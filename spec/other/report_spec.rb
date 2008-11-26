require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Report do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
  end

  describe '#run' do

    it 'should invoke the default aggregation method on the model' do
      User.should_receive(:count).once

      @report.run
    end

    it 'should invoke the custom aggregation method on the model if one is specified' do
      @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :sum)
      User.should_receive(:sum).once

      @report.run
    end

    describe do

      before do
        User.create!(:login => 'test 1', :created_at => Time.now - 1.week,  :profile_visits => 1)
        User.create!(:login => 'test 2', :created_at => Time.now - 2.weeks, :profile_visits => 2)
        User.create!(:login => 'test 3', :created_at => Time.now - 2.weeks, :profile_visits => 3)
      end

      it 'should return correct data for :aggregation => :count' do
        result = User.registrations_report.to_a

        result[0][1].should == 1
        result[1][1].should == 2
      end

      it 'should return correct data for :aggregation => :sum' do
        result = User.registrations_report(:aggregation => :sum, :value_column_name => :profile_visits).to_a

        result[0][1].should == 1
        result[1][1].should == 5
      end

      it 'should return correct data with custom conditions' do
        result = User.registrations_report(:conditions => ['login IN (?)', ['test 1', 'test 2']]).to_a

        result[0][1].should == 1
        result[1][1].should == 1
      end

      after do
        User.destroy_all
      end

    end

  end

end
