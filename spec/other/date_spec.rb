require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Date do

  describe '#to_reporting_period' do

    it 'should return a reporting period for the specified grouping and instance of DateTime' do
      date_time = DateTime.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:hour)

      date_time.to_reporting_period(grouping).should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(grouping, date_time)
    end

    it 'should return a reporting period for the specified grouping and instance of DateTime if the grouping is specified as a symbol' do
      date_time = DateTime.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:hour)

      date_time.to_reporting_period(:hour).should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(grouping, date_time)
    end

    it 'should raise an ArgumentError if the grouping is not specified as a symbol or an instance of Kvlr::ReportsAsSparkline::Grouping' do
      lambda { DateTime.now.to_reporting_period(1) }.should raise_error(ArgumentError)
    end

  end

end
