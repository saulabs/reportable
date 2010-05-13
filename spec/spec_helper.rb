ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require File.join(File.dirname(__FILE__), 'boot')

class User < ActiveRecord::Base; end

class YieldMatchException < Exception; end

begin
  require 'ruby-debug'
  Debugger.start
  Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
rescue LoadError
  # ruby-debug wasn't available so neither can the debugging be
end