require File.join(File.dirname(File.dirname(File.expand_path(__FILE__))),'spec_helper')

describe Saulabs::Reportable::ReportCache do

  before do
    @report = Saulabs::Reportable::Report.new(User, :registrations, :limit => 10)
  end

  describe 'validations' do

    before do
      @report_cache = Saulabs::Reportable::ReportCache.new(
        :model_name       => User.name,
        :report_name      => 'registrations',
        :grouping         => 'date',
        :aggregation      => 'count',
        :value            => 1.0,
        :reporting_period => '2070/03/23'
      )
    end

    it 'should succeed when all required attributes are set' do
      @report_cache.should be_valid
    end

    it 'should not succeed when no model_name is set' do
      @report_cache.model_name = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when a blank model_name is set' do
      @report_cache.model_name = ''

      @report_cache.should_not be_valid
    end

    it 'should not succeed when no report_name is set' do
      @report_cache.report_name = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when a blank report_name is set' do
      @report_cache.report_name = ''

      @report_cache.should_not be_valid
    end

    it 'should not succeed when no grouping is set' do
      @report_cache.grouping = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when a blank grouping is set' do
      @report_cache.grouping = ''

      @report_cache.should_not be_valid
    end

    it 'should not succeed when no aggregation is set' do
      @report_cache.aggregation = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when a blank aggregation is set' do
      @report_cache.aggregation = ''

      @report_cache.should_not be_valid
    end

    it 'should not succeed when no value is set' do
      @report_cache.value = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when no reporting_period is set' do
      @report_cache.reporting_period = nil

      @report_cache.should_not be_valid
    end

    it 'should not succeed when a blank reporting_period is set' do
      @report_cache.reporting_period = ''

      @report_cache.should_not be_valid
    end

  end

  describe '.clear_for' do

    it 'should delete all entries in the cache for the klass and report name' do
      Saulabs::Reportable::ReportCache.should_receive(:delete_all).once.with(:conditions => {
        :model_name  => User.name,
        :report_name => 'registrations'
      })

      Saulabs::Reportable::ReportCache.clear_for(User, :registrations)
    end

  end

  describe '.process' do

    before do
      Saulabs::Reportable::ReportCache.stub!(:find).and_return([])
      Saulabs::Reportable::ReportCache.stub!(:prepare_result).and_return([])
    end

    it 'should raise an ArgumentError if no block is given' do
      lambda do
        Saulabs::Reportable::ReportCache.process(@report, @report.options)
      end.should raise_error(ArgumentError)
    end

    it 'sould start a transaction' do
      Saulabs::Reportable::ReportCache.should_receive(:transaction)

      Saulabs::Reportable::ReportCache.process(@report, @report.options) {}
    end

    describe 'with :live_data = true' do

      before do
        @options = @report.options.merge(:live_data => true)
      end

      it 'should yield to the given block' do
        lambda {
          Saulabs::Reportable::ReportCache.process(@report, @options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      it 'should yield the first reporting period if not all required data could be retrieved from the cache' do
        reporting_period = Saulabs::Reportable::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - 3.send(@report.options[:grouping].identifier)
        )
        Saulabs::Reportable::ReportCache.stub!(:all).and_return([Saulabs::Reportable::ReportCache.new])

        Saulabs::Reportable::ReportCache.process(@report, @options) do |begin_at, end_at|
          begin_at.should == Saulabs::Reportable::ReportingPeriod.first(@report.options[:grouping], @report.options[:limit]).date_time
          end_at.should   == nil
          []
        end
      end

      it 'should yield the reporting period after the last one in the cache if all required data could be retrieved from the cache' do
        reporting_period = Saulabs::Reportable::ReportingPeriod.new(
          @report.options[:grouping],
          Time.now - @report.options[:limit].send(@report.options[:grouping].identifier)
        )
        cached = Saulabs::Reportable::ReportCache.new
        cached.stub!(:reporting_period).and_return(reporting_period.date_time)
        Saulabs::Reportable::ReportCache.stub!(:all).and_return(Array.new(@report.options[:limit] - 1, Saulabs::Reportable::ReportCache.new), cached)

        Saulabs::Reportable::ReportCache.process(@report, @options) do |begin_at, end_at|
          begin_at.should == reporting_period.date_time
          end_at.should   == nil
          []
        end
      end

    end

    describe 'with :live_data = false' do

      it 'should not yield if all required data could be retrieved from the cache' do
        Saulabs::Reportable::ReportCache.stub!(:all).and_return(Array.new(@report.options[:limit], Saulabs::Reportable::ReportCache.new))

        lambda {
          Saulabs::Reportable::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should_not raise_error(YieldMatchException)
      end

      it 'should yield to the block if no data could be retrieved from the cache' do
        Saulabs::Reportable::ReportCache.stub!(:all).and_return([])

        lambda {
          Saulabs::Reportable::ReportCache.process(@report, @report.options) { raise YieldMatchException.new }
        }.should raise_error(YieldMatchException)
      end

      describe 'with :end_date = <some date>' do

        before do
          @options = @report.options.merge(:end_date => Time.now)
        end

        it 'should yield the last date and time of the reporting period for the specified end date' do
          reporting_period = Saulabs::Reportable::ReportingPeriod.new(@report.options[:grouping], @options[:end_date])

          Saulabs::Reportable::ReportCache.process(@report, @options) do |begin_at, end_at|
            end_at.should   == reporting_period.last_date_time
            []
          end
        end

      end

    end

    it 'should read existing data from the cache' do
      Saulabs::Reportable::ReportCache.should_receive(:all).once.with(
        :conditions => [
          %w(model_name report_name grouping aggregation conditions).map do |column_name|
            "#{Saulabs::Reportable::ReportCache.connection.quote_column_name(column_name)} = ?"
          end.join(' AND ') + ' AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          '',
          Saulabs::Reportable::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::Reportable::ReportCache.process(@report, @report.options) { [] }
    end

    it 'should utilize the end_date in the conditions' do
      end_date = Time.now
      Saulabs::Reportable::ReportCache.should_receive(:all).once.with(
        :conditions => [
          %w(model_name report_name grouping aggregation conditions).map do |column_name|
            "#{Saulabs::Reportable::ReportCache.connection.quote_column_name(column_name)} = ?"
          end.join(' AND ') + ' AND reporting_period BETWEEN ? AND ?',
          @report.klass.to_s,
          @report.name.to_s,
          @report.options[:grouping].identifier.to_s,
          @report.aggregation.to_s,
          '',
          Saulabs::Reportable::ReportingPeriod.first(@report.options[:grouping], 9).date_time,
          Saulabs::Reportable::ReportingPeriod.new(@report.options[:grouping], end_date).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::Reportable::ReportCache.process(@report, @report.options.merge(:end_date => end_date)) { [] }
    end

    it "should read existing data from the cache for the correct grouping if one other than the report's default grouping is specified" do
      grouping = Saulabs::Reportable::Grouping.new(:month)
      Saulabs::Reportable::ReportCache.should_receive(:all).once.with(
        :conditions => [
          %w(model_name report_name grouping aggregation conditions).map do |column_name|
            "#{Saulabs::Reportable::ReportCache.connection.quote_column_name(column_name)} = ?"
          end.join(' AND ') + ' AND reporting_period >= ?',
          @report.klass.to_s,
          @report.name.to_s,
          grouping.identifier.to_s,
          @report.aggregation.to_s,
          '',
          Saulabs::Reportable::ReportingPeriod.first(grouping, 10).date_time
        ],
        :limit => 10,
        :order => 'reporting_period ASC'
      ).and_return([])

      Saulabs::Reportable::ReportCache.process(@report, { :limit => 10, :grouping => grouping }) { [] }
    end

    it 'should yield the first reporting period if the cache is empty' do
      Saulabs::Reportable::ReportCache.process(@report, @report.options) do |begin_at, end_at|
        begin_at.should == Saulabs::Reportable::ReportingPeriod.first(@report.options[:grouping], 10).date_time
        end_at.should == nil
        []
      end
    end
  end
  
  describe '.serialize_conditions' do
    
    it 'should serialize empty conditions correctly' do
      result = Saulabs::Reportable::ReportCache.send(:serialize_conditions, [])
      result.should eql('')
    end
    
    it 'should serialize a conditions array correctly' do
      result = Saulabs::Reportable::ReportCache.send(:serialize_conditions, ['active = ? AND gender = ?', true, 'male'])
      result.should eql('active = ? AND gender = ?truemale')
    end
    
    it 'should serialize a conditions hash correctly' do
      result = Saulabs::Reportable::ReportCache.send(:serialize_conditions, { :gender => 'male', :active => true })
      result.should eql('activetruegendermale')
    end
    
  end

  describe '.prepare_result' do

    before do
      @current_reporting_period = Saulabs::Reportable::ReportingPeriod.new(@report.options[:grouping])
      @new_data = [[@current_reporting_period.previous.date_time, 1.0]]
      Saulabs::Reportable::ReportingPeriod.stub!(:from_db_string).and_return(@current_reporting_period.previous)
      @cached = Saulabs::Reportable::ReportCache.new
      @cached.stub!(:save!)
      Saulabs::Reportable::ReportCache.stub!(:build_cached_data).and_return(@cached)
    end

    it 'should create :limit instances of Saulabs::Reportable::ReportCache with value 0.0 if no new data has been read and nothing was cached' do
      Saulabs::Reportable::ReportCache.should_receive(:build_cached_data).exactly(10).times.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        anything(),
        0.0
      ).and_return(@cached)

      Saulabs::Reportable::ReportCache.send(:prepare_result, [], [], @report, @report.options)
    end

    it 'should create a new Saulabs::Reportable::ReportCache with the correct value if new data has been read' do
      Saulabs::Reportable::ReportCache.should_receive(:build_cached_data).exactly(9).times.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        anything(),
        0.0
      ).and_return(@cached)
      Saulabs::Reportable::ReportCache.should_receive(:build_cached_data).once.with(
        @report,
        @report.options[:grouping],
        @report.options[:conditions],
        @current_reporting_period.previous,
        1.0
      ).and_return(@cached)

      Saulabs::Reportable::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)
    end

    it 'should save the created Saulabs::Reportable::ReportCache' do
      @cached.should_receive(:save!)

      Saulabs::Reportable::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)
    end

    it 'should return an array of arrays of Dates and Floats' do
      result = Saulabs::Reportable::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options)

      result.should be_kind_of(Saulabs::Reportable::ResultSet)
      result.to_a.should be_kind_of(Array)
      result.to_a[0].should be_kind_of(Array)
      result.to_a[0][0].should be_kind_of(Date)
      result.to_a[0][1].should be_kind_of(Float)
    end

    describe 'with :live_data = false' do

      before do
        @result = Saulabs::Reportable::ReportCache.send(:prepare_result, @new_data, [], @report, @report.options).to_a
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
        @result = Saulabs::Reportable::ReportCache.send(:prepare_result, @new_data, [], @report, options).to_a
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
      @data = [[Saulabs::Reportable::ReportingPeriod.new(Saulabs::Reportable::Grouping.new(:day)), 3.0]]
    end

    it 'should return the correct value when new data has been read for the reporting period' do
      Saulabs::Reportable::ReportCache.send(:find_value, @data, @data[0][0]).should == 3.0
    end

    it 'should return 0.0 when no data has been read for the reporting period' do
      Saulabs::Reportable::ReportCache.send(:find_value, @data, @data[0][0].next).should == 0.0
    end

  end

end
