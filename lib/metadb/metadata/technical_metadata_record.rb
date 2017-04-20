
module MetaDB
  module Metadata
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

      @item.project.session.conn.exec_params('SELECT tech_data FROM projects_techmd WHERE project_name=$1 AND item_number=$2 AND tech_element=$3 AND tech_label=$4',
                                             [@item.project.name, @item.number, @tech_element, @tech_label]).select do |row|

        @tech_data = row['tech_data']
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
  end
end
