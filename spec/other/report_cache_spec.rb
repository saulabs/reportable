require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::ReportCache do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
  end

  describe '#process' do

    before do
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([])
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:prepare_result).and_return([])
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10)
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:transaction)

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) {}
    end

    it 'should yield to the given block' do
      lambda {
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) { raise YieldMatchException.new }
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
        :limit => 10,
        :order => 'reporting_period ASC'
      )

      puts Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) { [] }
    end

    it 'should prepare the results before it returns them' do
      new_data = []
      cached_data = []
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return(cached_data)
      last_reporting_period_to_read = Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.grouping, 10)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:prepare_result).once.with(new_data, cached_data, last_reporting_period_to_read, @report, false)

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) { new_data }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) do |begin_at|
        begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.grouping, 10).date_time
        []
      end
    end

    it 'should yield the last reporting period in the cache if the cache is not empty' do
      reporting_period = Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.grouping)
      cached = Kvlr::ReportsAsSparkline::ReportCache.new({
        :model_name       => @report.klass,
        :report_name      => @report.name,
        :grouping         => @report.grouping.identifier.to_s,
        :aggregation      => @report.aggregation.to_s,
        :value            => 1,
        :reporting_period => reporting_period.date_time
      })
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:find).and_return([cached])

      Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10) do |begin_at|
        begin_at.should == reporting_period.date_time
        []
      end
    end

    describe 'with no_cache = true' do

      it 'should not read any data from cache' do
        Kvlr::ReportsAsSparkline::ReportCache.should_not_receive(:find)

        Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10, true) {}
      end

      it 'should yield the first reporting period' do
        Kvlr::ReportsAsSparkline::ReportCache.process(@report, 10, true) do |begin_at|
          begin_at.should == Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.grouping, 10).date_time
          []
        end
      end

    end

  end

  describe '#prepare_result' do

    before do
      @last_reporting_period_to_read = Kvlr::ReportsAsSparkline::ReportingPeriod.first(@report.grouping, 10)
      @new_data = [['2008/12', 1.0]]
      Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.grouping))
      @cached = Kvlr::ReportsAsSparkline::ReportCache.new
      @cached.stub!(:save!)
      @cached.stub!(:reporting_period).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.grouping).date_time)
      Kvlr::ReportsAsSparkline::ReportCache.stub!(:new).and_return(@cached)
    end

    it 'should convert the date strings from the newly read data to reporting periods' do
      Kvlr::ReportsAsSparkline::ReportingPeriod.should_receive(:from_db_string).once.with(@report.grouping, @new_data[0][0]).and_return(Kvlr::ReportsAsSparkline::ReportingPeriod.new(@report.grouping))

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report)
    end

    it 'should create a new Kvlr::ReportsAsSparkline::ReportCache with the correct data and value 0 if no new data has been read' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:new).once.with(
        :model_name       => @report.klass.to_s,
        :report_name      => @report.name.to_s,
        :grouping         => @report.grouping.identifier.to_s,
        :aggregation      => @report.aggregation.to_s,
        :reporting_period => anything(),
        :value            => 0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, [], [], @last_reporting_period_to_read, @report)
    end

    it 'should create a new Kvlr::ReportsAsSparkline::ReportCache with the correct data and value if new data has been read' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:new).once.with(
        :model_name       => @report.klass.to_s,
        :report_name      => @report.name.to_s,
        :grouping         => @report.grouping.identifier.to_s,
        :aggregation      => @report.aggregation.to_s,
        :reporting_period => anything(),
        :value            => 1.0
      ).and_return(@cached)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report)
    end

    it 'should save the created Kvlr::ReportsAsSparkline::ReportCache if no_cache is not specified' do
      @cached.should_receive(:save!).once

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report)
    end

    it 'should return an array of arrays of Dates and Floats' do
      result = Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, true)

      result.should be_kind_of(Array)
      result[0].should be_kind_of(Array)
      result[0][0].should be_kind_of(Date)
      result[0][1].should be_kind_of(Float)
    end

    it 'should update the last cached record if new data has been read for the last reporting period to read' do
      Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@last_reporting_period_to_read)
      @cached.should_receive(:update_attributes!).once.with(:value => 1.0)

      Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [@cached], @last_reporting_period_to_read, @report)
    end

    describe 'with no_cache = true' do

      it 'should not save the created Kvlr::ReportsAsSparkline::ReportCache' do
        @cached.should_not_receive(:save!)

        Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [], @last_reporting_period_to_read, @report, true)
      end

      it 'should not update the last cached record if new data has been read for the last reporting period to read' do
        Kvlr::ReportsAsSparkline::ReportingPeriod.stub!(:from_db_string).and_return(@last_reporting_period_to_read)
        @cached.should_not_receive(:update_attributes!)

        Kvlr::ReportsAsSparkline::ReportCache.send(:prepare_result, @new_data, [@cached], @last_reporting_period_to_read, @report, true)
      end

    end

  end

end
