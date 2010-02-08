require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Saulabs::ReportsAsSparkline::ReportCache do

  before do
    @report = Saulabs::ReportsAsSparkline::Report.new(User, :registrations, :limit => 10)
  end

  describe '.clear_for' do

    it 'should delete all entries in the cache for the klass and report name' do
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:delete_all).once.with(:conditions => {
        :model_name  => User.name,
        :report_name => 'registrations'
      })

      Saulabs::ReportsAsSparkline::ReportCache.clear_for(User, :registrations)
    end

  end

  describe '.process' do

    before do
      Saulabs::ReportsAsSparkline::ReportCache.stub!(:find).and_return([])
      Saulabs::ReportsAsSparkline::ReportCache.stub!(:prepare_result).and_return([])
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options)
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:transaction)

      Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options) {}
    end

    describe 'with :live_data = true' do

      before do
        @options = @report.options.merge(:live_data => true)
      end

      it 'should yield to the given block' do
        lambda {
          Saulabs::ReportsAsSparkline::ReportCache.process(@report, @options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      it 'should yield the first reporting period if not all required data could be retrieved from the cache' do
        reporting_period = Saulabs::ReportsAsSparkline::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - 3.send(@report.options[:grouping].identifier)
        )
        Saulabs::ReportsAsSparkline::ReportCache.stub!(:all).and_return([Saulabs::ReportsAsSparkline::ReportCache.new])

        Saulabs::ReportsAsSparkline::ReportCache.process(@report, @options) do |begin_at, end_at|
          begin_at.should == Saulabs::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], @report.options[:limit]).date_time
          end_at.should   == nil
          []
        end
      end

      it 'should yield the reporting period after the last one in the cache if all required data could be retrieved from the cache' do
        reporting_period = Saulabs::ReportsAsSparkline::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - @report.options[:limit].send(@report.options[:grouping].identifier)
        )
        cached = Saulabs::ReportsAsSparkline::ReportCache.new
        cached.stub!(:reporting_period).and_return(reporting_period.date_time)
        Saulabs::ReportsAsSparkline::ReportCache.stub!(:all).and_return(Array.new(@report.options[:limit] - 1, Saulabs::ReportsAsSparkline::ReportCache.new), cached)

        Saulabs::ReportsAsSparkline::ReportCache.process(@report, @options) do |begin_at, end_at|
          begin_at.should == reporting_period.date_time
          end_at.should   == nil
          []
        end
      end

    end

    describe 'with :live_data = false' do

      it 'should not yield if all required data could be retrieved from the cache' do
        Saulabs::ReportsAsSparkline::ReportCache.stub!(:all).and_return(Array.new(@report.options[:limit], Saulabs::ReportsAsSparkline::ReportCache.new))

        lambda {
          Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should_not raise_error(YieldMatchException)
      end

      it 'should yield to the block if no data could be retrieved from the cache' do
        Saulabs::ReportsAsSparkline::ReportCache.stub!(:all).and_return([])

        lambda {
          Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      describe 'with :end_date = <some date>' do

        before do
          @options = @report.options.merge(:end_date => Time.now)
        end

        it 'should yield the last date and time of the reporting period for the specified end date' do
          reporting_period = Saulabs::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping], @options[:end_date])

          Saulabs::ReportsAsSparkline::ReportCache.process(@report, @options) do |begin_at, end_at|
            end_at.should   == reporting_period.last_date_time
            []
          end
        end

      end

    end

    it 'should read existing data from the cache' do
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:all).once.with(
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND `condition` = ? AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          @report.options[:conditions].to_s,
          Saulabs::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options) { [] }
    end

    it 'should utilize the end_date in the conditions' do
      end_date = Time.now
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:all).once.with(
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND `condition` = ? AND reporting_period BETWEEN ? AND ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          @report.options[:conditions].to_s,
          Saulabs::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 9).date_time,
          Saulabs::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping], end_date).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options.merge(:end_date => end_date)) { [] }
    end

    it "should read existing data from the cache for the correct grouping if one other than the report's default grouping is specified" do
      grouping = Saulabs::ReportsAsSparkline::Grouping.new(:month)
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:find).once.with(
        :all,
        :conditions => [
          'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND `condition` = ? AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          grouping.identifier.to_s,
          @report.aggregation.to_s,
          @report.options[:conditions].to_s,
          Saulabs::ReportsAsSparkline::ReportingPeriod.first(grouping, 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::ReportsAsSparkline::ReportCache.process(@report, { :limit => 10, :grouping => grouping }) { [] }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Saulabs::ReportsAsSparkline::ReportCache.process(@report, @report.options) do |begin_at, end_at|
        begin_at.should == Saulabs::ReportsAsSparkline::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        end_at.should == nil
        []
      end
    end
  end

  describe '.prepare_result' do

    before do
      @current_reporting_period = Saulabs::ReportsAsSparkline::ReportingPeriod.new(@report.options[:grouping])
      @new_data = [[@current_reporting_period.previous.date_time, 1.0]]
      Saulabs::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@current_reporting_period.previous)
      @cached = Saulabs::ReportsAsSparkline::ReportCache.new
      @cached.stub!(:save!)
      Saulabs::ReportsAsSparkline::ReportCache.stub!(:build_cached_data).and_return(@cached)
    end

    it 'should create :limit instances of Saulabs::ReportsAsSparkline::ReportCache with value 0.0 if no new data has been read and nothing was cached' do
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(10).times.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        anything(),
        0.0
      ).and_return(@cached)

      Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, [], [], @report, @report.options)
    end

    it 'should create a new Saulabs::ReportsAsSparkline::ReportCache with the correct value if new data has been read' do
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).exactly(9).times.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        anything(),
        0.0
      ).and_return(@cached)
      Saulabs::ReportsAsSparkline::ReportCache.should_receive(:build_cached_data).once.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        @current_reporting_period.previous,
        1.0
      ).and_return(@cached)

      Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)
    end

    it 'should save the created Saulabs::ReportsAsSparkline::ReportCache' do
      @cached.should_receive(:save!).once

      Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)
    end

    it 'should return an array of arrays of Dates and Floats' do
      result = Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)

      result.should be_kind_of(Array)
      result[0].should be_kind_of(Array)
      result[0][0].should be_kind_of(Date)
      result[0][1].should be_kind_of(Float)
    end

    describe 'with :live_data = false' do

      before do
        @result = Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)
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
        @result = Saulabs::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @report, options)
      end

      it 'should return an array of length (:limit + 1)' do
        @result.length.should == 11
      end

      it 'should include an entry for the current reporting period' do
        @result.find { |row| row[0] == @current_reporting_period.date_time }.should_not be_nil
      end

    end
  end

  describe '.find_value' do

    before do
      @data = [[Saulabs::ReportsAsSparkline::ReportingPeriod.new(Saulabs::ReportsAsSparkline::Grouping.new(:day)), 3.0]]
    end

    it 'should return the correct value when new data has been read for the reporting period' do
      Saulabs::ReportsAsSparkline::ReportCache.send(:find_value, @data, @data[0][0]).should == 3.0
    end

    it 'should return 0.0 when no data has been read for the reporting period' do
      Saulabs::ReportsAsSparkline::ReportCache.send(:find_value, @data, @data[0][0].next).should == 0.0
    end

  end

end
