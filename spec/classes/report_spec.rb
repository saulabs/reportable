require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Report do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
  end

  describe '#run' do

    it 'should process the data with the report cache' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => @report.options[:grouping], :conditions => [] },
        true
      )

      @report.run
    end

    it 'should process the data with the report cache and specify cache = false when custom conditions are given' do
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => @report.options[:grouping], :conditions => { :some => :condition } },
        false
      )

      @report.run(:conditions => { :some => :condition })
    end

    it 'should validate the specified options for the :run context' do
      @report.should_receive(:ensure_valid_options).once.with({ :limit => 3 }, :run)

      result = @report.run(:limit => 3)
    end

    it 'should use a custom grouping if one is specified' do
      grouping = Kvlr::ReportsAsSparkline::Grouping.new(:month)
      Kvlr::ReportsAsSparkline::Grouping.should_receive(:new).once.with(:month).and_return(grouping)
      Kvlr::ReportsAsSparkline::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => grouping, :conditions => [] },
        true
      )

      @report.run(:grouping => :month)
    end

    for grouping in [:hour, :day, :week, :month] do

      describe "for grouping #{grouping.to_s}" do

        before(:all) do
          User.create!(:login => 'test 1', :created_at => Time.now - 1.send(grouping), :profile_visits => 1)
          User.create!(:login => 'test 2', :created_at => Time.now - 3.send(grouping), :profile_visits => 2)
          User.create!(:login => 'test 3', :created_at => Time.now - 3.send(grouping), :profile_visits => 3)
        end

        describe do

          before do
            @grouping = Kvlr::ReportsAsSparkline::Grouping.new(grouping)
            @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :grouping => grouping, :limit => 10)
            @result = @report.run
          end

          it "should return an array starting reporting period (Time.now - (limit - 1).#{grouping.to_s})" do
            @result.first[0].should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(@grouping, Time.now - 9.send(grouping)).date_time
          end

          it "should return data ending with with the current reporting period" do
            @result.last[0].should == Kvlr::ReportsAsSparkline::ReportingPeriod.new(@grouping).date_time
          end

        end

        it 'should return correct data for aggregation :count' do
          @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :count, :grouping => grouping, :limit => 10)
          result = @report.run.to_a

          result[9][1].should == 0.0
          result[8][1].should == 1.0
          result[7][1].should == 0.0
          result[6][1].should == 2.0
        end

        it 'should return correct data for aggregation :sum' do
          @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :sum, :grouping => grouping, :value_column => :profile_visits, :limit => 10)
          result = @report.run().to_a

          result[9][1].should == 0.0
          result[8][1].should == 1.0
          result[7][1].should == 0.0
          result[6][1].should == 5.0
        end

        it 'should return correct data for aggregation :count when custom conditions are specified' do
          @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :count, :grouping => grouping, :limit => 10)
          result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2']]).to_a

          result[9][1].should == 0.0
          result[8][1].should == 1.0
          result[7][1].should == 0.0
          result[6][1].should == 1.0
        end

        it 'should return correct data for aggregation :sum when custom conditions are specified' do
          @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :sum, :grouping => grouping, :value_column => :profile_visits, :limit => 10)
          result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2']]).to_a

          result[9][1].should == 0.0
          result[8][1].should == 1.0
          result[7][1].should == 0.0
          result[6][1].should == 2.0
        end

        after(:all) do
          User.destroy_all
        end

        after(:each) do
          Kvlr::ReportsAsSparkline::ReportCache.destroy_all
        end

      end

    end

  end

  describe '#read_data' do

    it 'should invoke the aggregation method on the model' do
      @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :count)
      User.should_receive(:count).once.and_return([])

      @report.send(:read_data, Time.now, @report.options[:grouping])
    end

    it 'should setup the conditions' do
      @report.should_receive(:setup_conditions).once.and_return([])

      @report.send(:read_data, Time.now, @report.options[:grouping])
    end

  end

  describe '#setup_conditions' do

    it 'should return conditions for date_column >= begin_at only when no custom conditions are specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at).should == ['created_at >= ?', begin_at]
    end

    it 'should return conditions for date_column >= begin_at only when an empty Hash of custom conditions is specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at, {}).should == ['created_at >= ?', begin_at]
    end

    it 'should return conditions for date_column >= begin_at only when an empty Array of custom conditions is specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at, []).should == ['created_at >= ?', begin_at]
    end

    it 'should correctly include custom conditions if they are specified as a Hash' do
      begin_at = Time.now
      custom_conditions = { :first_name => 'first name', :last_name => 'last name' }

      conditions = @report.send(:setup_conditions, begin_at, custom_conditions)
      #cannot check for equality of complete conditions array since hashes are not ordered (thus it is unknown whether first_name or last_name comes first)
      conditions[0].should include('first_name = ?')
      conditions[0].should include('last_name = ?')
      conditions[0].should include('created_at >= ?')
      conditions.should include('first name')
      conditions.should include('last name')
      conditions.should include(begin_at)
    end

    it 'should correctly include custom conditions if they are specified as an Array' do
      begin_at = Time.now
      custom_conditions = ['first_name = ? AND last_name = ?', 'first name', 'last name']

      @report.send(:setup_conditions, begin_at, custom_conditions).should == [
        'first_name = ? AND last_name = ? AND created_at >= ?',
        'first name',
        'last name',
        begin_at
      ]
    end

  end

  describe '#ensure_valid_options' do

    it 'should raise an error if malformed conditions are specified' do
      lambda { @report.send(:ensure_valid_options, { :conditions => 1 }) }.should raise_error(ArgumentError)
    end

    it 'should not raise an error if conditions are specified as an Array' do
      lambda { @report.send(:ensure_valid_options, { :conditions => ['first_name = ?', 'first name'] }) }.should_not raise_error(ArgumentError)
    end

    it 'should not raise an error if conditions are specified as a Hash' do
      lambda { @report.send(:ensure_valid_options, { :conditions => { :first_name => 'first name' } }) }.should_not raise_error(ArgumentError)
    end

    it 'should raise an error if an invalid grouping is specified' do
      lambda { @report.send(:ensure_valid_options, { :grouping => :decade }) }.should raise_error(ArgumentError)
    end

    describe 'for context :initialize' do

      it 'should not raise an error if valid options are specified' do
        lambda { @report.send(:ensure_valid_options, {
            :limit        => 100,
            :aggregation  => :count,
            :grouping     => :day,
            :date_column  => :created_at,
            :value_column => :id,
            :conditions   => []
          })
        }.should_not raise_error(ArgumentError)
      end
      
      it 'should raise an error if an unsupported option is specified' do
        lambda { @report.send(:ensure_valid_options, { :invalid => :option }) }.should raise_error(ArgumentError)
      end
      
      it 'should raise an error if an invalid aggregation is specified' do
        lambda { @report.send(:ensure_valid_options, { :aggregation => :invalid }) }.should raise_error(ArgumentError)
      end

      it 'should raise an error if aggregation :sum is spesicied but no :value_column' do
        lambda { @report.send(:ensure_valid_options, { :aggregation => :sum }) }.should raise_error(ArgumentError)
      end

    end

    describe 'for context :run' do

      it 'should not raise an error if valid options are specified' do
        lambda { @report.send(:ensure_valid_options, { :limit => 100, :conditions => [], :grouping => :week }, :run)
        }.should_not raise_error(ArgumentError)
      end
      
      it 'should raise an error if an unsupported option is specified' do
        lambda { @report.send(:ensure_valid_options, { :aggregation => :sum }, :run) }.should raise_error(ArgumentError)
      end

    end
  
  end

end
