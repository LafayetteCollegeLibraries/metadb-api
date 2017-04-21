
module MetaDB
  module Metadata
    class MetadataAttribute
      attr_reader :element, :label, :id, :attribute_index, :large, :date_searchable
      
      def initialize(field,
                     large = nil,
                     date_searchable = nil,
                     date_readable = nil,
                     controlled = nil,
                     multiple = nil,
                     additions = nil,
                     sorted = nil,
                     attribute_index = nil,
                     vocab_name = nil,
                     error = nil,
                     id = nil,
                     ui_label = nil)

      @field = field
      @project_name = field.item.project.name
      @element = field.element
      @label = field.label
      @md_type = field.md_type

      @large = large
      @date_searchable = date_searchable
      @date_readable = date_readable
      @controlled = controlled
      @multiple = multiple
      @additions = additions
      @sorted = sorted

      @attribute_index = attribute_index
      @vocab_name = vocab_name
      @error = error
      @id = id
      @ui_label = ui_label

      read

      # Work-around
      @id = '0' if @id.nil?
      @attribute_index = '0' if @attribute_index.nil?

      # Cannot cast this directly into a boolean
      normalize = lambda do |value|

        if value.is_a? String
          value == 'f' ? false : true
        else
          value
        end
      end

      @large = normalize.call(@large)
      @date_searchable = normalize.call(@date_searchable)
      @date_readable = normalize.call(@date_readable)
      @controlled = normalize.call(@controlled)
      @multiple = normalize.call(@multiple)
      @additions = normalize.call(@additions)
      @sorted = normalize.call(@sorted)
    end

    def clone(field, attribute_index = nil)

      new_attribute = MetadataAttribute.new(field,
                                            @large,
                                            @date_searchable,
                                            @date_readable,
                                            @controlled,
                                            @multiple,
                                            @additions,
                                            @sorted,
                                            attribute_index,
                                            @vocab_name,
                                            @error,
                                            # @id,
                                            @ui_label)

    end

    def insert

      if @field.item.project.session.conn.exec_params('SELECT project_name, element, label, md_type,large,date_searchable,date_readable,controlled,multiple,additions,sorted,attribute_index,vocab_name,error,id,ui_label from custom_attributes_adminmd_descmd WHERE project_name=$1 AND element=$2 AND label=$3 AND md_type=$4',
                                                      [ @project_name,
                                                        @element,
                                                        @label,
                                                        @md_type,
                                                      ]).values.empty?

        begin
          
          @field.item.project.session.conn.exec_params('INSERT INTO custom_attributes_adminmd_descmd (project_name, element, label, md_type,large,date_searchable,date_readable,controlled,multiple,additions,sorted,attribute_index,vocab_name,error,ui_label) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15 )',
                                                       [ @project_name,
                                                         @element,
                                                         @label,
                                                         @md_type,
                                                         @large,

                                                         @date_searchable,
                                                         @date_readable,
                                                         @controlled,
                                                         @multiple,
                                                         @additions,

                                                         @sorted,
                                                         @attribute_index,
                                                         @vocab_name,
                                                         @error,
                                                         @ui_label,
                                                       ])

        rescue Exception => e
          
          # Terrible, terrible work-around for this problem
          @field.item.project.session.conn.exec_params('INSERT INTO custom_attributes_adminmd_descmd (project_name, element, label, md_type,large,date_searchable,date_readable,controlled,multiple,additions,sorted,attribute_index,vocab_name,error,id,ui_label) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, (SELECT MAX(id) from custom_attributes_adminmd_descmd)+1, $15 )',
                                                       [ @project_name,
                                                         @element,
                                                         @label,
                                                         @md_type,
                                                         @large,

                                                         @date_searchable,
                                                         @date_readable,
                                                         @controlled,
                                                         @multiple,
                                                         @additions,

                                                         @sorted,
                                                         @attribute_index,
                                                         @vocab_name,
                                                         @error,
                                                         @ui_label,
                                                       ])
        end
      end

      # Retrieve the primary key
      read
    end

    def read

      @field.item.project.session.conn.exec_params('SELECT project_name, element, label, md_type,large,date_searchable,date_readable,controlled,multiple,additions,sorted,attribute_index,vocab_name,error,id,ui_label from custom_attributes_adminmd_descmd WHERE project_name=$1 AND element=$2 AND label=$3 AND md_type=$4',
                                                   [ @project_name,
                                                     @element,
                                                     @label,
                                                     @md_type,
                                                   ]).select do |row|

        
        @project_name = row['project_name']
        @element = row['element']
        @label = row['label']
        @md_type = row['md_type']
        @large = row['large']
        @date_searchable = row['date_searchable']
        @date_readable = row['date_readable']
        @controlled = row['controlled']
        @multiple = row['multiple']
        @additions = row['additions']
        @sorted = row['sorted']
        @attribute_index = row['attribute_index']
        @vocab_name = row['vocab_name']
        @error = row['error']
        @id = row['id']
        @ui_label = row['ui_label']
      end
    end
  end
  end
end
