
require 'csv'
require_relative 'derivative'

include Derivatives

  # Modeling MetaDB Project entities
  #
  class Project

    attr_accessor :items
    attr_reader :session, :name, :dir_path

    def initialize(session, name, items = nil, options = {})

      @session = session
      @name = name

      @items = items || []
      # Uncomment
      # @items = (1..1808).to_a

      @dir_path = options.fetch :dir_path, File.join("/var/metadb/master/", @name)
      @access_path = options.fetch :access_path, File.join("/var/metadb/access/", @name)

      # Populate the fields
      @field_classes = field_classes

      # @derivative_options = options.keep_if { |k,v| [ :branding, :branding_text, :image_write_path ].include? k.to_sym }
      @derivative_options = { :image_write_path => @access_path }

      # Uncomment
      read if items.nil?
      # @items += items

      @access_images = @items.map { |item| [ Derivative.new( item, @derivative_options ),  LargeDerivative.new( item, @derivative_options ),  CustomDerivative.new( item, @derivative_options ),  ThumbnailDerivative.new( item, @derivative_options ) ] }
      # @access_images = @items.map { |item| [ ThumbnailDerivative.new( item, @derivative_options ) ] }
    end

    # Retrieve the classes for the fields in the project
    #
    # @return [Array] an array of Class Objects (derived from MetadataRecord)
    def field_classes

      classes = {}
      
      # Retrieve the administrative and descriptive metadata
      #
      res = @session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 LIMIT 1', [ @name ])
      res.each do |item_record|

        # classes << Item.get_field_class(item_record['element'], item_record['label'])

        if classes.has_key? item_record['element']

          classes[item_record['element']][item_record['label']] = Item.get_field_class(item_record['element'], item_record['label'])
        else

          classes[item_record['element']] = { item_record['label'] => Item.get_field_class(item_record['element'], item_record['label']) }
        end
      end

      # Append the technical metadata fields
      #
      res = @session.conn.exec_params('SELECT * FROM projects_techmd WHERE project_name=$1 LIMIT 1', [ @name ])
      res.each do |item_record|

        # classes << TechnicalMetadataRecord.new(self, item_record['tech_element'], item_record['tech_label'], item_record['data'])
        if classes.has_key? item_record['tech_element']

          classes[item_record['tech_element']][item_record['tech_label']] = TechnicalMetadataRecord
        else

          classes[item_record['tech_element']] = { item_record['tech_label'] => TechnicalMetadataRecord }
        end
      end

      classes
    end

    # Generate a set of blank metadata fields for a newly-added Item
    #
    # @param [Item] the Item to which the newly-created metadata field is related
    # @return [Array] an array of Class Objects (derived from MetadataRecord)
    def fields(item)

      fields = []

      @field_classes.each_pair do |element, value|

        value.each_pair do |label, klass|
    
          fields << klass.new(item, element, label)

          # Create the new attribute also?
        end
      end

      fields
    end

    # Parse a CSV file and create the new Items
    #
    def parse_from_csv(csv_file_path)

      data = CSV.read(csv_file_path)
      headers = data.shift

      data.each_index do |i|

        @items << Item.new(self, i, nil, headers)

        row = data[i]
        @items[i].set_fields row
      end
      @items
    end

    def read

      res = @session.conn.exec_params('SELECT item_number,id FROM items WHERE project_name=$1 ORDER BY item_number', [@name])

      # @todo Remove for debugging
      res.each do |item_record|

        if self.respond_to? :logger

          logger.info "Instantiating an item record for #{item_record['item_number']}"
        else

          puts "Instantiating an item record for #{item_record['item_number']}"
        end

        # @items << Item.new(self, item_record['item_number'], item_record)
        @items << Item.new(self, item_record['item_number'], item_record['id'])
      end

      # Retrieve settings in relation to project derivative generation
      res = @session.conn.exec_params('SELECT annotation_mode, brand, bg_color, fg_color FROM derivative_settings WHERE project_name=$1', [@name])
      res.each do |derivative_settings|

        @derivative_options.merge!({ :branding => derivative_settings['annotation_mode'],
                                     :branding_text => derivative_settings['brand'],
                                     :bg_color => derivative_settings['bg_color'],
                                     :fg_color => derivative_settings['fg_color']
                                   })
      end
    end

    def write

      if @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1', [@name]).values.empty?

        @session.conn.exec_params("INSERT INTO projects (project_name, project_notes, deriv_host) VALUES($1, $2, 'http://metadb.lafayette.edu/')", [@name, ''])
      end

      @items.map { |item| item.write }.reduce { |results, result| results or result }
    end



    # Derive all images (thumbnail, fullsize, large, and custom) for Items within the Project
    # @param init [Fixnum] Beginning of the range
    # @param term [Fixnum] End of the range
    #
    def derive(init = nil, term = nil)

      init = init || @access_images.first.first.item.number
      term = term || @access_images.last.first.item.number

      init = init.to_i
      term = term.to_i

      access_images = @access_images.select do |access_image_set|

        # access_image_set.first.item.number >= init and access_image_set.first.item.number <= term

        # Why does to_i need to be explicitly invoked?
        #
        access_image_set.first.item.number.to_i >= init and access_image_set.first.item.number.to_i <= term
      end

      access_images.each do |access_image_set|

        begin
          
          access_image_set.map { |access_image| access_image.derive }
        rescue Exception => ex

          if respond_to? :logger

            logger.error "Failed to generated the following derivatives: #{ex.message}"
          else

            $stderr.puts "Failed to generated the following derivatives: #{ex.message}"
          end
        end
      end.reduce(:+)
    end

    # Derive all thumbnail images for Items within the Project
    # @param init [Fixnum] Beginning of the range
    # @param term [Fixnum] End of the range
    #
    def derive_thumbnails(init = nil, term = nil)

      init = init || @access_images.first.first.item.number
      term = term || @access_images.last.first.item.number

      init = init.to_i
      term = term.to_i

      access_images = @access_images.select do |access_image_set|

        # access_image_set.first.item.number >= init and access_image_set.first.item.number <= term

        # Why does to_i need to be explicitly invoked?
        #
        access_image_set.first.item.number.to_i >= init and access_image_set.first.item.number.to_i <= term
      end

      access_images.each do |access_image_set|

        begin
          
          access_image_set.select do |access_image|

            access_image.is_a? ThumbnailDerivative
          end.map do |access_image|

            access_image.derive
          end
        rescue Exception => ex

          if respond_to? :logger

            logger.error "Failed to generated the following derivatives: #{ex.message}"
          else

            $stderr.puts "Failed to generated the following derivatives: #{ex.message}"
          end
        end
      end.reduce(:+)      
    end

    # Append a new Item to a given Project
    #
    # @param options [Hash] the options for the Item
    def add(options = {})

      item = options.fetch :item, nil
      if item.nil?

        item_number = options.fetch :number, nil
        if item_number.nil? and @items.last.nil?

          item_number = 1
        else

          item_number = @items.last.number + 1
        end
        
        item_id = options.fetch :id, nil
        item_fields = options.fetch :fields, @fields

        item = Item.new self, item_number, item_id, item_fields
      end

      item.write

      @items << item
    end

    # Parse the Project directory for new master image files, and create Items for any new Items ingested
    #
    def parse

      # Dir.glob("#{@dir_path}/*.tiff?|jpe?g") do |master_file_name|
      Dir.glob("#{@dir_path}/*.{tif,tiff,TIF,TIFF,jpg,jpeg,JPG,JPEG}") do |master_file_name|

        # Attempt to construct the Item using the file path alone
        add :item => Item.new( self, file_path: File.join( @dir_path, master_file_name ) )
      end
    end

    # Prefix the title.english field for all Items within a given collection
    # @param (String) prefix The prefix which is to be prepended to the dc.title field
    #
    def prefix_titles(prefix, title_element = 'title', title_label = 'english')

      @items.each do |item|

        item.fields.each do |item_field|

          item_field.data = "[#{prefix}#{"%04d" % item.number}] #{item_field.data}" if item_field.element == title_element and item_field.label == title_label
          item_field.update
        end
      end
    end

    # Set the default values of a given field to a string value
    # @param (Array) fields A mapping consisting of the field element, field label, and default field value
    #
    def set_default_values(fields)

      @items.each do |item|

        fields.each do |field_options|

          item.fields.each do |item_field|

            item_field.data = field_options[:data] if item_field.element == field_options[:element] and item_field.label == field_options[:label]
            item_field.update
          end
        end
      end
    end
  end
  
  class ProjectSet
    attr_reader :projects
    
    def initialize(session, projects = {})
      
      @session = session
      @projects = projects
    end
    
    # Split a project into a set
    def self.split(project, subset_length = 500)
      
      subset = {}
      
      i = 0
      while project.items.length > i

        if i == 0

          index = "0001"
          project_start = i
          project_length = subset_length - 1
        else

          index = "%04d" % i
          project_start = i - 1
          project_length = subset_length
        end

        child_project_name = project.name + '-' + index

        child_project = Project.new(project.session, child_project_name)
        subset[child_project_name] = child_project

        puts "Cloning the item record for the subset #{i}"

        # project.items.slice(i - 1, subset_length).each do |item|
        project.items.slice(project_start, project_length).each do |item|

          # Clones the MetaDB Item, and all associated fields
          # Uncomment
          item = item.clone(child_project, nil, [], 'lc-spcol-' + project.name)
          child_project.items << item
        end

        i += (subset_length)
      end
      
      set = ProjectSet.new @session, subset
    end
    
    # Join disparate sets of projects
    def self.join
      
      nil
    end
    
    def write
      
      @projects.values.map { |project| project.write }.reduce { |results, result| results or result }
    end
  end
