
require_relative 'metadb'
include MetaDB

namespace :metadb do

  desc 'Derive images for Items within a Project'
  task :derive, [:user, :password, :project_name, :host] do |t, args|

    args.with_defaults :host => 'localhost'

    session = Session.new args.user, args[:password], args[:project_name], args.host
    session.project.derive
  end
end
