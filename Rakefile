
require_relative 'metadb'
include MetaDB

namespace :metadb do

  desc 'Derive images for Items within a Project'
  task :derive, [:user, :password, :project_name, :host, :init, :term] do |t, args|

    args.with_defaults :host => 'localhost', :init => nil, :term => nil

    session = Session.new args.user, args[:password], args[:project_name], args.host
    session.project.derive args.init, args.term
  end

  desc 'Prefix titles for Items within a Project'
  task :prefix_titles, [:user, :password, :project_name, :prefix, :host] do |t, args|

    args.with_defaults :host => 'localhost'

    session = Session.new args.user, args[:password], args[:project_name], args.host
    session.project.prefix_titles args.prefix
  end
end
