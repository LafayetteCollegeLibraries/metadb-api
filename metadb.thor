require 'thor'

require File.join(File.dirname(__FILE__), 'metadb')
include MetaDB

class Metadb < Thor

  desc "split", "Split a Project"
  option :user, :aliases => "-u", :desc => "user", :default => 'metadb'
  option :password, :aliases => "-p", :desc => "password", :default => 'secret'
  option :project_name, :aliases => "-P", :desc => "project", :required => true
  option :host, :aliases => "-h", :desc => "host", :default => 'localhost'
  option :by, :aliases => "-b", :desc => "by", :default => 500, :type => :numeric
  def split()
    session = Session.new options[:user], options[:password], options[:project_name], options[:host], options[:user]

    set = ProjectSet.split session.project, options[:by]
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
