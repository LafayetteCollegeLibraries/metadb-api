require 'pg'
require_relative 'project'
require_relative 'vocabulary'

module MetaDB

  SILK_ROAD = 'srida'

  class Session
    attr_reader :conn, :project
    
    def initialize(user, password, project_name = nil, host = '127.0.0.1', db_name = 'metadb', project_options = {})
      
      @conn = PG::Connection.open(:host => host,
                                  :user => user,
                                  :password => password,
                                  :dbname => db_name)

      project(project_name) if project_name
    end

    def project(project_name)
      if project_name
        @project = Project.new(self, project_name, [], {})
      end
    end

    def vocabulary(vocabulary_name)
      Vocabulary.new self, vocabulary_name
    end
  end
end
