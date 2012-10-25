require 'rubygems'
require 'bundler'

Bundler.setup
Bundler.require

require "rspec/core/rake_task"


desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
RSpec::Core::RakeTask.new(:spec) do |spec|
end

YARD::Rake::YardocTask.new(:doc) do |t|
  t.files   = ['lib/**/*.rb', '-', 'HISTORY.md']
  t.options = ['--no-private', '--title', 'Reportable Documentation']
end

