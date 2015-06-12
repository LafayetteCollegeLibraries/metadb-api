require_relative 'spec_helper'

include Derivatives

describe 'Derivative' do

  before :each do

    @project = instance_double('Project', :name => 'project')
    @item = instance_double( 'Item',
                             :file_name => File.join( File.dirname(__FILE__), 'fixtures', 'lc-spcol-project-0001.tif'),
                             :project => @project,
                             :number => 1)
  end

  describe '#new' do

    it 'initializes derivatives for MetaDB Items' do

      @derivative = Derivative.new @item
    end
  end

  describe '#derive' do

    before :each do

      @derivative = Derivative.new @item
    end

    it 'derives JPEG\'s for MetaDB Items' do

      expect(@item).to receive(:write)
      output_file = @derivative.derive

      expect(output_file).to eq('/tmp/lc-spcol-project-0001.jpg')
    end
  end
end
