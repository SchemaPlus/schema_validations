require 'logger'

ActiveRecord::Base.logger = Logger.new(File.open("sqlite3.log", "w"))

ActiveRecord::Base.configurations = {
  'schema_validations' => {
    :adapter => 'sqlite3',
    :database => File.expand_path('schema_validations.sqlite3', File.dirname(__FILE__)),
  }

}

ActiveRecord::Base.establish_connection 'schema_validations'
ActiveRecord::Base.connection.execute "PRAGMA synchronous = OFF"
