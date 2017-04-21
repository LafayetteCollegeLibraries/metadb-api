# -*- coding: utf-8 -*-

require_relative 'spec_helper'

describe MetaDB::Project do

  let(:conn) do
    instance_double('Connection', :exec_params => [{'item_number' => 1, 'id' => 101}])
  end

  let(:session) do
    instance_double('Session', :conn => conn )
  end

  let(:items) do
    [ instance_double('Item', :number => 2, :file_name => 'lc-spcol-test-project-0002.tif', :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif' )) ]
  end

  let(:item) do
    instance_double('Item',
                    :number => 3,
                    :file_name => 'lc-spcol-test-project-0003.tif',
                    :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif'),
                    :write => true,
                    :project => instance_double('Project', :name => 'test-project'),
                    :derivative_base => 'lc-spcol-project')
  end

  describe '.new' do
    context 'without Items' do
      it 'creates a new Project' do

        # Work-around
        item_class = class_double('Item',
                                  :new => item,
                                  :get_field_class => MetaDB::Metadata::AdminDescRecord).as_stubbed_const

        @project = described_class.new session, 'test-project', [item]

        expect(@project.name).to eq('test-project')
        expect(@project.items.length).to eq 1
        expect(@project.items.first.number).to eq 3
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0003.tif'
      end
    end

    context 'with Items' do

      it 'creates a new Project' do

        # Work-around
        item_class = class_double('Item',
                                  :new => item,
                                  :get_field_class => MetaDB::Metadata::AdminDescRecord).as_stubbed_const

        @project = described_class.new session, 'test-project', items

        expect(@project.name).to eq('test-project')

        expect(@project.items.length).to eq 1
        expect(@project.items.first.number).to eq 2
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0002.tif'
      end
    end
  end

  describe '.split' do

    it 'splits a project into 3 subsets' do

      nil
    end
  end

  describe '#derive' do

    let(:derivative) { instance_double('Derivative', :item => item, :derive => [] ) }
    let(:large_derivative) { instance_double('LargeDerivative', :item => item, :derive => [] ) }
    let(:custom_derivative) { instance_double('CustomDerivative', :item => item, :derive => [] ) }
    let(:thumbnail_derivative) { instance_double('ThumbnailDerivative', :item => item, :derive => [] ) }

    it 'derives images for all Items' do

      # Work-around
      item_class = class_double('Item',
                                :new => item,
                                :get_field_class => MetaDB::Metadata::AdminDescRecord).as_stubbed_const
      
      derivative_class = class_double('Derivative', :new => derivative).as_stubbed_const
      large_derivative_class = class_double('LargeDerivative', :new => large_derivative).as_stubbed_const
      custom_derivative_class = class_double('CustomDerivative', :new => custom_derivative).as_stubbed_const
      thumbnail_derivative_class = class_double('ThumbnailDerivative', :new => thumbnail_derivative).as_stubbed_const
        
      @project = described_class.new session, 'test-project', [item], :dir_path => File.join( File.dirname(__FILE__), 'fixtures'), :access_path => File.join( File.dirname(__FILE__), 'fixtures')

      derivatives = @project.derive
    end
  end

  describe '#add' do

    it 'creates new Items and adds them to a Project' do

      # @todo Refactor
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'element' => 'descriptive',
                                                                                                                                                        'label' => 'coverage'}])
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_techmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'tech_element' => 'format.technical',
                                                                                                                                                'tech_label' => 'PixelWidth'}])

      @project = described_class.new session, 'test-project', [item]

      @project.add :item => item

      expect(item).to have_received(:write)
      expect(@project.items.length).to eq 2
    end
  end
end
