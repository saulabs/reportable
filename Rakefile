require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run specs.'
task :default => :spec

desc 'Run the specs on the CI server.'
Spec::Rake::SpecTask.new(:ci) do |t|
  t.spec_opts << '--format=specdoc'
  t.spec_files = FileList['spec/**/*_spec.rb']
end

desc 'Run the specs'
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << '--color'
  t.spec_opts << '--format=html:doc/spec.html'
  t.spec_opts << '--format=specdoc'
  t.rcov = true
  t.rcov_opts << '--exclude "gems/*,spec/*,init.rb"'
  t.rcov_dir = 'doc/coverage'
  t.spec_files = FileList['spec/**/*_spec.rb']
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['lib/**/*.rb', '-', 'README.md']
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
