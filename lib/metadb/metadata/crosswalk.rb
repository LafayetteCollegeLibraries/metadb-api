
require "rdf/vocab"

module MetaDB
  module Metadata
    class Crosswalk

      def self.normalize(value, metadb_label, delimiter = ';')
        normal_values = []

        if not value.nil? and not value.empty?
          normal_values = value.split(';').map do |single_value|
            
            case metadb_label
            when 'url.download'
              single_value.split('?item=').last
            else
              single_value
            end
          end
        end
        normal_values.join(delimiter)
      end

      def self.predicate_for(metadb_element, metadb_label)
        if metadb_label.empty? && ::RDF::Vocab::DC[metadb_element]
          ::RDF::Vocab::DC[metadb_element]
        else
          MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
        end
      end

      def self.custom_predicate_for(metadb_element, metadb_label)
        case metadb_element
        when 'contributor'
          predicate = ::RDF::Vocab::DC.contributor
        when 'coverage'
          case metadb_label
          when 'location'
            predicate = ::RDF::Vocab::DC.spatial
          when 'location.country'
            predicate = ::RDF::Vocab::DC.spatial
          when *CUSTOM_LABELS
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.coverage
          end
        when 'creator'
          case metadb_label
          when *CUSTOM_LABELS
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.creator
          end
        when 'date'
          case metadb_label
          when *CUSTOM_LABELS
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.date
          end
        when 'description'
          case metadb_label
          when 'Description'
            predicate = ::RDF::Vocab::DC.description
          when 'location'
            predicate = ::RDF::Vocab::DC.spatial
          when 'Location'
            predicate = ::RDF::Vocab::DC.spatial
          when 'text.english'
            predicate = ::RDF::Vocab::DC.description
          when 'text.french'
            predicate = ::RDF::Vocab::DC.description
          when 'text.german'
            predicate = ::RDF::Vocab::DC.description
          when 'text.japanese'
            predicate = ::RDF::Vocab::DC.description
          when *CUSTOM_LABELS
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)              
          else
            predicate = ::RDF::Vocab::DC.description
          end
        when 'format'
          case metadb_label
          when 'extant'
            predicate = ::RDF::Vocab::DC.extent
          when 'extent'
            predicate = ::RDF::Vocab::DC.extent
          when 'medium'
            predicate = ::RDF::Vocab::DC.medium
          when *CUSTOM_LABELS
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.format
          end
        when 'publisher'
          predicate = ::RDF::Vocab::DC.publisher
        when 'relation'
          case metadb_label
          when 'ispartof'
            predicate = ::RDF::Vocab::Bibframe.partOf
          when 'isPartOf'
            predicate = ::RDF::Vocab::Bibframe.partOf
          when 'relation.work.textref.name'
          predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.relation
          end
        when 'rights'
          predicate = ::RDF::Vocab::DC.rights
        when 'source'
          predicate = ::RDF::Vocab::DC.source
        when 'subject'
          case metadb_label
          when 'subject.work.subject.term'
            predicate = MetaDB::Metadata::Terms.mint(metadb_element, metadb_label)
          else
            predicate = ::RDF::Vocab::DC.subject
          end
        when 'title'
          predicate = ::RDF::Vocab::DC.title
        when 'identifier'
          predicate = ::RDF::Vocab::DC.identifier
        else
          raise NotImplementedError.new "No predicate for #{metadb_element}.#{metadb_label}"
        end
      end

      def self.transform(metadb_metadata)
        transformed_metadata = {}

        # Filter for technical metadata
        metadb_metadata.reject {|record| record[:element].include?('.technical') || FILTERED_FIELDS.include?(record[:label]) }.each do |record|
          predicate = predicate_for(record[:element], record[:label])
          if transformed_metadata.has_key?(predicate) && !transformed_metadata[predicate].empty?
            transformed_metadata[predicate] += ';' + normalize(record[:data], record[:label])
          else
            transformed_metadata[predicate] = normalize(record[:data], record[:label])
          end
        end

        transformed_metadata
      end
    end
  end
end
