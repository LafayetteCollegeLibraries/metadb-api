require 'pg'
require_relative 'project'

module MetaDB

  class Session
    attr_reader :conn, :project
    
    def initialize(user, password, project_name, host='127.0.0.1', dbName='metadb')
      
      @conn = PG::Connection.open(:host => host,
                                  :user => user,
                                  :password => password,
                                  :dbname => dbName)
      @project = Project.new self, project_name
    end
  end
end
