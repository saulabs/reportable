require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportingPeriod do

  describe '#date_time' do

    it 'should return the date and time with minutes = seconds = 0 for grouping :hour' do
      date_time = DateTime.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:hour), date_time)

      reporting_period.date_time.should == DateTime.new(date_time.year, date_time.month, date_time.day, date_time.hour, 0, 0)
    end

    it 'should return the date part only for grouping :day' do
      date_time = DateTime.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:day), date_time)

      reporting_period.date_time.should == date_time.to_date
    end

    describe 'for grouping :week' do

      it 'should return the date of the monday of the week date_time is in for any day in that week' do
        date_time = DateTime.new(2008, 11, 27)
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), date_time)

        reporting_period.date_time.should == Date.new(date_time.year, date_time.month, 24)
      end

      it 'should return the date of the monday of the week date_time is in when the specified date is a monday already' do
        date_time = DateTime.new(2008, 11, 24) #this is a monday already, should not change
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), date_time)

        reporting_period.date_time.should == Date.new(date_time.year, date_time.month, 24) # expect to get monday 24th again
      end

      it 'should return the date of the monday of the week date_time is in when the monday is in a different month than the specified date' do
        date_time = DateTime.new(2008, 11, 1) #this is a saturday
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), date_time)

        reporting_period.date_time.should == Date.new(2008, 10, 27) # expect to get the monday before the 1st, which is in october
      end

      it 'should return the date of the monday of the week date_time is in when the monday is in a different year than the specified date' do
        date_time = DateTime.new(2009, 1, 1) #this is a thursday
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), date_time)

        reporting_period.date_time.should == Date.new(2008, 12, 29) # expect to get the monday before the 1st, which is in december 2008
      end

    end

    it 'should return the date with day = 1 for grouping :month' do
      date_time = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), date_time)

      reporting_period.date_time.should == Date.new(date_time.year, date_time.month, 1)
    end

  end

  describe '.from_db_string' do

    it 'should return a reporting period with the correct date and time and with minutes = seconds = 0 for grouping :hour' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:hour)
      grouping.stub!(:date_parts_from_db_string).and_return([2008, 1, 1, 12])

      Kvlr::ReportsAsSparkline::ReportingPeriod.from_db_string(grouping, '').date_time.should == DateTime.new(2008, 1, 1, 12, 0, 0)
    end

    it 'should return a reporting period with the date part only for grouping :day' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:day)
      grouping.stub!(:date_parts_from_db_string).and_return([2008, 1, 1])

      Kvlr::ReportsAsSparkline::ReportingPeriod.from_db_string(grouping, '').date_time.should == Date.new(2008, 1, 1)
    end

    it 'should return a reporting period with the date part of the monday of the week the date is in for grouping :week' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:week)
      grouping.stub!(:date_parts_from_db_string).and_return([2008, 1])

      Kvlr::ReportsAsSparkline::ReportingPeriod.from_db_string(grouping, '').date_time.should == Date.new(2007, 12, 31)
    end

    it 'should return a reporting period with the correct date and with day = 1 for grouping :month' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:month)
      grouping.stub!(:date_parts_from_db_string).and_return([2008, 1])

      Kvlr::ReportsAsSparkline::ReportingPeriod.from_db_string(grouping, '').date_time.should == Date.new(2008, 1, 1)
    end

  end

  describe '#next' do

    it 'should return a reporting period with date and time one hour after the current period for grouping :hour' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:hour), now)
      expected = now + 1.hour

      reporting_period.next.date_time.should == DateTime.new(expected.year, expected.month, expected.day, expected.hour)
    end

    it 'should return a reporting period with date one day after the current period for grouping :day' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:day), now)
      expected = now + 1.day

      reporting_period.next.date_time.should == Date.new(expected.year, expected.month, expected.day)
    end

    it 'should return a reporting period with date one week after the current period for grouping :week' do
      now = DateTime.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), now)
      expected = reporting_period.date_time + 1.week

      reporting_period.next.date_time.should == Date.new(expected.year, expected.month, expected.day)
    end

    it 'should return a reporting period with date of the first day in the month one month after the current period' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), now)
      expected = reporting_period.date_time + 1.month

      reporting_period.next.date_time.should == Date.new(expected.year, expected.month, 1)
    end

  end

  describe '#previous' do

    it 'should return a reporting period with date and time one hour before the current period for grouping :hour' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:hour), now)
      expected = now - 1.hour

      reporting_period.previous.date_time.should == DateTime.new(expected.year, expected.month, expected.day, expected.hour)
    end

    it 'should return a reporting period with date one day before the current period for grouping :day' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:day), now)
      expected = now - 1.day

      reporting_period.previous.date_time.should == Date.new(expected.year, expected.month, expected.day)
    end

    it 'should return a reporting period with date one week before the current period for grouping :week' do
      now = DateTime.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:week), now)
      expected = reporting_period.date_time - 1.week

      reporting_period.previous.date_time.should == Date.new(expected.year, expected.month, expected.day)
    end

    it 'should return a reporting period with date of the first day in the month one month before the current period' do
      now = Time.now
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), now)
      expected = reporting_period.date_time - 1.month

      reporting_period.previous.date_time.should == Date.new(expected.year, expected.month, 1)
    end

  end

  describe '#==' do

    it 'should return true for 2 reporting periods with the same date_time and grouping' do
      now = DateTime.now
      reporting_period1 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), now)
      reporting_period2 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), now)

      (reporting_period1 == reporting_period2).should == true
    end

    it 'should return false for 2 reporting periods with the same date_time but different groupings' do
      now = Time.now
      reporting_period1 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), now)
      reporting_period2 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:day), now)

      (reporting_period1 == reporting_period2).should == false
    end

    it 'should return true for 2 reporting periods with the same grouping but different date_times if the date times evaluate to the same reporting period identifier' do
      reporting_period1 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), Time.now)
      reporting_period2 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), Time.now + 1.day)

      (reporting_period1 == reporting_period2).should == true
    end

    it 'should return false for 2 reporting periods with the same grouping but different date_times if the date times evaluate to different reporting period identifiers' do
      reporting_period1 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), Time.now)
      reporting_period2 = Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:month), Time.now + 2.months)

      (reporting_period1 == reporting_period2).should == false
    end

  end

  describe '.first' do

    before do
      @now = DateTime.now
      DateTime.stub!(:now).and_return(@now)
    end

    it 'should return a reporting period with the date part of (DateTime.now - limit.hours with minutes = seconds = 0 for grouping :hour' do
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.first(Kvlr::ReportsAsSparkline::Grouping.new(:hour), 3)
      expected = @now - 3.hours

      reporting_period.date_time.should == DateTime.new(expected.year, expected.month, expected.day, expected.hour, 0, 0)
    end

    it 'should return a reporting period with the date part of (DateTime.now - limit.days) for grouping :day' do
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.first(Kvlr::ReportsAsSparkline::Grouping.new(:day), 3)
      expected = @now - 3.days

      reporting_period.date_time.should == Date.new(expected.year, expected.month, expected.day)
    end

    it 'should return a reporting period with the date of the first day of the month at (DateTime.now - limit.months) for grouping :month' do
      DateTime.stub!(:now).and_return(DateTime.new(2008, 12, 31, 0, 0, 0))
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.first(Kvlr::ReportsAsSparkline::Grouping.new(:month), 3)

      reporting_period.date_time.should == DateTime.new(2008, 9, 1)
    end

    it 'should return a reporting period with the date of the monday of the week at (DateTime.now - limit.weeks) for grouping :week' do
      DateTime.stub!(:now).and_return(DateTime.new(2008, 12, 31, 0, 0, 0)) #wednesday
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.first(Kvlr::ReportsAsSparkline::Grouping.new(:week), 3)

      reporting_period.date_time.should == DateTime.new(2008, 12, 8) #the monday 3 weeks earlier
    end

  end

end
