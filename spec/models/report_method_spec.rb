require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline do

  describe 'created _report method' do

    it 'should raise an error when called with anything else than a hash' do
      lambda { User.registrations_report(1) }.should         raise_error(ArgumentError)
      lambda { User.registrations_report('invalid') }.should raise_error(ArgumentError)
      lambda { User.registrations_report([1, 2]) }.should    raise_error(ArgumentError)
    end

    it 'should raise an error when called with multiple arguments' do
      lambda { User.registrations_report({ 1 => 2 }, { 3 => 4 }) }.should raise_error(ArgumentError)
    end

    it 'should not raise an error when called with a hash' do
      lambda { User.registrations_report({ :test => :hash }) }.should_not raise_error(ArgumentError)
    end

    it 'should not raise an error when called without a parameter' do
      lambda { User.registrations_report }.should_not raise_error(ArgumentError)
    end

    it 'should return an ordered hash' do
      User.registrations_report.class.should == ActiveSupport::OrderedHash
    end

  end

end
