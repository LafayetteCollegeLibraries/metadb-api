
module MetaDB
  module Metadata
    NAMESPACE = "http://authority.lafayette.edu/ns/metadb/"

    class Terms < RDF::Vocabulary(NAMESPACE)

      def self.mint(metadb_element, metadb_label)

        normal_label = metadb_label.split('.').map {|s| s[0].upcase + s[1..-1] }.join
        slug = (metadb_element + normal_label)
        term slug.to_sym
      end      
    end
  end
end
