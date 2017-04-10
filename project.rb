
require 'csv'
require_relative 'derivative'

module MetaDB

  # Modeling MetaDB Project entities
  #
  class Project

    PREFIXES = {
      'imperial-postcards' => 'ip',
      'imperial-postcards-0001' => 'ip',
      'imperial-postcards-0500' => 'ip',
      'imperial-postcards-1000' => 'ip',
      'imperial-postcards-1500' => 'ip',
      'pacwar-postcards' => 'fd'
    }

    attr_accessor :items
    attr_reader :session, :name, :dir_path, :back_dir_path

    def initialize(session, name, items = [], options = {})

      @session = session
      @name = name
      
      @prefix = PREFIXES[@name]

      @items = items || []

      @dir_path = options.fetch :dir_path, File.join("/var/metadb/master/", @name)
      @access_path = options.fetch :access_path, File.join("/var/metadb/access/", @name)
      @back_dir_path = options.fetch :back_dir_path, File.join("/var/metadb/master_backs/", @name, "backs")

      # Populate the fields
      @field_classes = field_classes

      @derivative_options = { :image_write_path => @access_path }

      limit = options.fetch :limit, nil

      @access_images = @items.map { |item| [ Derivatives::Derivative.new( item, @derivative_options ),  Derivatives::LargeDerivative.new( item, @derivative_options ),  Derivatives::CustomDerivative.new( item, @derivative_options ),  Derivatives::ThumbnailDerivative.new( item, @derivative_options ) ] }
    end

    # Retrieve the classes for the fields in the project
    #
    # @return [Array] an array of Class Objects (derived from MetadataRecord)
    def field_classes

      classes = {}
      
      # Retrieve the administrative and descriptive metadata
      res = @session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 LIMIT 1', [ @name ])
      res.each do |item_record|

        admin_desc_element = item_record['element']

        if admin_desc_element
          if classes.has_key? admin_desc_element
            classes[item_record['element']][item_record['label']] = Item.get_field_class(item_record['element'], item_record['label'])
          else
            classes[item_record['element']] = { item_record['label'] => Item.get_field_class(item_record['element'], item_record['label']) }
          end
        end
      end

      # Append the technical metadata fields
      res = @session.conn.exec_params('SELECT * FROM projects_techmd WHERE project_name=$1 LIMIT 1', [ @name ])
      res.each do |item_record|

        tech_element = item_record['tech_element']
        if tech_element
          if classes.has_key? item_record['tech_element']
            classes[item_record['tech_element']][item_record['tech_label']] = TechnicalMetadataRecord
          else
            classes[item_record['tech_element']] = { item_record['tech_label'] => TechnicalMetadataRecord }
          end
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

          if element == 'title' and label == 'english'

            fields << klass.new(item, element, label, "[#{@prefix}#{"%04d" % item.number}] ")
          else
    
            fields << klass.new(item, element, label)
          end
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

    def read_derivative_options

      # Retrieve settings in relation to project derivative generation
      res = @session.conn.exec_params('SELECT annotation_mode, brand, bg_color, fg_color FROM derivative_settings WHERE project_name=$1', [@name])
      res.each do |derivative_settings|

        @derivative_options.merge!({ :branding => 1,
                                     :branding_text => derivative_settings['brand'],
                                     :bg_color => derivative_settings['bg_color'],
                                     :fg_color => derivative_settings['fg_color']
                                   })
      end
    end

    def item(item_number)
      item = Item.new(self, item_number)
    end

    def export_item(item_number)
      item(item_number).export
    end

    def export
      read
      @items.map { |item| item.export }
    end

    def read(limit = nil)
      query = "SELECT item_number,id FROM items WHERE project_name=$1 ORDER BY item_number"
      query += " LIMIT #{limit}" unless limit.nil?

      res = @session.conn.exec_params(query, [@name])

      # @todo Remove for debugging
      res.each do |item_record|
        @items << Item.new(self, item_record['item_number'], item_record['id'])
      end
    end

    def write

      if @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1', [@name]).values.empty?

        @session.conn.exec_params("INSERT INTO projects (project_name, project_notes, deriv_host) VALUES($1, $2, 'http://metadb.lafayette.edu/')", [@name, ''])
      end

      # Insert the derivative settings
      if @session.conn.exec_params('SELECT annotation_mode, brand, bg_color, fg_color FROM derivative_settings WHERE project_name=$1', [@name]).values.empty?

        [{:setting_name => 'thumb',
           :max_width => 300,
           :max_height => 300,
         },
         {:setting_name => 'large',
           :max_width => 2000,
           :max_height => 2000,
         },
         {:setting_name => 'custom',
           :max_width => 800,
           :max_height => 800,
         },
         {:setting_name => 'fullsize',
           :max_width => 0,
           :max_height => 0,
         },
        ].each do |values|

          @session.conn.exec_params("INSERT INTO derivative_settings (project_name, setting_name, max_width, max_height, annotation_mode, brand, bg_color, fg_color, enabled) " + 
                                    "VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9)", [@name,
                                                                                   values[:setting_name],
                                                                                   values[:max_width],
                                                                                   values[:max_height],
                                                                                   0,
                                                                                   @derivative_options[:branding_text],
                                                                                   @derivative_options[:bg_color],
                                                                                   @derivative_options[:fg_color],
                                                                                   true])
        end
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

        # Why does to_i need to be explicitly invoked?
        #
        access_image_set.first.item.number.to_i >= init and access_image_set.first.item.number.to_i <= term
      end

      access_images.each do |access_image_set|

        access_image_set.map { |access_image| access_image.derive }
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

        access_image_set.first.item.number.to_i >= init and access_image_set.first.item.number.to_i <= term
      end

      access_images.each do |access_image_set|

        access_image_set.select do |access_image|

          access_image.is_a? Derivatives::ThumbnailDerivative
        end.map do |access_image|

          access_image.derive
        end
      end.reduce(:+)      
    end

    # Append a new Item to a given Project
    #
    # @param options [Hash] the options for the Item
    def add(options = {})

      item = options.fetch :item, nil
      item_fields = options.fetch :fields, @fields
      dir_path = options.fetch :dir_path, @dir_name
      derivative_base = options.fetch :derivative_base, nil

      if item.nil?
        item_number = options.fetch :number, nil
        item_id = options.fetch :id, nil

        if item_fields

          if item_number.nil? and @items.last.nil?

            item_number = 1
          else

            item_number = @items.last.number + 1
          end

          item = Item.new self, item_number, item_id, item_fields, dir_path: dir_path, derivative_base: derivative_base
        else
          file_path = options.fetch :file_path, nil

          # Create the new Item
          item = Item.new self, item_number, file_path: file_path, dir_path: dir_path, derivative_base: derivative_base

          # Retrieve the fields
          item.fields = fields(item)
        end
      end

      item.write

      @items << item
    end

    # Parse the Project directory for new master image files, and create Items for any new Items ingested
    #
    def parse

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
      subset_step = 0

      while project.items.length >= subset_step

        if subset_step == 0

          project_index = "%04d" % 1
          item_step = 0
          item_slice_length = subset_length - 1
        else

          project_index = "%04d" % (subset_step)
          item_step = subset_step - 1
          item_slice_length = subset_length
        end

        child_project_name = project.name + '-' + project_index
        child_project = Project.new(project.session, child_project_name)
        subset[child_project_name] = child_project

        project.items.slice(item_step, item_slice_length).each do |item|

          new_item = item.clone(child_project, nil, [], project.dir_path, project.name)
          child_project.items << new_item
        end

        subset_step += subset_length
      end

      set = ProjectSet.new @session, subset
    end
    
    def write
      
      @projects.values.map { |project| project.write }.reduce { |results, result| results or result }
    end
  end
end
