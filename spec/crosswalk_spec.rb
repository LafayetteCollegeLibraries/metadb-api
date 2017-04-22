require_relative 'spec_helper'

describe MetaDB::Metadata::Crosswalk do

  describe '.normalize' do

    it 'splits MetaDB field values' do
      expect(described_class.normalize('foo;bar;baz', '')).to eql('foo;bar;baz')
    end
  end

  describe '.predicate_for' do

    it 'generates predicates for custom MetaDB fields' do
      expect(described_class.predicate_for('date', 'image.lower').to_s).to eql('http://authority.lafayette.edu/ns/metadb/dateImageLower')
    end

    it 'generates predicates for members of the Dublin Core metadata element set' do
      expect(described_class.predicate_for('date', '').to_s).to eql(::RDF::Vocab::DC11.date.to_s)
    end

    it 'generates predicates for Dublin Core terms' do
      expect(described_class.predicate_for('created', '').to_s).to eql(::RDF::Vocab::DC.created.to_s)
      expect(described_class.predicate_for('rights', '').to_s).to eql(::RDF::Vocab::DC.rights.to_s)
      expect(described_class.predicate_for('source', '').to_s).to eql(::RDF::Vocab::DC.source.to_s)
      expect(described_class.predicate_for('title', '').to_s).to eql(::RDF::Vocab::DC.title.to_s)
      expect(described_class.predicate_for('type', '').to_s).to eql(::RDF::Vocab::DC.type.to_s)
      expect(described_class.predicate_for('identifier', '').to_s).to eql(::RDF::Vocab::DC.identifier.to_s)
    end
  end

  describe '.custom_predicate_for' do

    it 'generates predicates for custom MetaDB fields' do
      expect(described_class.predicate_for('date', 'image.lower').to_s).to eql('http://authority.lafayette.edu/ns/metadb/dateImageLower')
    end
  end

  context 'with Item metadata' do
    let(:metadata) do
      [
        {:element => 'date', :label => 'image.lower', :data => '1932'},
        {:element => 'date', :label => 'image.upper', :data => '1933-02-14;1934-03-15'}
      ]
    end

    describe '.transform' do
      it 'transforms MetaDB metadata records' do

        transformed = described_class.transform(metadata)
        expect(transformed).to include({"http://authority.lafayette.edu/ns/metadb/dateImageLower" => "1932"})
        expect(transformed).to include({"http://authority.lafayette.edu/ns/metadb/dateImageUpper" => "1933-02-14;1934-03-15"})
      end
    end
  end
end
