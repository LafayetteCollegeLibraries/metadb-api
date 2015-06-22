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

    [ instance_double('Item', :number => 2, :file_name => 'lc-spcol-test-project-0002.tif', :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-project-0001.tif' )) ]
  end

#  let(:item_class) do

    # class_double('Item', :new => instance_double('Item', :number => 3, :file_name => 'lc-spcol-test-project-0003.tif' ) )
#    class_double('Item', :new => instance_double('Item', :number => 3, :file_name => 'lc-spcol-test-project-0003.tif' ) ).as_stubbed_const
#  end

  let(:item) do

    # instance_double('Item', :number => 3, :file_path => '/var/metadb/master/test-project/lc-spcol-test-project-0003.tif' )
    instance_double('Item', :number => 3, :file_name => 'lc-spcol-test-project-0003.tif', :file_path => File.join(File.dirname(__FILE__), 'fixtures', 'lc-spcol-project-0001.tif' ) )
  end

  describe '.new' do

    context 'without Items' do

      it 'creates a new Project' do

        # Work-around
        item_class = class_double('Item', :new => item ).as_stubbed_const
        
        @project = Project.new session, 'test-project'

        expect(@project.name).to eq('test-project')
        expect(@project.items.length).to eq 1
        expect(@project.items.first.number).to eq 3
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0003.tif'
      end
    end

    context 'with Items' do

      it 'creates a new Project' do

        item_class = class_double('Item', :new => item ).as_stubbed_const

        @project = Project.new session, 'test-project', items

        expect(@project.name).to eq('test-project')

        expect(@project.items.length).to eq 2
        expect(@project.items.first.number).to eq 3
        expect(@project.items.first.file_name).to eq 'lc-spcol-test-project-0003.tif'
        expect(@project.items.last.number).to eq 2
        expect(@project.items.last.file_name).to eq 'lc-spcol-test-project-0002.tif'
      end
    end
  end

  describe '#derive' do

    let(:derivative) { instance_double('Derivative', :item => item, :derive => [] ) }
    let(:large_derivative) { instance_double('LargeDerivative', :item => item, :derive => [] ) }
    let(:custom_derivative) { instance_double('CustomDerivative', :item => item, :derive => [] ) }
    let(:thumbnail_derivative) { instance_double('ThumbnailDerivative', :item => item, :derive => [] ) }

    it 'derives images for all Items' do

      # Work-around
      item_class = class_double('Item', :new => item ).as_stubbed_const

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
end
