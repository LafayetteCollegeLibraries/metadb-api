require 'thor'
require 'bagit'
require 'zip'
require 'base64'
require 'httparty'
require File.join(File.dirname(__FILE__), 'lib', 'metadb')
require_relative 'zip_file_generator'

class Metadb < Thor
  
  no_commands do

    def export(item_record, output_dir, jp2_only: false)

      # Generate the name for the Bag
      item_file_path = item_record[:file_path]

      # Derive the JPEG2000
      item_jp2_path = item_file_path.split('/').last.gsub(/\.tif/, '.jp2')
      `/usr/bin/env convert #{item_file_path}[0] -define numrlvls=7 -define jp2:tilewidth=1024 -define jp2:tileheight=1024 -define jp2:rate=0.02348 -define jp2:prg=rpcl -define jp2:mode=int -define jp2:prcwidth=16383 -define jp2:prcheight=16383 -define jp2:cblkwidth=64 -define jp2:cblkheight=64 -define jp2:sop #{item_jp2_path}`

      item_back_file_path = item_record[:back_file_path]

      # Derive the JPEG2000 from the image of the postcard back
      if item_back_file_path
        item_back_jp2_path = item_back_file_path.split('/').last.gsub(/\.+$/, '.jp2')
        `/usr/bin/env convert #{item_back_file_path}[0] -define numrlvls=7 -define jp2:tilewidth=1024 -define jp2:tileheight=1024 -define jp2:rate=0.02348 -define jp2:prg=rpcl -define jp2:mode=int -define jp2:prcwidth=16383 -define jp2:prcheight=16383 -define jp2:cblkwidth=64 -define jp2:cblkheight=64 -define jp2:sop #{item_back_jp2_path}`
      end

      bag_name = item_file_path.split('/').last.gsub(/\.tif/, '')
      bag_name = bag_name.split('/').last.gsub(/\.jpe?g/, '')
      metadata_file_name = "#{bag_name}_metadata.csv"

      # Create the CSV for the metadata
      CSV.open(metadata_file_name, "wb") do |csv|
        csv << ["predicate", "object"]
        MetaDB::Metadata::Crosswalk.transform(item_record[:metadata]).each_pair { |predicate,object| csv << [predicate,object] }
      end
    
      FileUtils.rm_r bag_name if File.directory? bag_name
    
      # Add the image to the Bag
      bag = BagIt::Bag.new bag_name
      
      if jp2_only
        bag.add_file(item_jp2_path.split('/').last, item_jp2_path)
        bag.add_file(item_back_jp2_path.split('/').last, item_back_jp2_path) if item_back_file_path
      else
        bag.add_file(item_file_path.split('/').last, item_file_path)
        bag.add_file(item_back_file_path.split('/').last, item_back_file_path) if item_back_file_path
      end

      bag.add_file(metadata_file_name, metadata_file_name)
    
      # generate the manifest and tagmanifest files
      bag.manifest!

      # zip the Bag
      zipfile_name = File.join(output_dir, bag_name + '.zip')
      FileUtils.rm zipfile_name if File.exists? zipfile_name
      FileUtils.rm item_jp2_path
      FileUtils.rm item_back_jp2_path if item_back_jp2_path
      FileUtils.rm metadata_file_name
      
      zip = ZipFileGenerator.new bag_name, zipfile_name
      zip.write
      FileUtils.rm_r bag_name if File.directory? bag_name      
    end
  end

  desc "export_vocabulary", "Export a Controlled Vocabulary"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :vocabulary, :aliases => "-V", :desc => "controlled vocabulary", :required => true
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  def export_vocabulary()
    session = MetaDB::Session.new options[:user], options[:password], nil, options[:host], options[:user]

    vocabulary = session.vocabulary(options[:vocabulary])
    vocabulary_data = vocabulary.export

    # Create the CSV for the metadata
    CSV.open("vocabulary_#{options[:vocabulary]}.csv", "wb") do |csv|
      csv << ["vocabulary", "term"]
      vocabulary_data[:terms].each { |term| csv << [options[:vocabulary], term] }
    end
  end

  desc "export_item", "Export an Item from a Project"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :project_name, :aliases => "-P", :desc => "project", :required => true
  option :item_number, :aliases => "-i", :desc => "item number", :required => true, :type => :numeric
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  option :output_dir, :aliases => "-o", :desc => "output directory for the Items", :required => true
  option :jp2_only, :aliases => "-j", :desc => "only export the JPEG2000 derivative", :type => :boolean, :default => true
  def export_item()
    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]
    item_record = session.project.export_item(options[:item_number])
    export(item_record, options[:output_dir], jp2_only: options[:jp2_only])
  end

  desc "export_project", "Export a Project"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :project_name, :aliases => "-P", :desc => "project", :required => true
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  option :output_dir, :aliases => "-o", :desc => "output directory for the Items", :required => true
  option :first, :aliases => "-f", :desc => "first Item in the subset being exported"
  option :last, :aliases => "-l", :desc => "last Item in the subset being exported"
  option :jp2_only, :aliases => "-j", :desc => "only export the JPEG2000 derivative", :type => :boolean, :default => true
  def export_project()
    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]

    last = options.fetch(:last, nil)
    first = options.fetch(:first, nil)

    items = if first
              if last
                session.project.items(first.to_i, last.to_i)
              else
                session.project.items(first.to_i)
              end
            else
              session.project.items
            end

    items.each do |item|
      item_record = session.project.export_item(item.number)
      export(item_record, options[:output_dir], jp2_only: options[:jp2_only])
    end
  end

  desc "split", "Split a Project"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :project_name, :aliases => "-P", :desc => "project", :required => true
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  option :by, :aliases => "-b", :desc => "by", :default => 500, :type => :numeric
  def split()
    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]

    set = MetaDB::ProjectSet.split session.project, options[:by]
    set.write
  end

  desc "derive", "Derive images for Items within a Project"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :project_name, :aliases => "-P", :desc => "project", :required => true
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  def derive()

    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]
    session.project.derive
  end

  desc "create", "Create an Item within a Project"
  option :file, :aliases => "-f", :desc => "file path", :required => true
  option :number, :aliases => "-n", :desc => "number", :default => 1, :type => :numeric
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  option :project_name, :aliases => "-P", :desc => "project name", :required => true
  option :dir_path, :aliases => "-d", :desc => "project directory path"
  option :derivative_base, :aliases => "-D", :desc => "derivative base"
  def create()
    dir_path = options[:dir_path].empty? ? File.join("/var/metadb/master/", options[:project_name]) : options[:dir_path]

    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:dbname]

    session.project.add :number => options[:number], file: options[:file], dir_path: dir_path, derivative_base: options[:derivative_base]
  end

  desc "create_project", "Create a New Project"

  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'

  option :project_name, :aliases => "-P", :desc => "project name", :required => true
  option :dir_path, :aliases => "-d", :desc => "project directory path"
  option :derivative_base, :aliases => "-D", :desc => "derivative base"
  def create_project()
    dir_path = options[:dir_path].empty? ? File.join("/var/metadb/master/", options[:project_name]) : options[:dir_path]

    session = MetaDB::Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]
    session.project.write
  end
end
