require 'pg'
require_relative 'project'

module MetaDB

  SILK_ROAD = 'srida'

  class Session
    attr_reader :conn, :project
    
    def initialize(user, password, project_name, host='127.0.0.1', db_name='metadb', project_options = {})
      
      @conn = PG::Connection.open(:host => host,
                                  :user => user,
                                  :password => password,
                                  :dbname => db_name)

      @project = Project.new self, project_name, nil, project_options
    end
  end
end
