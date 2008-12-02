require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Grouping do

  describe '#new' do

    it 'should raise an error if an unsupported grouping is specified' do
      lambda { Kvlr::ReportsAsSparkline::Grouping.new(:unsupported) }.should raise_error(ArgumentError)
    end

  end

  describe '.to_reporting_period' do

    it 'should return the date with day = 1 for grouping :month' do
      datetime = Time.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:month)

      grouping.to_reporting_period(datetime).should == Date.new(datetime.year, datetime.month, 1)
    end

    it 'should return the date of the first day of the week date_time is in (we use monday as first day of the week) for grouping :week' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:week)

      datetime = DateTime.new(2008, 11, 27) #this is a thursday
      grouping.to_reporting_period(datetime).should == DateTime.new(datetime.year, datetime.month, 24) # this is the monday before the 27th

      datetime = DateTime.new(2008, 11, 24) #this is a monday already, should not change
      grouping.to_reporting_period(datetime).should == DateTime.new(datetime.year, datetime.month, 24) # expect to get monday 24th again

      datetime = DateTime.new(2008, 11, 1) #this is a saturday
      grouping.to_reporting_period(datetime).should == DateTime.new(datetime.year, 10, 27) # expect to get the monday before the 1st, which is in october

      datetime = DateTime.new(2009, 1, 1) #this is a thursday
      grouping.to_reporting_period(datetime).should == DateTime.new(2008, 12, 29) # expect to get the monday before the 1st, which is in december 2008
    end

    it 'should return the date for grouping :day' do
      datetime = Time.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:day)

      grouping.to_reporting_period(datetime).should == datetime.to_date
    end

    it 'should return the date and time with minutes = seconds = 0 for grouping :hour' do
      datetime = Time.now
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:hour)

      grouping.to_reporting_period(datetime).should == DateTime.new(datetime.year, datetime.month, datetime.day, datetime.hour, 0, 0)
    end

  end

  describe '.previous_reporting_period' do

    it 'should return the first day of the month before the specified period for grouping :month' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:month)
      period = grouping.to_reporting_period(Time.now)

      grouping.previous_reporting_period(period).should == Date.new((period - 1.month).year, (period - 1.month).month, 1)
    end

    it 'should return the date 1 week before the specified period for grouping :week' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:week)
      period = grouping.to_reporting_period(Time.now)

      grouping.previous_reporting_period(period).should == Date.new((period - 1.week).year, (period - 1.week).month, (period - 1.week).day)
    end

    it 'should return the date 1 day before the specified period for grouping :day' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:day)
      period = grouping.to_reporting_period(Time.now)

      grouping.previous_reporting_period(period).should == Date.new((period - 1.day).year, (period - 1.day).month, (period - 1.day).day)
    end

    it 'should return the date and time 1 hour before the specified period for grouping :hour' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:day)
      period = grouping.to_reporting_period(Time.now)

      grouping.previous_reporting_period(period).should == Date.new((period - 1.hour).year, (period - 1.hour).month, (period - 1.hour).day, (period - 1.hour).hour)
    end

  end

end
