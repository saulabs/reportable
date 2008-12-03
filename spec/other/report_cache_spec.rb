require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportCache do

  describe '#cached_transaction' do

    before do
      @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, :count, 100, 'created_at')
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:transaction)

      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, :count, 100, 'created_at') {}
    end

  end

  describe '#get_last_period_to_read' do

    before do
      @grouping = Kvlr::ReportsAsSparkline::Grouping.new(:day)
    end

    it 'should correctly return the last reporting period that is in the cache' do
      cached_data = [
        Kvlr::ReportsAsSparkline::ReportCache.new(:reporting_period => (Time.now - 3.days).to_date.to_formatted_s(:db)),
        Kvlr::ReportsAsSparkline::ReportCache.new(:reporting_period => (Time.now - 2.days).to_date.to_formatted_s(:db))
      ]

      Kvlr::ReportsAsSparkline::ReportCache.send(
        :get_last_reporting_period,
        cached_data,
        @grouping,
        @grouping.first_reporting_period(3)
      ).should == @grouping.to_reporting_period(Time.now - 2.days)
    end

    it 'should return the first reporting period for (Time.now - limit * day/week/month/year) if the cache is empty' do
      Kvlr::ReportsAsSparkline::ReportCache.send(
        :get_last_reporting_period,
        [],
        @grouping,
        @grouping.first_reporting_period(3)
      ).should == @grouping.to_reporting_period(Time.now - 3.days)
    end

  end

end
