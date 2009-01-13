require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::CumulatedReport do

  before do
    @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :cumulated_registrations)
  end

  describe '#run' do

    it 'should cumulate the data' do
      @report.should_receive(:cumulate).once

      @report.run
    end

    it 'should return an array of the same length as the specified limit' do
      @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :cumulated_registrations, :limit => 10)

      @report.run.length.should == 10
    end

    for grouping in [:hour, :day, :week, :month] do

      describe "for grouping #{grouping.to_s}" do

        before(:all) do
          User.create!(:login => 'test 1', :created_at => Time.now - 1.send(grouping), :profile_visits => 1)
          User.create!(:login => 'test 2', :created_at => Time.now - 3.send(grouping), :profile_visits => 2)
          User.create!(:login => 'test 3', :created_at => Time.now - 3.send(grouping), :profile_visits => 3)
        end

        describe do

          before do
            @grouping = Kvlr::ReportsAsSparkline::Grouping.new(grouping)
            @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :cumulated_registrations, :grouping => grouping, :limit => 10)
            @result = @report.run
          end

          it "should return an array starting reporting period (Time.now - (limit - 1).#{grouping.to_s})" do
            @result.first[0].should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(@grouping, Time.now - 9.send(grouping)).date_time
          end

          it "should return data ending with with the current reporting period" do
            @result.last[0].should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(@grouping).date_time
          end

        end

        it 'should return correct data for aggregation :count' do
          @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :registrations, :aggregation => :count, :grouping => grouping, :limit => 10)
          result = @report.run

          result[9][1].should == 3.0
          result[8][1].should == 3.0
          result[7][1].should == 2.0
          result[6][1].should == 2.0
        end

        it 'should return correct data for aggregation :sum' do
          @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :registrations, :aggregation => :sum, :grouping => grouping, :value_column => :profile_visits, :limit => 10)
          result = @report.run()

          result[9][1].should == 6.0
          result[8][1].should == 6.0
          result[7][1].should == 5.0
          result[6][1].should == 5.0
        end

        it 'should return correct data for aggregation :count when custom conditions are specified' do
          @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :registrations, :aggregation => :count, :grouping => grouping, :limit => 10)
          result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2']])

          result[9][1].should == 2.0
          result[8][1].should == 2.0
          result[7][1].should == 1.0
          result[6][1].should == 1.0
        end

        it 'should return correct data for aggregation :sum when custom conditions are specified' do
          @report = Kvlr::ReportsAsSparkline::CumulatedReport.new(User, :registrations, :aggregation => :sum, :grouping => grouping, :value_column => :profile_visits, :limit => 10)
          result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2']])

          result[9][1].should == 3.0
          result[8][1].should == 3.0
          result[7][1].should == 2.0
          result[6][1].should == 2.0
        end

        after(:all) do
          User.destroy_all
        end

      end

      after(:each) do
        Kvlr::ReportsAsSparkline::ReportCache.destroy_all
      end

    end

  end

  describe '#cumulate' do

    it 'should correctly cumulate the given data' do
      first = (Time.now - 1.week).to_s
      second = Time.now.to_s
      data = [[first, 1], [second, 2]]

      @report.send(:cumulate, data).should == [[first, 1.0], [second, 3.0]]
    end

  end

end
