
module MetaDB
  module Metadata
    NAMESPACE = "http://authority.lafayette.edu/ns/metadb/"

    class Terms < RDF::Vocabulary(NAMESPACE)

      def self.mint(metadb_element, metadb_label)

        if metadb_element == 'relation'
          if metadb_label == 'ispartof'
            metadb_label = 'IsPartOf'
          end
        elsif metadb_element == 'format'
          if metadb_label == 'extant'
            metadb_label = 'extent'
          end
        elsif metadb_element == 'rights'
          if metadb_label == 'availibility'
            metadb_label = 'availability'
          end
        elsif metadb_element == 'description'
          if metadb_label == 'Culture_of_Artifact_&_Artist'
            metadb_label = 'Culture_of_Artifact_and_Artist'
          end
        end

        normal_label = metadb_label.split('.').map {|s| s[0].upcase + s[1..-1] }.join
        slug = (metadb_element + normal_label)
        term slug.to_sym
      end      
    end
  end
end
