require 'rake'
require 'spec/rake/spectask'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.rcov_opts  << '--exclude "gems/*,spec/*,init.rb"'
  t.rcov       = true
  t.rcov_dir   = 'doc/coverage'
  t.spec_files = FileList['spec/**/*_spec.rb']
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['lib/**/*.rb', '-', 'HISTORY.md']
    t.options = ['--no-private', '--title', 'Reportable Documentation']
  end
rescue LoadError
end

begin
  require 'simplabs/excellent/rake'
  Simplabs::Excellent::Rake::ExcellentTask.new(:excellent) do |t|
    t.paths = %w(lib)
  end
rescue LoadError
end
