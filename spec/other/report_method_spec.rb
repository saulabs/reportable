require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Simplabs::ReportsAsSparkline do

  describe 'for inherited models' do

    before(:all) do
      User.create!(:login => 'test 1', :created_at => Time.now - 1.days,  :profile_visits => 1)
      User.create!(:login => 'test 2', :created_at => Time.now - 2.days, :profile_visits => 2)
      SpecialUser.create!(:login => 'test 3', :created_at => Time.now - 2.days, :profile_visits => 3)
    end

    it 'should include all data when invoked on the base model class' do
      result = User.registrations_report.to_a

      result[9][1].should == 1.0
      result[8][1].should == 2.0
    end

    it 'should include only data for instances of the inherited model when invoked on the inherited model class' do
      result = SpecialUser.registrations_report.to_a

      result[9][1].should == 0.0
      result[8][1].should == 1.0
    end

    after(:all) do
      User.destroy_all
      SpecialUser.destroy_all
    end

  end

  after do
    Simplabs::ReportsAsSparkline::ReportCache.destroy_all
  end

end

class User < ActiveRecord::Base
  reports_as_sparkline :registrations, :limit => 10
end

class SpecialUser < User; end
