require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Report do

  before do
    @report = Kvlr::ReportsAsSparkline::Report.new(User, :registrations)
  end

  describe '.run' do

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
      end

    end

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

end
