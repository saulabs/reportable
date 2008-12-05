require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Report do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
  end

  share_as :OptionValidation do

    it 'should not raise an error if valid options are specified' do
      lambda { @report.send(:ensure_valid_options, {
        :limit             => 100,
        :aggregation       => :count,
        :grouping          => :day,
        :date_column_name  => 'created_at',
        :value_column_name => 'id',
        :conditions        => []
      }) }.should_not raise_error(ArgumentError)
    end

    it 'should raise an error if an unsupported option is specified' do
      lambda { @report.send(:ensure_valid_options, { :invalid => :option }) }.should raise_error(ArgumentError)
    end

    it 'should raise an error if an invalid aggregation is specified' do
      lambda { @report.send(:ensure_valid_options, { :aggregation => :invalid }) }.should raise_error(ArgumentError)
    end

    it 'should raise an error if an invalid grouping is specified' do
      lambda { @report.send(:ensure_valid_options, { :aggregation => :invalid }) }.should raise_error(ArgumentError)
    end

    it 'should raise an error if malformed conditions are specified' do
      lambda { @report.send(:ensure_valid_options, { :conditions => 1 }) }.should raise_error(ArgumentError)
      lambda { @report.send(:ensure_valid_options, { :conditions => { :user_name => 'username' } }) }.should raise_error(ArgumentError)
    end

  end

  describe '.run' do

    include OptionValidation

    it 'should invoke the default aggregation method on the model' do
      User.should_receive(:count).once.and_return([])

      @report.run
    end

    it 'should invoke the custom aggregation method on the model if one is specified' do
      @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations, :aggregation => :sum)
      User.should_receive(:sum).once.and_return([])

      @report.run
    end

    describe do

      before do
        User.create!(:login => 'test 1', :created_at => Time.now - 1.week,  :profile_visits => 1)
        User.create!(:login => 'test 2', :created_at => Time.now - 2.weeks, :profile_visits => 2)
        User.create!(:login => 'test 3', :created_at => Time.now - 2.weeks, :profile_visits => 3)
      end

      it 'should validate the specified options' do
        @report.should_receive(:ensure_valid_options).once.with(:aggregation => :sum, :value_column_name => :profile_visits, :limit => 3)

        result = @report.run(:aggregation => :sum, :value_column_name => :profile_visits, :limit => 3)
      end

      it 'should return correct data for :aggregation => :count' do
        result = @report.run.to_a

        result[0][1].should == 1
        result[1][1].should == 2
      end

      it 'should return correct data for :aggregation => :sum' do
        result = @report.run(:aggregation => :sum, :value_column_name => :profile_visits).to_a

        result[0][1].should == 1
        result[1][1].should == 5
      end

      it 'should return correct data with custom conditions' do
        result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2']]).to_a

        result[0][1].should == 1
        result[1][1].should == 1
      end

      after do
        User.destroy_all
        Kvlr::ReportsAsSparkline::ReportCache.destroy_all
      end

    end

  end

  describe '.setup_conditions' do

    it 'should return conditions for date_column_name >= begin_at only if no custom conditions are specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at, 'created_at').should == ['created_at >= ?', begin_at]
    end

    it 'should return conditions for date_column_name >= begin_at only if an empty Hash of custom conditions is specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at, 'created_at', {}).should == ['created_at >= ?', begin_at]
    end

    it 'should return conditions for date_column_name >= begin_at only if an empty Array of custom conditions is specified' do
      begin_at = Time.now

      @report.send(:setup_conditions, begin_at, 'created_at', []).should == ['created_at >= ?', begin_at]
    end

    it 'should correctly include custom conditions if they are specified as a Hash' do
      begin_at = Time.now
      custom_conditions = { :first_name => 'first name', :last_name => 'last name' }

      conditions = @report.send(:setup_conditions, begin_at, 'created_at', custom_conditions)
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

      @report.send(:setup_conditions, begin_at, 'created_at', custom_conditions).should == [
        'first_name = ? AND last_name = ? AND created_at >= ?',
        'first name',
        'last name',
        begin_at
      ]
    end

  end

end
