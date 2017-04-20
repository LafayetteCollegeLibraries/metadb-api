
module MetaDB
  module Metadata
    # Class for the DescRecord
    class DescRecord < AdminDescRecord
    
      def initialize(item, element, label, data='', attribute=nil)
      
        @md_type = 'descriptive'
        super(item, element, label, data, attribute)
      end
    end
  end
end
