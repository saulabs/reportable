require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DateTime do

  describe '.to_reporting_period' do

    it 'should return a reporting period for the specified grouping and instance of DateTime' do
      date_time = DateTime.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:hour)

      date_time.to_reporting_period(grouping).should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(grouping, date_time)
    end

  end

end
