
module MetaDB
  module Metadata
    class AdminDescRecord < MetadataRecord

      def read

        res = @item.project.session.conn.exec_params('SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
                                                     [@item.project.name, @item.number, @md_type, @element, @label])
        res.each do |row|
          
          @data = row['data']
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
  end
end
