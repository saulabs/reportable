ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'active_record/version'
require 'active_support'

begin
  require 'ruby-debug'
  # Debugger.start
  # Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
rescue LoadError
  # ruby-debug wasn't available so neither can the debugging be
end

ROOT = Pathname(File.expand_path(File.join(File.dirname(__FILE__), '..')))

$LOAD_PATH << File.join(ROOT, 'lib')
$LOAD_PATH << File.join(ROOT, 'lib/saulabs')

require File.join(ROOT, 'lib', 'saulabs', 'reportable.rb')

# Rails::Initializer.run(:set_load_path)
# Rails::Initializer.run(:set_autoload_paths)
# Rails::Initializer.run(:initialize_time_zone) do |config|
#   config.time_zone = 'Pacific Time (US & Canada)'
# end

# FileUtils.mkdir_p File.join(File.dirname(__FILE__), 'log')
# ActiveRecord::Base.logger = ActiveSupport::BufferedLogger.new(File.dirname(__FILE__) + "/log/spec.log")

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
ActiveRecord::Base.default_timezone = :local

databases = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'db', 'database.yml')))
ActiveRecord::Base.establish_connection(databases[ENV['DB'] || 'sqlite3'])
load(File.join(File.dirname(__FILE__), 'db', 'schema.rb'))

class User < ActiveRecord::Base; end

class YieldMatchException < Exception; end
