require File.dirname(__FILE__) + '/spec_helper.rb'


describe "basic model without report_as_sparkline" do
  
  class MyUserModelWithoutReport < ActiveRecord::Base
  end
  
  it "should not have registrations_report class method" do
    MyUserModelWithoutReport.methods.include?(:registrations_report.to_s).should == false
  end
  
  it "should not have registrations_graph class method" do
    MyUserModelWithoutReport.methods.include?(:registrations_graph.to_s).should == false
  end
  
  
end

describe "basic model with report_as_sparkline" do
  
  class User < ActiveRecord::Base
    report_as_sparkline :registrations
    report_as_sparkline :total_users, { :cumulate => :registrations }
  end

  
  it "should have registrations_report class method" do
    User.methods.include?(:registrations_report.to_s).should == true
  end
  
end

describe "Model#name_report, should only accept one hash as a optional argument" do
  
  it "should raise ArgumentError when calling with two arguments" do
    lambda {
      User.registrations_report("one", "two")
    }.should raise_error(ArgumentError)
  end
  
  it "should raise ArgumentError when calling with one argument that is not a hash" do
    lambda {
      User.registrations_report("one")
    }.should raise_error(ArgumentError)
  end
  
  it "should raise ArgumentError when calling with one argument that is not a hash" do
    lambda {
      User.registrations_report(1)
    }.should raise_error(ArgumentError)
  end
  
  it "should not raise Error when calling with one argument that is a hash" do
    lambda {
      User.registrations_report(:hello => :world)
    }.should_not raise_error
  end
  
  it "should not raise Error when calling without arguments" do
    lambda {
      User.registrations_report
    }.should_not raise_error
  end
  
end


describe "Model#name_report should default to count operation on created at" do
  
  it "should call models count function" do
    User.registrations_report.class.should == Array
  end
  
end

describe "Model#name_report should default to count operation on created at" do
  
  it "should call models count function" do
    User.registrations_report.class.should == Array
  end
  
end

describe "Testing invalid operations and groups" do
  
  class UserInvalid < ActiveRecord::Base
  end
  
  it "Model with invalid operation should raise InvalidOperationExpception" # do    
  #     lambda {
  #       UserInvalid.class_eval %{
  #         report_as_sparkline :registrations, :operation => :countrrrr
  #       }
  #     }.should raise_error(Kvlr::ReportsAsSparkline::InvalidOperationExpception)
  #   end
  
end

