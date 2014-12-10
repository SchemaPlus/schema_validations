# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "schema_validations/version"

Gem::Specification.new do |s|
  s.name        = "schema_validations"
  s.version     = SchemaValidations::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ronen Barzel", "Michał Łomnicki"]
  s.email       = ["ronen@barzel.org", "michal.lomnicki@gmail.com"]
  s.homepage    = "https://github.com/SchemaPlus/schema_validations"
  s.summary     = "Automatically creates validations basing on the database schema."
  s.description = "SchemaValidations extends ActiveRecord to automatically create validations by inspecting the database schema. This makes your models more DRY as you no longer need to duplicate NOT NULL, unique, numeric and varchar constraints on the model level."
  s.license     = 'MIT'

  s.rubyforge_project = "schema_validations"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("schema_plus")
      
  s.add_development_dependency("schema_dev", "~> 1.0")
  s.add_development_dependency("rake")
  s.add_development_dependency("rdoc")
  s.add_development_dependency("rspec")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("simplecov-gem-profile")
  s.add_development_dependency("database_cleaner")
end

