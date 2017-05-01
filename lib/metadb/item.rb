
require 'mini_magick'
require_relative 'metadata'

module MetaDB
  class Item

    attr_reader :project, :number, :id, :file_name, :file_path, :derivative_base
    attr_accessor :fields, :custom_file_name, :thumbnail_file_name, :large_file_name, :fullsize_file_name

    # @todo Complete for technical metadata
    def self.get_field_class(element, label)
      
      field_name = (element + '.' + label).downcase
      if Metadata::AdminRecord::FIELD_NAMES.include? field_name
        return Metadata::AdminRecord
      end
      
      Metadata::DescRecord
    end

    def initialize(project, number = nil, id = nil, fields = [], project_name = nil, file_path: nil, dir_path: nil, derivative_base: nil)
      @project = project
      @number = number
      @id = id
      @fields = fields

      dir_path = @project.dir_path if dir_path.nil?
      back_dir_path = @project.back_dir_path if back_dir_path.nil?

      @derivative_base = derivative_base.nil? ? "lc-spcol-#{@project.name}" : derivative_base

      if not file_path.nil?

        # The following file naming scheme is enforced:
        #
        # * lc-spcol-beyond-steel-0007.tif
        # * lc-spcol-srida-001078.tiff
        # * biol101-201009-assignment02-0806.jpg
        # * lc-geology-slides-0005.jpeg
        
        file_path_m = /\-(\d{4,6})\.(?:tiff|jpeg|tif|jpg)/.match file_path
        raise Exception.new "Failed to parse the master image file path #{file_path}" unless file_path_m

        @id = file_path_m[1]
        @number = @id.to_i

        @file_name = file_path.split('/').last
        base_file_name = @file_name.split('.').first
        
        @file_path = file_path
      elsif number.nil?

        raise Exception.new "Cannot create a new Item without a number"
      else

        if not project_name.nil?
          base_file_name = 'lc-spcol-' + project_name + '-' + ("%04d" % number)
        else

          # Extended handling for project with anomalous file naming schemes
          # @todo Refactor
          case project.name
          when BIOL101
            base_project_name = project.name.gsub(/\-\d{4}/, '')

            case number
            when 1..286
              base_file_name = base_project_name + '-201009-assignment01-' + ("%04d" % number)
            when 287..1046
              base_file_name = base_project_name + '-201009-assignment02-' + ("%04d" % number)
            when 1047..1237
              base_file_name = base_project_name + '-201009-assignment03-' + ("%04d" % number)
            else
              base_file_name = base_project_name + '-201009-assignment04-' + ("%04d" % number)
            end
          when GEOLOGY_SLIDES
            base_project_name = project.name.gsub(/\-\d{4}/, '')
            base_file_name = 'lc-' + base_project_name + '-' + ("%04d" % number)
          when GEOLOGY_SLIDES_ESI
            base_project_name = project.name.gsub(/\-\d{4}/, '')
            base_file_name = 'lc-' + base_project_name + '-' + ("%04d" % number)
          when SILK_ROAD
            base_file_name = 'lc-spcol-' + project.name + '-' + ("%06d" % number)
          else
            base_project_name = project.name.gsub(/\-\d{4}/, '')
            base_file_name = 'lc-spcol-' + base_project_name + '-' + ("%04d" % number)
          end
        end

        case project.name
        when BIOL101
          file_exts = ['.tif', '.jpeg', '.jpg']
        when MCKELVY_HOUSE
          file_exts = ['.tif', '.jpeg', '.jpg']
        when GEOLOGY_SLIDES_ESI
          file_exts = ['.tif', '.jpeg', '.jpg']
        when SILK_ROAD
          file_exts = ['.tif', '.jpeg', '.jpg']
        else
          file_exts = ['.tif']
        end

        files_paths = file_exts.select do |file_ext|
          file_name = base_file_name + file_ext
          file_path = File.join( dir_path, file_name )

          File.exist? file_path
        end

        if files_paths.empty?
          raise Exception.new "Cannot create a new Item for #{base_file_name} unless the file exists"
        else
          # Only use the first file path
          file_ext = files_paths.first
          @file_name = base_file_name + file_ext
          @file_path = File.join( dir_path, @file_name )
        end
      end

      @thumbnail_file_name = base_file_name + '-300.jpg'
      @custom_file_name = base_file_name + '-800.jpg'
      @large_file_name = base_file_name + '-2000.jpg'
      @fullsize_file_name = base_file_name + '.jpg'

      # Retrieve the second file (if a back exists)
      back_files = Dir.glob("#{back_dir_path}/#{base_file_name}b*")
      unless back_files.empty?
        @back_file_path = back_files.first
        @back_file_name = back_files.first
      end
    end

    # Clones an Item
    # Can either accept an explicit set of fields for the newly-cloned Item, or, will instantiate a new Item using the member fields of the instance
    # @param project
    # @param number
    # @param fields
    #
    def clone(project, number = nil, fields = [], dir_path = nil, project_name = nil)
      
      project ||= @project
      number ||= @number
      number = number.to_i

      # /var/metadb/master/imperial-postcards/lc-spcol-imperial-postcards-1808.tif
      cloned_file_path = File.join( dir_path, 'lc-spcol-' + project_name + '-' + ("%04d" % number) + '.tif' )
      new_item = Item.new(project, number, nil, [], project_name, file_path: cloned_file_path)

      if fields.empty?

        fields = @fields.each do |field|

          new_field = field.class.new(new_item, field.element, field.label, field.data)

          # For each new field, an accompanying attribute must also be instantiated
          # (This resolves issues in which the foreign key constraints between projects_adminmd_descmd and custom_attributes_adminmd_descmd must not be violated)
          # @todo Move this into the constructor for the field
          if new_field.is_a? Metadata::AdminDescRecord
            new_field.attribute = field.attribute.clone new_field, field.attribute.attribute_index
          else
            new_field.attribute = field.attribute.clone new_field
          end

          new_item.fields << new_field
        end
      end

      return new_item
    end
    
    def parse_fields(field_names = [])
      
      field_names.each do |name|

        name_elems = name.split '.'
        element = name_elems.shift
        label = name_elems.join '.'
        
        metadata_class = Item.get_field_class(element, label)
        @fields << metadata_class.new(self, element, label, '')
      end
    end

    def set_fields(row)
      
      row.each_index do |i|
        
        @fields[i].data = row[i]
        @fields[i].update
      end
    end

    def write # Avoiding the term "serialize" here

      existing_items = @project.session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2', [ @project.name, @number ])

      # if existing_items.first.values.empty?
      if existing_items.values.empty?

        @project.session.conn.exec_params("INSERT INTO items (project_name, item_number, file_name, thumbnail_file_name, custom_file_name, large_file_name, fullsize_file_name, checksum) VALUES($1, $2, $3, $4, $5, $6, $7, '')",
                                          [ @project.name,
                                            @number,
                                            @file_name,
                                            @thumbnail_file_name,
                                            @custom_file_name,
                                            @large_file_name,
                                            @fullsize_file_name ])


        # Retrieve the ID
        res = @project.session.conn.exec_params('SELECT id FROM items WHERE project_name=$1 AND item_number=$2', [ @project.name, @number ])
        res.each do |item_record|

          @id = item_record['id']
        end
      end
      
      @fields.map {|field| field.insert }
    end

    def read

      # Retrieve the administrative and descriptive metadata
      #
      res = @project.session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2', [ @project.name,
                                                                                                                                  @number ])
      res.each do |item_record|

        metadata_class = Item.get_field_class(item_record['element'], item_record['label'])

        field = metadata_class.new(self, item_record['element'], item_record['label'], item_record['data'])

        # Refactor
        @fields << field
      end

      # Append the technical metadata fields
      res = @project.session.conn.exec_params('SELECT * FROM projects_techmd WHERE project_name=$1 AND item_number=$2', [ @project.name,
                                                                                                                          @number ])
      res.each do |item_record|

        field = Metadata::TechnicalMetadataRecord.new(self, item_record['tech_element'], item_record['tech_label'], item_record['data'])

        # Refactor
        field.attribute = Metadata::TechnicalMetadataAttribute.new(field)

        @fields << field
      end
    end

    def export
      read

      {
        :project => @project.name,
        :number => @number,
        :file_path => @file_path,
        :back_file_path => @back_file_path,
        :metadata => @fields.map do |field|
          {
            :element => field.element,
            :label => field.label,
            :data => field.data
          }
        end
      }
    end
  end
end
