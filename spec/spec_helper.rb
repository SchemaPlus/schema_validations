# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_validations'
require 'schema_dev/rspec'

SchemaDev::Rspec.setup

RSpec.configure do |config|
  config.around(:each) do |example|
    remove_all_models

    ActiveRecord::Migration.suppress_messages do
      example.run
    ensure
      ActiveRecord::Base.connection.tables.each do |table|
        ActiveRecord::Migration.drop_table table, force: :cascade
      end
    end
  end
end

# avoid deprecation warnings
I18n.enforce_available_locales = true

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

def remove_all_models
  ActiveRecord::Base.descendants.each do |c|
    next if c == ActiveRecord::InternalMetadata
    next if c == ActiveRecord::SchemaMigration
    ActiveSupport::Dependencies.remove_constant c.name
  end
end

def define_schema(config={}, &block)
  ActiveRecord::Migration.suppress_messages do
    ActiveRecord::Schema.define do
      connection.tables.each do |table|
        drop_table table, force: :cascade
      end
      instance_eval &block
    end
  end
end

SimpleCov.command_name "[Ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING}]"
