require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run specs.'
task :default => :spec

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

desc 'Generate documentation for the ReportsAsSparkline plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'ReportsAsSparkline'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
