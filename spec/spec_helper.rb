$:.reject! { |e| e.include? 'TextMate' }

ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'spec'
require 'test/unit'
require 'active_support'
require 'initializer'

require File.join(File.dirname(__FILE__), 'boot') unless defined?(ActiveRecord)

class User < ActiveRecord::Base; end

class YieldMatchException < Exception; end

begin
  require 'ruby-debug'
  Debugger.start
  Debugger.settings[:autoeval] = true if Debugger.respond_to?(:settings)
rescue LoadError
  # ruby-debug wasn't available so neither can the debugging be
end