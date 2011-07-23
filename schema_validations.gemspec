# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "schema_validations/version"

Gem::Specification.new do |s|
  s.name        = "schema_validations"
  s.version     = SchemaValidations::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ronen Barzel", "Michał Łomnicki"]
  s.email       = ["ronen@barzel.org", "michal.lomnicki@gmail.com"]
  s.homepage    = "https://github.com/lomba/schema_validations"
  s.summary     = "Enhances ActiveRecord schema mechanism, including more DRY index creation and support for foreign key constraints and views."
  s.summary     = "Sets validations on ActiveRecord models basing on database schema."
  s.description = "SchemaValidations extends ActiveRecord to automatically create validations by inspecting the database schema. This makes your models more DRY as you no longer need to duplicate NOT NULL, unique, numeric and varchar constraints on the model level."

  s.rubyforge_project = "schema_validations"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency("schema_plus")
      
  case ENV['SCHEMA_VALIDATIONS_RAILS_VERSION']
  when '3.0'
      s.add_development_dependency("rails", "~> 3.0")
      s.add_development_dependency("mysql2", "~> 0.2.6")
  when '3.1'
      s.add_development_dependency("rails", ">= 3.1.0.rc4")
      s.add_development_dependency("mysql2")
  else
      s.add_development_dependency("mysql2")
  end

  s.add_development_dependency("rake", "~> 0.8.7")
  s.add_development_dependency("rspec")
  s.add_development_dependency("sqlite3")
  s.add_development_dependency("simplecov")
  s.add_development_dependency("simplecov-gem-adapter")
  s.add_development_dependency("ruby-debug19") if RUBY_VERSION >= "1.9.2"
end

