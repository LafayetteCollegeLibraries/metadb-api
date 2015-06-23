require_relative 'spec_helper'

include Derivatives

context 'when generating all derivatives' do

  let(:project) { instance_double('Project', :name => 'project') }
  let(:item) do

    instance_double( 'Item',
                     :file_name => 'lc-spcol-test-project-0003.tif',
                     :file_path => File.join( File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif'),
                     :project => project,
                     :number => 1)
  end

  let(:item_2) do

    instance_double( 'Item',

                     :file_name => 'lc-spcol-test-project-0003.tif',
                     :file_path => File.join( File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif'),
                     :project => project,
                     :number => 2)
  end

  let(:item_3) do

    instance_double( 'Item',

                     :file_name => 'lc-spcol-test-project-0003.tif',
                     :file_path => File.join( File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif'),
                     :project => project,
                     :number => 3)
    
  end

  describe '#new' do

    it 'initializes derivatives for MetaDB Items' do

      @derivative = Derivative.new item
    end
  end

  describe '#derive' do

    let(:derivative) { Derivative.new item }

    it 'derives JPEG\'s for MetaDB Items' do

      expect(item).to receive(:write)
      output_file = derivative.derive

      expect(output_file).to eq('/tmp/lc-spcol-project-0001.jpg')
    end

    context 'when appending branding under the derivative images' do

      it 'derives branded JPEG\'s for MetaDB Items' do
        
        @derivative_2 = Derivative.new item_2, :branding => BRANDING_UNDER, :branding_text => 'Testing branding'
        
        expect(item_2).to receive(:write)
        output_file_path = @derivative_2.derive
        
        expect(output_file_path).to eq('/tmp/lc-spcol-project-0002.jpg')
        
        output_file_contents = File.open(output_file_path, 'r') { |f| f.read }
        unbranded_file_contents = File.open('/tmp/lc-spcol-project-0001.jpg', 'r') { |f| f.read }
        
        expect(output_file_contents).not_to eq(unbranded_file_contents)
      end
    end

    context 'when appending branding over the derivative images' do
      
      it 'derives branded JPEG\'s for MetaDB Items' do
        
        @derivative_3 = Derivative.new item_3, :branding => BRANDING_OVER, :branding_text => 'Testing branding'
        
        expect(item_3).to receive(:write)
        output_file_path = @derivative_3.derive
        
        expect(output_file_path).to eq('/tmp/lc-spcol-project-0003.jpg')
        
        output_file_contents = File.open(output_file_path, 'r') { |f| f.read }
        unbranded_file_contents = File.open('/tmp/lc-spcol-project-0001.jpg', 'r') { |f| f.read }
        
        expect(output_file_contents).not_to eq(unbranded_file_contents)
        
        branded_under_file_contents = File.open('/tmp/lc-spcol-project-0002.jpg', 'r') { |f| f.read }
        
        expect(output_file_contents).not_to eq(branded_under_file_contents)
      end
    end    
  end

describe 'ThumbnailDerivative' do

  describe '#derive' do

      let(:thumbnail) { ThumbnailDerivative.new item }

    it 'derives thumbnail JPEG\'s for MetaDB Items' do

      expect(item).to receive(:write)
      output_file = thumbnail.derive

      expect(output_file).to eq('/tmp/lc-spcol-project-0001-300.jpg')
    end
  end
end

describe 'LargeDerivative' do

  describe '#derive' do

      let(:large) { LargeDerivative.new item }

    it 'derives large JPEG\'s for MetaDB Items' do

      expect(item).to receive(:write)
      output_file = large.derive

      expect(output_file).to eq('/tmp/lc-spcol-project-0001-2000.jpg')
    end
  end
end

describe 'CustomDerivative' do

  describe '#derive' do

      let(:custom) { CustomDerivative.new item }

    it 'derives custom JPEG\'s for MetaDB Items' do

      expect(item).to receive(:write)
      output_file = custom.derive

      expect(output_file).to eq('/tmp/lc-spcol-project-0001-800.jpg')
    end
  end
end
end
