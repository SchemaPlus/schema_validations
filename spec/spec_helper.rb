require 'simplecov'
require 'simplecov-gem-profile'
SimpleCov.start "gem"

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rspec'
require 'active_record'
require 'schema_validations'
require 'schema_dev/rspec'

SchemaDev::Rspec.setup_db('sqlite3')


# avoid deprecation warnings
I18n.enforce_available_locales = true

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each {|f| require f}

def remove_all_models
  ObjectSpace.each_object(Class) do |c|
    next unless c.ancestors.include? ActiveRecord::Base
    next if c == ActiveRecord::Base
    next if c.name.blank?
    ActiveSupport::Dependencies.remove_constant c.name
  end
end

SimpleCov.command_name "[Ruby #{RUBY_VERSION} - ActiveRecord #{::ActiveRecord::VERSION::STRING}]"
