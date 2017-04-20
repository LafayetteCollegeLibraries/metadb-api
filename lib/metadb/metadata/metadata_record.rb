
module MetaDB
  module Metadata
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

      # Ensure that the record within custom_attributes_adminmd_descmd exists
      @attribute = MetadataAttribute.new(self) if @attribute.nil?
    end
  end
  end
end
