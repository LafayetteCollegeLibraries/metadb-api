# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metadb/version'

Gem::Specification.new do |spec|
  spec.name        = 'metadb_api'
  spec.version     = MetaDB::VERSION
  spec.summary     = "MetaDB API"
  spec.description = "A migration API for (legacy) MetaDB"
  spec.authors     = ["James R. Griffin III"]
  spec.email       = 'griffinj@lafayette.edu'
  spec.files       = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  spec.test_files  = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.homepage    = 'https://github.com/LafayetteCollegeLibraries/metadb-api'
  spec.license     = 'GPLv3'
end
