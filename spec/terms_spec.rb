require_relative 'spec_helper'

describe MetaDB::Metadata::Terms do

  describe '.mint' do

    it 'mints a new predicate for a MetaDB field name' do

      expect(described_class.mint('testelement', 'testlabel')).to be_a RDF::URI
      expect(described_class.mint('description', 'customlabel').to_s).to eql('http://authority.lafayette.edu/ns/metadb/descriptionCustomlabel')
      expect(described_class.mint('description', 'customLabel').to_s).to eql('http://authority.lafayette.edu/ns/metadb/descriptionCustomLabel')
      expect(described_class.mint('description', 'custom.label').to_s).to eql('http://authority.lafayette.edu/ns/metadb/descriptionCustomLabel')
    end
  end
end
