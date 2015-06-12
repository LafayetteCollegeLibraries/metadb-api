
require 'mini_magick'
require_relative 'metadata'

  class Item

    attr_reader :project, :number, :id, :file_name
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
    def initialize(project, number, id = nil, fields = [], project_name = nil)

      @project = project
      @number = number
      @id = id
      @fields = fields

      if not project_name.nil?

        base_file_name = project_name + '-' + ("%04d" % number)
      else

        base_file_name = project.name + '-' + ("%04d" % number)
      end

      @file_name = base_file_name + '.tif'
      @thumbnail_file_name = base_file_name + '-300.jpg'
      @custom_file_name = base_file_name + '-800.jpg'
      @large_file_name = base_file_name + '-2000.jpg'
      @fullsize_file_name = base_file_name + '.jpg'

      read if @fields.empty?
    end

    # Clones an Item
    # Can either accept an explicit set of fields for the newly-cloned Item, or, will instantiate a new Item using the member fields of the instance
    # @param project
    # @param number
    # @param fields
    #
    def clone(project, number = nil, fields = [], project_name = nil)
      
      project ||= @project
      number ||= @number
      # fields = @fields if fields.empty?

      #puts 'new item number: ' + number
      #raise NotImplementedError.new

      new_item = Item.new(project, number, nil, [], project_name)

      if fields.empty?

        fields = @fields.each do |field|

          # @logger.info 'Cloning the field ' + field.element + '.' + field.label  + ' from ' + @number + ' to ' + number

          new_field = field.class.new(new_item, field.element, field.label, field.data)

          # For each new field, an accompanying attribute must also be instantiated
          # (This resolves issues in which the foreign key constraints between projects_adminmd_descmd and custom_attributes_adminmd_descmd must not be violated)
          # @todo Move this into the constructor for the field

          if new_field.is_a? AdminDescRecord

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
        field.attribute = MetadataAttribute.new(field)

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
