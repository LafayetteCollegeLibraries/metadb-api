
require 'mini_magick'
require_relative 'metadata'

  class Item

    attr_reader :project, :number, :id, :file_name, :file_path
    attr_accessor :fields, :custom_file_name, :thumbnail_file_name, :large_file_name, :fullsize_file_name

    # @todo Complete for technical metadata
    def self.get_field_class(element, label)
      
      field_name = (element + '.' + label).downcase
      if AdminRecord::FIELD_NAMES.include? field_name

        return AdminRecord
      end
      
      DescRecord
    end

    #
    #
    def initialize(project, number = nil, id = nil, fields = [], project_name = nil, file_path: nil)

      @project = project
      @number = number
      @id = id
      @fields = fields

      if not file_path.nil?

        # The following file naming scheme is enforced:
        #
        # * lc-spcol-beyond-steel-0007.tif
        # * lc-spcol-srida-001078.tiff
        # * biol101-201009-assignment02-0806.jpg
        # * lc-geology-slides-0005.jpeg
        
        file_path_m = /\-(\d{4,6})\.(?:tiff|jpeg|tif|jpg)/.match file_path
        raise Exception.new "Failed to parse the master image file path #{file_path}" unless file_path_m

        # ?
        # @id = file_path_m[2]
        # @number = @id.to_i
        @number = file_path_m[1].to_i

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
          if project.name == 'srida'

            # lc-spcol-srida-001094.tif
            base_file_name = 'lc-spcol-' + project.name + '-' + ("%06d" % number)
          else

            base_file_name = 'lc-spcol-' + project.name + '-' + ("%04d" % number)
          end
        end

=begin
        if project.name == 'srida'

          @file_name = base_file_name + '.jpeg'
        else

          # This assumes that all files are images in the TIFF
          # @todo Refactor
          @file_name = base_file_name + '.tif'
        end
=end

        if project.name == 'srida'

          file_exts = ['.tif', '.jpeg', '.jpg']
        else

          file_exts = ['.tif']
        end

        files_paths = file_exts.select do |file_ext|

          file_name = base_file_name + file_ext
          file_path = File.join( @project.dir_path, file_name )

          File.exist? file_path
        end

        if files_paths.empty?

          raise Exception.new "Cannot create a new Item for #{base_file_name} unless the file exists"
        else

          # Only use the first file path
          file_ext = files_paths.first
          @file_name = base_file_name + file_ext
          @file_path = File.join( @project.dir_path, @file_name )
        end

=begin
        # This assumes that all files are images in the TIFF
        # @todo Refactor
        @file_name = base_file_name + '.tif'
        @file_path = File.join( @project.dir_path, @file_name )
=end

=begin
        # Ensure that the file exists, or raise an exception
        raise Exception.new "Cannot create a new Item for #{@file_path} unless the file exists" unless File.exist? @file_path
=end

      end

      @thumbnail_file_name = base_file_name + '-300.jpg'
      @custom_file_name = base_file_name + '-800.jpg'
      @large_file_name = base_file_name + '-2000.jpg'
      @fullsize_file_name = base_file_name + '.jpg'

      read if not @id.nil? and @fields.empty?
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
      # fields = @fields if fields.empty?

      # /var/metadb/master/imperial-postcards/lc-spcol-imperial-postcards-1808.tif
      # base_file_name = 'lc-spcol-' + project.name + '-' + ("%04d" % number)
      # cloned_file_path = 'lc-spcol-' + project.name + '-' + ("%04d" % number) + '.tif'
      cloned_file_path = File.join( dir_path, 'lc-spcol-' + project_name + '-' + ("%04d" % number) + '.tif' )
      new_item = Item.new(project, number, nil, [], project_name, file_path: cloned_file_path)

      if fields.empty?

        fields = @fields.each do |field|

          # @logger.info 'Cloning the field ' + field.element + '.' + field.label  + ' from ' + @number + ' to ' + number
          new_field = field.class.new(new_item, field.element, field.label, field.data)

          # For each new field, an accompanying attribute must also be instantiated
          # (This resolves issues in which the foreign key constraints between projects_adminmd_descmd and custom_attributes_adminmd_descmd must not be violated)
          # @todo Move this into the constructor for the field

          if new_field.is_a? AdminDescRecord

            # puts 'Cloning the field ' + field.element + '.' + field.label + " (#{field.attribute.attribute_index})"
            new_field.attribute = field.attribute.clone new_field, field.attribute.attribute_index
          else

            # puts 'Cloning the field ' + field.element + '.' + field.label
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
        # @fields[name] = metadata_class.new(self, element, label, '')
      end
    end

    def set_fields(row)
      
      row.each_index do |i|
        
        @fields[i].data = row[i]
        @fields[i].update
      end
    end
    
    def write # Avoiding the term "serialize" here

      if @project.session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2', [ @project.name,
                                                                                                                               @number ]).values.empty?
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
        # field.attribute = MetadataAttribute.new(field)

        @fields << field
        # @fields[item_record['element'] + '.' + item_record['label']] = metadata_class.new(self, item_record['element'], item_record['label'], item_record['data'])
      end

      # Append the technical metadata fields
      #
      res = @project.session.conn.exec_params('SELECT * FROM projects_techmd WHERE project_name=$1 AND item_number=$2', [ @project.name,
                                                                                                                          @number ])
      res.each do |item_record|

        field = TechnicalMetadataRecord.new(self, item_record['tech_element'], item_record['tech_label'], item_record['data'])

        # Refactor
        field.attribute = TechnicalMetadataAttribute.new(field)

        @fields << field
      end
    end
  end
