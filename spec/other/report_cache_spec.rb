require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportCache do

  describe '#cached_transaction' do

    before do
      @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([])
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:update_cache).and_return([])
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100)
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:transaction)

      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) {}
    end

    it 'should yield to the given block' do
      lambda {
        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) { raise YieldMatchException.new }
      }.should raise_error(YieldMatchException)
    end

    it 'should read existing data for the report from cache' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:find).once.with(
        :all,
        :conditions => {
          :model_name => @report.klass.to_s,
          :report_name => @report.name.to_s,
          :grouping => @report.grouping.identifier.to_s,
          :aggregation => @report.aggregation.to_s
        },
        :limit => 100,
        :order => "reporting_period DESC"
      )

      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) { [] }
    end

    it 'should update the cache' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:update_cache)

      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) { [] }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) do |begin_at|
        begin_at.should == @report.grouping.first_reporting_period(100)
        []
      end
    end

    it 'should yield the last reporting period in the cache if the cache is not empty' do
      cached = Kvlr::ReportsAsSparkline::ReportCache.new({
        :model_name       => @report.klass,
        :report_name      => @report.name,
        :grouping         => @report.grouping.identifier.to_s,
        :aggregation      => @report.aggregation.to_s,
        :value            => 1,
        :reporting_period => DateTime.now
      })
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])

      Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100) do |begin_at|
        begin_at.should == @report.grouping.to_reporting_period(cached.reporting_period)
        []
      end
    end

    describe 'with no_cache = true' do

      it 'should not start a transaction' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:transaction)

        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100, true) {}
      end

      it 'should not read any data from cache' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:find)

        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100, true) {}
      end

      it 'should not update the cache' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:update_cache)

        Kvlr::ReportsAsSparkline::ReportCache.cached_transaction(@report, 100, true) {}
      end

    end

  end

end
