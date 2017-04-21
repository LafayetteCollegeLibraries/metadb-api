module MetaDB
  module Metadata

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
        read
      end

      def read

        @field.item.project.session.conn.exec_params('SELECT project_name, tech_element, tech_label, custom_attributes_techmd WHERE project_name=$1 AND tech_element=$2 AND tech_label=$3',
                                                     [ @project_name,
                                                       @tech_element,
                                                       @tech_label,
                                                     ]).select do |row|
        
          @project_name = row['project_name']
          @tech_element = row['tech_element']
          @tech_label = row['tech_label']
        end
      end
    end
  end
end
