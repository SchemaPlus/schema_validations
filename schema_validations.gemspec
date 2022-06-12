# frozen_string_literal: true

$:.push File.expand_path("../lib", __FILE__)
require "schema_validations/version"

Gem::Specification.new do |gem|
  gem.name        = "schema_validations"
  gem.version     = SchemaValidations::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Ronen Barzel", "Michał Łomnicki"]
  gem.email       = ["ronen@barzel.org", "michal.lomnicki@gmail.com"]
  gem.homepage    = "https://github.com/SchemaPlus/schema_validations"
  gem.summary     = "Automatically creates validations basing on the database schema."
  gem.description = "SchemaValidations extends ActiveRecord to automatically create validations by inspecting the database schema. This makes your models more DRY as you no longer need to duplicate NOT NULL, unique, numeric and varchar constraints on the model level."
  gem.license     = 'MIT'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.required_ruby_version = '>= 2.5'

  gem.add_dependency 'schema_plus_columns', '~> 1.0.1'
  gem.add_dependency 'activerecord', '>= 5.2', '< 7.1'
  gem.add_dependency 'valuable'

  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'schema_dev', '~> 4.2.0'
end
