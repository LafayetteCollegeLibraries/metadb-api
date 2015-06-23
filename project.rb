
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
      @access_path = options.fetch :dir_path, File.join("/var/metadb/access/", @name)

      @derivative_options = options.keep_if { |k,v| [ :branding, :branding_text, :image_write_path ].include? k.to_sym }

      # Populate the fields
      @field_classes = field_classes

      # Uncomment
      read if items.nil?
      # @items += items

      @access_images = @items.map { |item| [ Derivative.new( item ),  LargeDerivative.new( item ),  CustomDerivative.new( item ),  ThumbnailDerivative.new( item ) ] }
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
      # res = @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1 ORDER BY item_number LIMIT 20', [@name])
      res.each do |item_record|

        # puts "Instantiating an item record for #{item_record['item_number']}"

        # @items << Item.new(self, item_record['item_number'], item_record)
        @items << Item.new(self, item_record['item_number'], item_record['id'])
      end
    end

    def write

      if @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1', [@name]).values.empty?

        @session.conn.exec_params("INSERT INTO projects (project_name, project_notes, deriv_host) VALUES($1, $2, 'http://metadb.lafayette.edu/')", [@name, ''])
      end

      @items.map { |item| item.write }.reduce { |results, result| results or result }
    end

    # Derive all images (thumbnail, fullsize, large, and custom) for Items within the Project
    #
    #
    def derive

      @access_images.each do |access_image_set|

        begin
          
          access_image_set.map { |access_image| access_image.derive access_image, @derivative_options }
        rescue Exception

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

          puts "Cloning the item record for #{item.number}"
          # Debugging
          # puts "Cloning the item record for #{item}"
          
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
