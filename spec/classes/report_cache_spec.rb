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

    describe 'with :live_data = true' do

      before do
        @options = @report.options.merge(:live_data => true)
      end

      it 'should yield to the given block' do
        lambda {
          Kvlr::ReportsAsSparkline::ReportCache.process(@report, @options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      it 'should yield the reporting period after the last one in the cache, and before the first one in the cache if data was read from cache' do
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - 3.send(@report.options[:grouping].identifier)
        )
        cached = Kvlr::ReportsAsSparkline::ReportCache.new
        cached.stub!(:reporting_period).and_return(reporting_period.date_time)
        Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])

        expected_dates = [[reporting_period.next.date_time, nil], [reporting_period.offset(-7).date_time, reporting_period.date_time]]
        yield_count = 0
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @options) do |begin_at, end_at|
          [begin_at, end_at].should == expected_dates[yield_count]
          yield_count += 1
          []
        end

        yield_count.should == 2
      end

    end

    describe 'with :live_data = false' do

      it 'should not yield to the block if data for the reporting period before the current one has been found in the cache' do
        cached = Kvlr::ReportsAsSparkline::ReportCache.new
        cached.stub!(:reporting_period).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping]).previous)
        Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])
        lambda {
          Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should_not raise_error(YieldMatchException)
      end

      it 'should yield to the block if no data for the reporting period before the current one has been found in the cache' do
        lambda {
          Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      it 'should yield the reporting period after the last one in the cache, and before the first one in the cache if data was read from cache' do
        reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - 3.send(@report.options[:grouping].identifier)
        )
        cached = Kvlr::ReportsAsSparkline::ReportCache.new
        cached.stub!(:reporting_period).and_return(reporting_period.date_time)
        Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])

        expected_dates = [[reporting_period.next.date_time, nil], [reporting_period.offset(-7).date_time, reporting_period.date_time]]
        yield_count = 0
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) do |begin_at, end_at|
          [begin_at, end_at].should == expected_dates[yield_count]
          yield_count += 1
          []
        end

        yield_count.should == 2
      end

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

    it 'should utilize the end_date in the conditions' do
      end_date = Time.now
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:find).once.with(
        :all,
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND reporting_period BETWEEN ? AND ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time,
          Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping], end_date).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      )

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options.merge(:end_date => end_date)) { [] }
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
      new_after_cache_data = []
      new_before_cache_data = []
      cached_data = []
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return(cached_data)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:prepare_result).once.with(new_before_cache_data, new_after_cache_data, cached_data, @report, @report.options, true)

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) { new_after_cache_data }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options) do |begin_at, end_at|
        begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        end_at.should == nil
        []
      end
    end

    describe 'with cache = false' do

      it 'should not read any data from cache' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:find)

        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options, false) {}
      end

      it 'should yield the first reporting period' do
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, @report.options, false) do |begin_at, end_at|
          begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
          end_at.should == nil
          []
        end
      end

    end

  end

  describe '.prepare_result' do

    before do
      @current_reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping])
      @new_after_cache_data = [[@current_reporting_period.previous.date_time, 1.0]]
      Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@current_reporting_period.previous)
      @cached = Kvlr::ReportsAsSparkline::ReportCache.new
      @cached.stub!(:save!)
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:build_cached_data).and_return(@cached)
    end

    it 'should convert the date strings from the newly read data to reporting periods' do
      Kvlr::ReportsAsSparkline::ReportingPeriod.should_receive(:from_db_string).once.with(@report.options[:grouping], @new_after_cache_data[0][0]).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping]))

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options)
    end

    it 'should create :limit instances of Kvlr::ReportsAsSparkline::ReportCache with value 0.0 if no new data has been read and nothing was cached' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(10).times.with(
        @report,
        @report.options[:grouping],
        anything(),
        0.0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], [], [], @report, @report.options)
    end

    it 'should create a new Kvlr::ReportsAsSparkline::ReportCache with the correct value if new data has been read' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(9).times.with(
        @report,
        @report.options[:grouping],
        anything(),
        0.0
      ).and_return(@cached)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).once.with(
        @report,
        @report.options[:grouping],
        @current_reporting_period.previous,
        1.0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options)
    end

    it 'should save the created Kvlr::ReportsAsSparkline::ReportCache' do
      @cached.should_receive(:save!).once

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options)
    end

    it 'should return an array of arrays of Dates and Floats' do
      result = Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options, true)

      result.should be_kind_of(Array)
      result[0].should be_kind_of(Array)
      result[0][0].should be_kind_of(Date)
      result[0][1].should be_kind_of(Float)
    end

    describe 'with :live_data = false' do

      before do
        @result = Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options, true)
      end

      it 'should return an array of length :limit' do
        @result.length.should == 10
      end

      it 'should not include an entry for the current reporting period' do
        @result.find { |row| row[0] == @current_reporting_period.date_time }.should be_nil
      end

    end

    describe 'with :live_data = true' do

      before do
        options = @report.options.merge(:live_data => true)
        @result = Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, options, true)
      end

      it 'should return an array of length (:limit + 1)' do
        @result.length.should == 11
      end

      it 'should include an entry for the current reporting period' do
        @result.find { |row| row[0] == @current_reporting_period.date_time }.should_not be_nil
      end

    end

    describe 'with cache = false' do

      it 'should not save the created Kvlr::ReportsAsSparkline::ReportCache' do
        @cached.should_not_receive(:save!)

        Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], @new_after_cache_data, [], @report, @report.options, false)
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
