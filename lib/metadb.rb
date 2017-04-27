require 'pg'
require_relative 'metadb/project'
require_relative 'metadb/item'
require_relative 'metadb/metadata'
require_relative 'metadb/vocabulary'
require_relative 'metadb/term'
require_relative 'metadb/derivative'

module MetaDB
  SILK_ROAD = 'srida'
  
  class Session
    attr_reader :conn, :project
    
    def initialize(user, password, project_name = nil, host = '127.0.0.1', db_name = 'metadb', project_options = {})
      
      @conn = PG::Connection.open(:host => host,
                                  :user => user,
                                  :password => password,
                                  :dbname => db_name)

      read_project(project_name) if project_name
    end

    def read_project(project_name)
      @project = Project.new(self, project_name, [], {})
    end

    def vocabulary(vocabulary_name)
      Vocabulary.new self, vocabulary_name
    end
  end
end
