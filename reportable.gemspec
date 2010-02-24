# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|

  s.name    = %q{reportable}
  s.version = '1.0.0'

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to?(:required_rubygems_version=)
  s.authors                   = ['Marco Otte-Witte', 'Martin Kavalar']
  s.date                      = %q{2010-02-26}
  s.email                     = %q{reportable@saulabs.com}
  s.files                     = []
  s.homepage                  = %q{http://github.com/saulabs/reportable}
  s.require_paths             = ['lib']
  s.rubygems_version          = %q{1.3.0}
  s.summary                   = %q{Easy report generation for Ruby on Rails}
  s.description               = %q{Reportable allows for easy report generation from ActiveRecord and DataMapper models by the addition of the reportable method.}

  if s.respond_to?(:specification_version) then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end

end
