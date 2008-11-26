$:.reject! { |e| e.include? 'TextMate' }

ENV['RAILS_ENV'] = 'test'

require 'rubygems'
require 'spec'
require 'test/unit'
require 'active_support'
require 'initializer'

require File.join(File.dirname(__FILE__), 'boot') unless defined?(ActiveRecord)

class User < ActiveRecord::Base
  report_as_sparkline :registrations
  report_as_sparkline :cumulated_registrations, :cumulate => :registrations
end
