
require 'csv'

  # Modeling MetaDB Project entities
  #
  class Project

    attr_accessor :items
    attr_reader :session, :name

    def initialize(session, name, items = [])

      @session = session
      @name = name

      @items = []
      # Uncomment
      # @items = (1..1808).to_a

      # Uncomment
      read if @items.empty?
      @items += items
    end

    def parse(csv_file_path)

      data = CSV.read(csv_file_path)
      headers = data.shift

      data.each_index do |i|

        @items << Item.new(self, i, nil, headers)

        row = data[i]
        @items[i].set_fields row
      end
      @items
    end

    def read

      res = @session.conn.exec_params('SELECT item_number,id FROM items WHERE project_name=$1 ORDER BY item_number', [@name])

      # @todo Remove for debugging
      # res = @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1 ORDER BY item_number LIMIT 20', [@name])
      res.each do |item_record|

        puts "Instantiating an item record for #{item_record['item_number']}"

        # @items << Item.new(self, item_record['item_number'], item_record)
        @items << Item.new(self, item_record['item_number'], item_record['id'])
      end
    end

    def write

      if @session.conn.exec_params('SELECT item_number FROM items WHERE project_name=$1', [@name]).values.empty?

        @session.conn.exec_params("INSERT INTO projects (project_name, project_notes, deriv_host) VALUES($1, $2, 'http://metadb.lafayette.edu/')", [@name, ''])
      end

      @items.map { |item| item.write }.reduce { |results, result| results or result }
    end
  end
  
  class ProjectSet
    attr_reader :projects
    
    def initialize(session, projects = {})
      
      @session = session
      @projects = projects
    end
    
    # Split a project into a set
    def self.split(project, subset_length = 500)
      
      subset = {}
      
      i = 0
      while project.items.length > i

        if i == 0

          index = "0001"
          project_start = i
          project_length = subset_length - 1
        else

          index = "%04d" % i
          project_start = i - 1
          project_length = subset_length
        end

        child_project_name = project.name + '-' + index

        child_project = Project.new(project.session, child_project_name)
        subset[child_project_name] = child_project

        puts "Cloning the item record for the subset #{i}"

        # project.items.slice(i - 1, subset_length).each do |item|
        project.items.slice(project_start, project_length).each do |item|

          puts "Cloning the item record for #{item.number}"
          # Debugging
          # puts "Cloning the item record for #{item}"
          
          # Clones the MetaDB Item, and all associated fields
          # Uncomment
          item = item.clone(child_project, nil, [], 'lc-spcol-' + project.name)
          child_project.items << item
        end

        i += (subset_length)
      end
      
      set = ProjectSet.new @session, subset
    end
    
    # Join disparate sets of projects
    def self.join
      
      nil
    end
    
    def write
      
      @projects.values.map { |project| project.write }.reduce { |results, result| results or result }
    end
  end
