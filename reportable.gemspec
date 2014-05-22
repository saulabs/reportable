# -*- encoding: utf-8 -*-

pkg_files = [
  'README.md',
  'HISTORY.md',
  'Rakefile',
  'MIT-LICENSE'
]
pkg_files += Dir['generators/**/*']
pkg_files += Dir['lib/**/*.rb']
pkg_files += Dir['rails/**/*.rb']
pkg_files += Dir['spec/**/*.{rb,yml,opts}']

Gem::Specification.new do |s|

  s.name    = %q{reportable}
  s.version = '1.3.1'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to?(:required_rubygems_version=)
  s.authors                   = ['Marco Otte-Witte', 'Martin Kavalar']
  s.date                      = %q{2012-02-14}
  s.email                     = %q{reportable@saulabs.com}
  s.files                     = pkg_files
  s.homepage                  = %q{http://github.com/saulabs/reportable}
  s.require_path              = 'lib'
  s.rubygems_version          = %q{1.3.0}
  s.has_rdoc                  = false
  s.summary                   = %q{Easy report generation for Ruby on Rails}
  s.description               = %q{Reportable allows for easy report generation from ActiveRecord models by the addition of the reportable method.}


  s.add_dependency(%q<activerecord>, ['>= 3.0'])
  s.add_dependency(%q<activesupport>, ['>= 3.0.0'])

end
