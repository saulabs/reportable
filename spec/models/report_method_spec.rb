require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline do

  describe 'generated <xyz>_report method' do

    it 'should raise an error when called with anything else than a hash' do
      lambda { User.registrations_report(1) }.should         raise_error(ArgumentError)
      lambda { User.registrations_report('invalid') }.should raise_error(ArgumentError)
      lambda { User.registrations_report([1, 2]) }.should    raise_error(ArgumentError)
    end

    it 'should raise an error when called with multiple arguments' do
      lambda { User.registrations_report({ 1 => 2 }, { 3 => 4 }) }.should raise_error(ArgumentError)
    end

    it 'should not raise an error when called with a hash' do
      lambda { User.registrations_report({ :limit => 1 }) }.should_not raise_error(ArgumentError)
    end

    it 'should not raise an error when called without a parameter' do
      lambda { User.registrations_report }.should_not raise_error(ArgumentError)
    end

  end

  describe 'for inherited models' do

    before(:all) do
      User.create!(:login => 'test 1', :created_at => Time.now - 1.week,  :profile_visits => 1)
      User.create!(:login => 'test 2', :created_at => Time.now - 2.weeks, :profile_visits => 2)
      SpecialUser.create!(:login => 'test 3', :created_at => Time.now - 2.weeks, :profile_visits => 3)
    end

    it 'should include all data when invoked on the base model class' do
      result = User.registrations_report.to_a

      result.length.should == 20
      result[7][1].should  == 1
      result[14][1].should  == 2
    end

    it 'should include all data when invoked on the base model class' do
      result = SpecialUser.registrations_report.to_a

      result.length.should == 20
      result[14][1].should  == 1
    end

    after(:all) do
      User.destroy_all
      SpecialUser.destroy_all
    end

  end

  after do
    Kvlr::ReportsAsSparkline::ReportCache.destroy_all
  end

end

class User < ActiveRecord::Base
  report_as_sparkline :registrations, :cumulate => true, :limit => 20
end

class SpecialUser < User; end
