# -*- coding: utf-8 -*-

require_relative 'spec_helper'

describe 'Project' do

  let(:conn) do

    instance_double('Connection', :exec_params => [
                                                   # { 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
                                                   # { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }
                                                   {'item_number' => 1, 'id' => 101}
                                                  ] )
  end


  let(:session) do

    instance_double('Session', :conn => conn )
  end

  let(:items) do

    [ instance_double('Item', :number => 2, :file_name => 'lc-spcol-test-project-0002.tif', :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif' )) ]
  end

#  let(:item_class) do

    # class_double('Item', :new => instance_double('Item', :number => 3, :file_name => 'lc-spcol-test-project-0003.tif' ) )
#    class_double('Item', :new => instance_double('Item', :number => 3, :file_name => 'lc-spcol-test-project-0003.tif' ) ).as_stubbed_const
#  end

  let(:item) do

    # instance_double('Item', :number => 3, :file_path => '/var/metadb/master/test-project/lc-spcol-test-project-0003.tif' )
    instance_double('Item',
                    :number => 3,
                    :file_name => 'lc-spcol-test-project-0003.tif',
                    :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-test-project-0003.tif'),
                    :write => true)
  end

  describe '.new' do

    context 'without Items' do

      it 'creates a new Project' do

        # Work-around
        item_class = class_double('Item',
                                  :new => item,
                                  :get_field_class => AdminDescRecord).as_stubbed_const
        
        @project = Project.new session, 'test-project'

        expect(@project.name).to eq('test-project')
        expect(@project.items.length).to eq 1
        expect(@project.items.first.number).to eq 3
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0003.tif'
      end
    end

    context 'with Items' do

      it 'creates a new Project' do

        # Work-around
        # item_class = class_double('Item', :new => item ).as_stubbed_const
        item_class = class_double('Item',
                                  :new => item,
                                  :get_field_class => AdminDescRecord).as_stubbed_const

        @project = Project.new session, 'test-project', items

        expect(@project.name).to eq('test-project')

        expect(@project.items.length).to eq 1
        expect(@project.items.first.number).to eq 2
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0002.tif'
#        expect(@project.items.last.number).to eq 2
#        expect(@project.items.last.file_name).to eq 'lc-spcol-test-project-0002.tif'
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
      # item_class = class_double('Item', :new => item ).as_stubbed_const
      item_class = class_double('Item',
                                :new => item,
                                :get_field_class => AdminDescRecord).as_stubbed_const
      
      derivative_class = class_double('Derivative', :new => derivative).as_stubbed_const
      large_derivative_class = class_double('LargeDerivative', :new => large_derivative).as_stubbed_const
      custom_derivative_class = class_double('CustomDerivative', :new => custom_derivative).as_stubbed_const
      thumbnail_derivative_class = class_double('ThumbnailDerivative', :new => thumbnail_derivative).as_stubbed_const
        
      @project = Project.new session, 'test-project'

      derivatives = @project.derive

      expect(derivative).to have_received(:derive)
      expect(thumbnail_derivative).to have_received(:derive)
    end
  end

  describe '#add' do

    it 'creates new Items and adds them to a Project' do

      # @todo Refactor
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'element' => 'descriptive',
                                                                                                                                                        'label' => 'coverage'}])
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_techmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'tech_element' => 'format.technical',
                                                                                                                                                'tech_label' => 'PixelWidth'}])

      @project = Project.new session, 'test-project', []

      @project.add :item => item

      expect(item).to have_received(:write)
      expect(@project.items.length).to eq 1
    end
  end

  describe '#parse' do

    it 'creates new Items for newly uploaded image files' do

      # @todo Refactor
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'element' => 'descriptive',
                                                                                                                                     'label' => 'coverage'}])
      expect(conn).to receive(:exec_params).with('SELECT * FROM projects_techmd WHERE project_name=$1 LIMIT 1', ['test-project']).and_return([{ 'tech_element' => 'format.technical',
                                                                                                                             'tech_label' => 'PixelWidth'}])

      allow(conn).to receive(:exec_params).with('SELECT project_name, element, label, md_type,large,date_searchable,date_readable,controlled,multiple,additions,sorted,attribute_index,vocab_name,error,id,ui_label from custom_attributes_adminmd_descmd WHERE project_name=$1 AND element=$2 AND label=$3 AND md_type=$4',
                                                [ 'test-project',
                                                  'descriptive',
                                                  'coverage',
                                                  'descriptive'
                                                ]).and_return({})

      allow(conn).to receive(:exec_params).with('SELECT project_name, tech_element, tech_label FROM custom_attributes_techmd WHERE project_name=$1 AND tech_element=$2 AND tech_label=$3',
                                                      [ 'test-project',
                                                        'format.technical',
                                                        'PixelWidth'
                                                      ]).and_return({})


      [1,3,2].each do |i|


      
        allow(conn).to receive(:exec_params).with('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2', ['test-project', i]).and_return([{ 'element' => 'descriptive',
                                                                                                                                                                       'label' => 'coverage' }],{})
        allow(conn).to receive(:exec_params).with('SELECT * FROM projects_techmd WHERE project_name=$1 AND item_number=$2', ['test-project', i]).and_return([{ 'tech_element' => 'format.technical',
                                                                                                                                                               'tech_label' => 'PixelWidth' }],{})

        # 'SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',

        allow(conn).to receive(:exec_params).with('SELECT data,attribute_id FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2 AND md_type=$3 AND element=$4 AND label=$5',
                                                  ['test-project',
                                                   i,
                                                   'descriptive',
                                                   'descriptive',
                                                   'coverage'
                                                  ]).and_return({})

        allow(conn).to receive(:exec_params).with('SELECT tech_data FROM projects_techmd WHERE project_name=$1 AND item_number=$2 AND tech_element=$3 AND tech_label=$4',
                                                  ['test-project', i, 'format.technical', 'PixelWidth']).and_return({})
      end

      @project = Project.new session, 'test-project', [], :dir_path => File.join(File.dirname(__FILE__), 'fixtures')

      @project.parse
      expect(@project.items.length).to eq 2
    end
  end
end
