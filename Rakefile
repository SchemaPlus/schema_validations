require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = '-Ispec'
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "schema_validations #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

namespace :postgresql do
  desc 'Build the PostgreSQL test databases'
  task :build_databases do
    %x( createdb -E UTF8 schema_validations_unittest )
  end

  desc 'Drop the PostgreSQL test databases'
  task :drop_databases do
    %x( dropdb schema_validations_unittest )
  end

  desc 'Rebuild the PostgreSQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_postgresql_databases => 'postgresql:build_databases'
task :drop_postgresql_databases => 'postgresql:drop_databases'
task :rebuild_postgresql_databases => 'postgresql:rebuild_databases'

MYSQL_DB_USER = 'schema_validations'
namespace :mysql do
  desc 'Build the MySQL test databases'
  task :build_databases do
    %x( echo "create DATABASE schema_validations_unittest DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_unicode_ci " | mysql --user=#{MYSQL_DB_USER})
  end

  desc 'Drop the MySQL test databases' 
  task :drop_databases do
    %x( mysqladmin --user=#{MYSQL_DB_USER} -f drop schema_validations_unittest )
  end

  desc 'Rebuild the MySQL test databases'
  task :rebuild_databases => [:drop_databases, :build_databases]
end

task :build_mysql_databases => 'mysql:build_databases'
task :drop_mysql_databases => 'mysql:drop_databases'
task :rebuild_mysql_databases => 'mysql:rebuild_databases'
