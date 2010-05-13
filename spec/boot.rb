plugin_root = File.join(File.dirname(__FILE__), '..')

$:.unshift "#{plugin_root}/lib"

Bundler.require
require 'initializer'

RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../') unless defined?(RAILS_ROOT)
Rails::Initializer.run(:set_load_path)
Rails::Initializer.run(:set_autoload_paths)
Rails::Initializer.run(:initialize_time_zone) do |config|
  config.time_zone = 'Pacific Time (US & Canada)'
end

require File.join(File.dirname(__FILE__), '..', 'rails', 'init.rb')

FileUtils.mkdir_p File.join(File.dirname(__FILE__), 'log')
ActiveRecord::Base.logger = Logger.new(File.join(File.dirname(__FILE__), 'log', 'spec.log'))

databases = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'db', 'database.yml')))
ActiveRecord::Base.establish_connection(databases[ENV['DB'] || 'sqlite3'])
load(File.join(File.dirname(__FILE__), 'db', 'schema.rb'))
