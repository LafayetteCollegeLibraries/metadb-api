# -*- coding: utf-8 -*-

require_relative 'spec_helper'

describe MetaDB::Item do

  #  '/var/metadb/master/test-project'
  let(:project) { instance_double('Project', :name => 'test-project', :session => @session, :dir_path => File.join(File.dirname(__FILE__), 'fixtures')) }

  describe '.new' do

    before :each do

      @conn = instance_double('Connection', :exec_params => [
                                                             { 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
                                                             { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }
                                                            ] )

      @session = instance_double('Session', :conn => @conn )
      

      @field = instance_double('DescRecord', :element => 'title', :label => 'english')
    end

    context 'using an existing MetaDB Item' do

      it 'creates a new Item from a MetaDB record' do

        # @item = Item.new(project, 1)
        @item = described_class.new(project, 3, '0003', [ @field ])

        expect(@item.file_name).to eq 'lc-spcol-test-project-0003.tif'
        expect(@item.file_path).to eq File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif')
      end
    end

    context 'using an existing file path' do

      it 'creates a new Item from an image in the TIFF' do

        @item = described_class.new project, file_path: File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif')

        expect(@item.number).to eq 3
        expect(@item.id).to eq '0003'
      end

      it 'creates a new Item from an image in the JPEG format' do
        
        test_file_path = File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0002.jpg')

        @item = described_class.new project, file_path: test_file_path

        expect(@item.number).to eq 2
        expect(@item.id).to eq '0002'
      end

      it 'raises exceptions for improperly structured file names' do
        
        test_file_path = File.join(File.dirname(__FILE__), 'fixtures', '.DS_Store')
        expect { @item = described_class.new project, file_path: test_file_path }.to raise_error("Failed to parse the master image file path #{test_file_path}")
      end
    end
  end

  describe '#write' do

    before :each do

      @conn = instance_double('Connection')
      allow(@conn).to receive(:exec_params).and_return([{ 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
                                                        { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }],
                                                       {})

      @session = instance_double('Session', :conn => @conn )
      # @project = instance_double('Project', :name => 'test-item', :session => @session, :dir_path => '/var/metadb/master/test-item')

      @field = instance_double('DescRecord', :element => 'title', :label => 'english')
    end

    it 'updates an Item for a MetaDB record' do

      @item = described_class.new(project, 3)

      # :custom_file_name, :thumbnail_file_name, :large_file_name, :fullsize_file_name
      @item.custom_file_name = 'lc-spcol-test-project-0003-800.tif'
      @item.thumbnail_file_name = 'lc-spcol-test-project-0003-300.tif'
      @item.large_file_name = 'lc-spcol-test-project-0003-2000.tif'
      @item.fullsize_file_name = 'lc-spcol-test-project-0003.tif'

      expect(@conn).to receive(:exec_params).with("SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2", ['test-project', 3]).and_return({})

      expect(@conn).to receive(:exec_params).with("INSERT INTO items (project_name, item_number, file_name, thumbnail_file_name, custom_file_name, large_file_name, fullsize_file_name, checksum) VALUES($1, $2, $3, $4, $5, $6, $7, '')",
                                                  [ 'test-project',
                                                    3,
                                                    'lc-spcol-test-project-0003.tif',
                                                    'lc-spcol-test-project-0003-300.tif',
                                                    'lc-spcol-test-project-0003-800.tif',
                                                    'lc-spcol-test-project-0003-2000.tif',
                                                    'lc-spcol-test-project-0003.tif']).and_return([{}])

      @item.write

    end
  end
end
