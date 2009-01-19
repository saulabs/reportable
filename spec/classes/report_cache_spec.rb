require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportCache do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :limit => 10)
  end

  describe '.process' do

    before do
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([])
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:prepare_result).and_return([])
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options)
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:transaction)

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) {}
    end

    it 'should yield to the given block' do
      lambda {
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
      }.should raise_error(YieldMatchException)
    end

    it 'should read existing data from the cache' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:find).once.with(
        :all,
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      )

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { [] }
    end

    it "should read existing data from the cache for the correct grouping if one other than the report's default grouping is specified" do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:month)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:find).once.with(
        :all,
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          grouping.identifier.to_s,
          @report.aggregation.to_s,
          Kvlr::ReportsAsSparkline::ReportingPeriod.first(grouping, 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      )

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, { :limit => 10, :grouping => grouping }) { [] }
    end

    it 'should prepare the results before it returns them' do
      new_data = []
      cached_data = []
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return(cached_data)
      last_reporting_period_to_read = Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:prepare_result).once.with(new_data, cached_data, last_reporting_period_to_read, @report, @report.options, true)

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { new_data }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) do |begin_at|
        begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        []
      end
    end

    it 'should yield the reporting period after the last one in the cache if the cache is not empty' do
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping])
      cached = Kvlr::ReportsAsSparkline::ReportCache.new({
        :model_name       => @report.klass,
        :report_name      => @report.name,
        :grouping         => @report.options[:grouping].identifier.to_s,
        :aggregation      => @report.aggregation.to_s,
        :value            => 1,
        :reporting_period => reporting_period.date_time
      })
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) do |begin_at|
        begin_at.should == reporting_period.next.date_time
        []
      end
    end

    describe 'with cache = false' do

      it 'should not read any data from cache' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:find)

        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options, false) {}
      end

      it 'should yield the first reporting period' do
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options, false) do |begin_at|
          begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
          []
        end
      end

    end

  end

  describe '.prepare_result' do

    before do
      @last_reporting_period_to_read = Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10)
      @new_data = [[@last_reporting_period_to_read.date_time, 1.0]]
      Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@last_reporting_period_to_read)
      @cached = Kvlr::ReportsAsSparkline::ReportCache.new
      @cached.stub!(:save!)
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:build_cached_data).and_return(@cached)
    end

    it 'should convert the date strings from the newly read data to reporting periods' do
      Kvlr::ReportsAsSparkline::ReportingPeriod.should_receive(:from_db_string).once.with(@report.options[:grouping], @new_data[0][0]).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping]))

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, @report.options)
    end

    it 'should create (:limit - 1) instances of Kvlr::ReportsAsSparkline::ReportCache with value 0.0 if no new data has been read and nothing was cached' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(9).times.with(
        @report,
        @report.options[:grouping],
        anything(),
        0.0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], [], @last_reporting_period_to_read, @report, @report.options)
    end

    it 'should create a new Kvlr::ReportsAsSparkline::ReportCache with the correct value if new data has been read' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(8).times.with(
        @report,
        @report.options[:grouping],
        anything(),
        0.0
      ).and_return(@cached)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).once.with(
        @report,
        @report.options[:grouping],
        @last_reporting_period_to_read,
        1.0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, @report.options)
    end

    it 'should save the created Kvlr::ReportsAsSparkline::ReportCache if no_cache is not specified' do
      @cached.should_receive(:save!).once

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, @report.options)
    end

    it 'should return an array of arrays of Dates and Floats' do
      result = Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, @report.options, true)

      result.should be_kind_of(Array)
      result[0].should be_kind_of(Array)
      result[0][0].should be_kind_of(Date)
      result[0][1].should be_kind_of(Float)
    end

    describe 'with cache = false' do

      it 'should not save the created Kvlr::ReportsAsSparkline::ReportCache' do
        @cached.should_not_receive(:save!)

        Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, @report.options, false)
      end

      it 'should not update the last cached record if new data has been read for the last reporting period to read' do
        Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@last_reporting_period_to_read)
        @cached.should_not_receive(:update_attributes!)

        Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [@cached], @last_reporting_period_to_read, @report, @report.options, false)
      end

    end

  end

  describe '.find_value' do

    before do
      @data = [[Kvlr::ReportsAsSparkline::ReportingPeriod.new(Kvlr::ReportsAsSparkline::Grouping.new(:day)), 3.0]]
    end

    it 'should return the correct value when new data has been read for the reporting period' do
      Kvlr::ReportsAsSparkline::ReportCache.send(:find_value, @data, @data[0][0]).should == 3.0
    end

    it 'should return 0.0 when no data has been read for the reporting period' do
      Kvlr::ReportsAsSparkline::ReportCache.send(:find_value, @data, @data[0][0].next).should == 0.0
    end

  end

end
