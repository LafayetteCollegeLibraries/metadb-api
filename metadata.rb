  class TechnicalMetadataAttribute
    attr_reader :element, :label, :id

    def initialize(field)

      @field = field
      @project_name = field.item.project.name
      @tech_element = field.tech_element
      @tech_label = field.tech_label
    end

    def clone(field)

      new_attribute = TechnicalMetadataAttribute.new(field)
    end

    def insert

      if @field.item.project.session.conn.exec_params('SELECT project_name, tech_element, tech_label FROM custom_attributes_techmd WHERE project_name=$1 AND tech_element=$2 AND tech_label=$3',
                                                      [ @project_name,
                                                        @tech_element,
                                                        @tech_label
                                                      ]).values.empty?

        @field.item.project.session.conn.exec_params('INSERT INTO custom_attributes_techmd (project_name, tech_element, tech_label) VALUES ($1, $2, $3)',
                                                     [ @project_name,
                                                       @tech_element,
                                                       @tech_label
                                                     ])

      end

      # Retrieve the primary key
      # read
    end
  end

  class MetadataAttribute
    attr_reader :element, :label, :id, :attribute_index

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
      normalize = lambda { |value| value == 'f' ? false : true }

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


      # new_attribute = MetadataAttribute.new(field)
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

  class MetadataRecord
    attr_reader :element, :label, :item, :md_type
    attr_accessor :data, :attribute
    
    def initialize(item, element, label, data=nil, attribute=nil)
      
      @item = item
      @element = element
      @label = label
      @attribute = attribute

      if data.nil?

        read
      else

        @data = data
      end

      # @logger.info 'instantiating the field ' + @element + '.' + @label + ' for ' + @item.number

      # Ensure that the record within custom_attributes_adminmd_descmd exists
      @attribute = MetadataAttribute.new(self) if @attribute.nil?
    end
  end

  class AdminDescRecord < MetadataRecord

    def read

      @item.project.session.conn.exec_params('SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
                                             [@item.project.name, @item.number, @md_type, @element, @label]).select do |row|

        @data = row['data']

        # @attribute_id = row['attribute_id'].to_i
        # @attribute = MetadataAttribute.new(self)
      end
    end

    def insert

      @attribute.insert
      if @item.project.session.conn.exec_params('SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
                                                [@item.project.name, @item.number, @md_type, @element, @label]).values.empty?

        @item.project.session.conn.exec_params('INSERT INTO projects_adminmd_descmd (project_name, item_number, md_type, element, label, data, attribute_id, item_id) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
                                               [@item.project.name, @item.number, @md_type, @element, @label, @data, @attribute.id.to_i, @item.id.to_i])
      end
    end

    def update

      @item.project.session.conn.exec_params('UPDATE projects_adminmd_descmd SET data=$6,attribute_id=$7 WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
                                             [@item.project.name, @item.number, @md_type, @element, @label, @data, @attribute.id.to_i])
    end
  end

  class AdminRecord < AdminDescRecord

    # @todo Refactor using field names retrieved from the database
    FIELD_NAMES = ['identifier.dmrecord',
                   'format.extent',
                   'relation.ispartof',
                   'format.digital',
                   'publisher.digital',
                   'rights.digital',
                   'creator.digital']
    
    def initialize(item, element, label, data='', attribute=nil)
      
      @md_type = 'administrative'
      super(item, element, label, data, attribute)
    end
  end

  # Class for the DescRecord
  class DescRecord < AdminDescRecord
    
    def initialize(item, element, label, data='', attribute=nil)
      
      @md_type = 'descriptive'
      super(item, element, label, data, attribute)
    end
  end

  # 
  # @todo Implement
  class TechnicalMetadataRecord

    attr_reader :tech_element, :tech_label, :item, :element, :label, :data
    attr_accessor :tech_data, :attribute
    
    def initialize(item, tech_element, tech_label, tech_data=nil, attribute=nil)
      
      @item = item
      @tech_element = tech_element
      @tech_label = tech_label
      @attribute = attribute
      
      @element = @tech_element
      @label = @tech_label

      if tech_data.nil?

        read
      else

        @tech_data = tech_data
      end

      @data = @tech_data

      # Ensure that the record within custom_attributes_adminmd_descmd exists
      @attribute = TechnicalMetadataAttribute.new(self) if @attribute.nil?
    end
    
    def read

      # @item.project.session.conn.exec_params('SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
      #                                       [@item.project.name, @item.number, @md_type, @element, @label]).select do |row|
      @item.project.session.conn.exec_params('SELECT tech_data FROM projects_techmd WHERE project_name=$1 AND item_number=$2 AND tech_element=$3 AND tech_label=$4',
                                             [@item.project.name, @item.number, @tech_element, @tech_label]).select do |row|

        @tech_data = row['tech_data']

        # @attribute_id = row['attribute_id'].to_i
        # @attribute = MetadataAttribute.new(self)
      end
    end

    def insert

      @attribute.insert
      if @item.project.session.conn.exec_params('SELECT tech_data FROM projects_techmd WHERE project_name=$1 AND item_number=$2 AND tech_element=$3 AND tech_label=$4',
                                                [@item.project.name, @item.number, @tech_element, @tech_label]).values.empty?

        @item.project.session.conn.exec_params('INSERT INTO projects_techmd (project_name, item_number, tech_element, tech_label, tech_data) VALUES ($1, $2, $3, $4, $5)',
                                               [@item.project.name, @item.number, @tech_element, @tech_label, @tech_data])

      end
    end

    def update

      @item.project.session.conn.exec_params('UPDATE projects_techmd SET tech_data=$5 WHERE project_name=$1 AND item_number=$2 AND tech_element=$3 AND tech_label=$4',
                                             [@item.project.name, @item.number, @tech_element, @tech_label, @tech_data])
    end
  end
