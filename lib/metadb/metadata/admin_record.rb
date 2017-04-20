
module MetaDB
  module Metadata
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
  end
end

