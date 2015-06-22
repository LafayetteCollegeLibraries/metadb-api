# -*- coding: utf-8 -*-

require_relative 'spec_helper'

describe 'Item' do

  describe '.new' do

    before :each do

      #       res = @project.session.conn.exec_params('SELECT * FROM projects_adminmd_descmd WHERE project_name=$1 AND item_number=$2', [ @project.name,

      @conn = instance_double('Connection', :exec_params => [
                                                             { 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
                                                             { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }
                                                            ] )

#      @conn = instance_double('Connection')
#      allow(@conn).to receive(:exec_params).and_return(
#                                                       [
#                                                        { 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
#                                                        { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }
#                                                       ],
#                                                       {}
#                                                       )

      @session = instance_double('Session', :conn => @conn )
      @project = instance_double('Project', :name => 'test-item', :session => @session)

      @field = instance_double('DescRecord', :element => 'title', :label => 'english')
    end

    it 'creates a new Item from a MetaDB record' do

      @item = Item.new(@project, 1)

      @item = Item.new(@project, 1, '0001', [ @field ])
    end
  end

  describe '#write' do

    before :each do

      @conn = instance_double('Connection')
      allow(@conn).to receive(:exec_params).and_return(
                                                       [
                                                        { 'element' => 'title', 'label' => 'japanese', 'data' => '試し' },
                                                        { 'element' => 'coverage', 'label' => 'location', 'data' => 'test location' }
                                                       ],
                                                       {}
                                                       )

      @session = instance_double('Session', :conn => @conn )
      @project = instance_double('Project', :name => 'test-item', :session => @session)

      @field = instance_double('DescRecord', :element => 'title', :label => 'english')
    end

    it 'updates an Item for a MetaDB record' do

      @item = Item.new(@project, 1)

      # :custom_file_name, :thumbnail_file_name, :large_file_name, :fullsize_file_name
      @item.custom_file_name = 'lc-spcol-test-item-0001-800.tif'
      @item.thumbnail_file_name = 'lc-spcol-test-item-0001-300.tif'
      @item.large_file_name = 'lc-spcol-test-item-0001-2000.tif'
      @item.fullsize_file_name = 'lc-spcol-test-item-0001.tif'

      expect(@conn).to receive(:exec_params).with(
                                                  "INSERT INTO items (project_name, item_number, file_name, thumbnail_file_name, custom_file_name, large_file_name, fullsize_file_name, checksum) VALUES($1, $2, $3, $4, $5, $6, $7, '')",
                                                  [ 'test-item',
                                                    1,
                                                    'lc-spcol-test-item-0001.tif',
                                                    'lc-spcol-test-item-0001-300.tif',
                                                    'lc-spcol-test-item-0001-800.tif',
                                                    'lc-spcol-test-item-0001-2000.tif',
                                                    'lc-spcol-test-item-0001.tif']
                                                  )
      @item.write

    end
  end
end