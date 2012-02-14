require File.join(File.dirname(File.dirname(File.expand_path(__FILE__))),'spec_helper')

describe Saulabs::Reportable::Report do

  before do
    @report = Saulabs::Reportable::Report.new(User, :registrations)
    @now    = Time.now
    DateTime.stub!(:now).and_return(@now)
  end

  describe '#options' do

    it 'should be frozen' do
      @report.options.should be_frozen
    end

  end

  describe '#run' do

    it 'should process the data with the report cache' do
      Saulabs::Reportable::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => @report.options[:grouping], :conditions => [], :live_data => false, :end_date => false }
      )

      @report.run
    end

    it 'should process the data with the report cache when custom conditions are given' do
      Saulabs::Reportable::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => @report.options[:grouping], :conditions => { :some => :condition }, :live_data => false, :end_date => false }
      )

      @report.run(:conditions => { :some => :condition })
    end

    it 'should validate the specified options for the :run context' do
      @report.should_receive(:ensure_valid_options).once.with({ :limit => 3 }, :run)

      result = @report.run(:limit => 3)
    end

    it 'should use a custom grouping if one is specified' do
      grouping = Saulabs::Reportable::Grouping.new(:month)
      Saulabs::Reportable::Grouping.should_receive(:new).once.with(:month).and_return(grouping)
      Saulabs::Reportable::ReportCache.should_receive(:process).once.with(
        @report,
        { :limit => 100, :grouping => grouping, :conditions => [], :live_data => false, :end_date => false }
      )

      @report.run(:grouping => :month)
    end

    it 'should return an array of the same length as the specified limit when :live_data is false' do
      @report = Saulabs::Reportable::Report.new(User, :cumulated_registrations, :limit => 10, :live_data => false)

      @report.run.to_a.length.should == 10
    end

    it 'should return an array of the same length as the specified limit + 1 when :live_data is true' do
      @report = Saulabs::Reportable::Report.new(User, :cumulated_registrations, :limit => 10, :live_data => true)

      @report.run.to_a.length.should == 11
    end

    for grouping in [:hour, :day, :week, :month] do

      describe "for grouping :#{grouping.to_s}" do

        before(:all) do
          User.create!(:login => 'test 1', :created_at => Time.now,                    :profile_visits => 2)
          User.create!(:login => 'test 2', :created_at => Time.now - 1.send(grouping), :profile_visits => 1)
          User.create!(:login => 'test 3', :created_at => Time.now - 3.send(grouping), :profile_visits => 2)
          User.create!(:login => 'test 4', :created_at => Time.now - 3.send(grouping), :profile_visits => 3)
        end

        describe 'when :end_date is specified' do

          it 'should not raise a SQL duplicate key error after multiple runs' do
            @report = Saulabs::Reportable::Report.new(User, :registrations,
              :limit    => 2,
              :grouping => grouping,
              :end_date => Date.yesterday.to_datetime
            )
            @report.run
            lambda { @report.run }.should_not raise_error
          end

          describe 'the returned result' do

            before do
              @end_date = DateTime.now - 1.send(grouping)
              @grouping = Saulabs::Reportable::Grouping.new(grouping)
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :grouping => grouping,
                :limit    => 10,
                :end_date => @end_date
              )
              @result = @report.run.to_a
            end

            it "should start with the reporting period (end_date - limit.#{grouping.to_s})" do
              @result.first[0].should == Saulabs::Reportable::ReportingPeriod.new(@grouping, @end_date - 9.send(grouping)).date_time
            end

            it "should end with the reporting period of the specified end date" do
              @result.last[0].should == Saulabs::Reportable::ReportingPeriod.new(@grouping, @end_date).date_time
            end

          end

        end

        [true, false].each do |live_data|

          describe "with :live_data = #{live_data}" do

            describe 'the returned result' do

              before do
                Saulabs::Reportable::ReportCache.delete_all
                @grouping = Saulabs::Reportable::Grouping.new(grouping)
                @report = Saulabs::Reportable::Report.new(User, :registrations,
                  :grouping  => grouping,
                  :limit     => 10,
                  :live_data => live_data
                )
                @result = @report.run.to_a
              end

              it "should be an array starting reporting period (Time.now - limit.#{grouping.to_s})" do
                @result.first[0].should == Saulabs::Reportable::ReportingPeriod.new(@grouping, Time.now - 10.send(grouping)).date_time
              end

              if live_data
                it "should be data ending with the current reporting period" do
                  @result.last[0].should == Saulabs::Reportable::ReportingPeriod.new(@grouping).date_time
                end
              else
                it "should be data ending with the reporting period before the current" do
                  @result.last[0].should == Saulabs::Reportable::ReportingPeriod.new(@grouping).previous.date_time
                end
              end

            end

            it 'should return correct data for aggregation :count' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation => :count,
                :grouping    => grouping,
                :limit       => 10,
                :live_data   => live_data
              )
              result = @report.run.to_a

              result[10][1].should == 1.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 2.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :sum' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation  => :sum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run().to_a

              result[10][1].should == 2.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 5.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :maximum' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation  => :maximum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run().to_a

              result[10][1].should == 2.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 3.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :minimum' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation  => :minimum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run().to_a

              result[10][1].should == 2.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 2.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :average' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation  => :average,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run().to_a

              result[10][1].should == 2.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 2.5
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :count when custom conditions are specified' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation => :count,
                :grouping    => grouping,
                :limit       => 10,
                :live_data   => live_data
              )
              result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2', 'test 4']]).to_a

              result[10][1].should == 1.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 1.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :sum when custom conditions are specified' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation  => :sum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2', 'test 4']]).to_a

              result[10][1].should == 2.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 3.0
              result[6][1].should  == 0.0
            end

            it 'should return correct results when run twice in a row with a higher limit on the second run' do
              @report = Saulabs::Reportable::Report.new(User, :registrations,
                :aggregation => :count,
                :grouping    => grouping,
                :limit       => 10,
                :live_data   => live_data
              )
              result = @report.run(:limit => 2).to_a

              result[2][1].should == 1.0 if live_data
              result[1][1].should  == 1.0
              result[0][1].should  == 0.0

              result = @report.run(:limit => 10).to_a

              result[10][1].should == 1.0 if live_data
              result[9][1].should  == 1.0
              result[8][1].should  == 0.0
              result[7][1].should  == 2.0
              result[6][1].should  == 0.0
            end

            unless live_data

              it 'should return correct data for aggregation :count when :end_date is specified' do
                @report = Saulabs::Reportable::Report.new(User, :registrations,
                  :aggregation => :count,
                  :grouping    => grouping,
                  :limit       => 10,
                  :end_date    => Time.now - 3.send(grouping)
                )
                result = @report.run.to_a

                result[9][1].should  == 2.0
                result[8][1].should  == 0.0
                result[7][1].should  == 0.0
                result[6][1].should  == 0.0
              end

              it 'should return correct data for aggregation :sum when :end_date is specified' do
                @report = Saulabs::Reportable::Report.new(User, :registrations,
                  :aggregation  => :sum,
                  :grouping     => grouping,
                  :value_column => :profile_visits,
                  :limit        => 10,
                  :end_date     => Time.now - 3.send(grouping)
                )
                result = @report.run.to_a

                result[9][1].should  == 5.0
                result[8][1].should  == 0.0
                result[7][1].should  == 0.0
                result[6][1].should  == 0.0
              end

              it 'should return correct results when run twice in a row with an end date further in the past on the second run' do
                @report = Saulabs::Reportable::Report.new(User, :registrations,
                  :aggregation => :count,
                  :grouping    => grouping,
                  :limit       => 10,
                  :live_data   => live_data
                )
                result = @report.run(:end_date => Time.now - 1.send(grouping)).to_a

                result[9][1].should  == 1.0
                result[8][1].should  == 0.0
                result[7][1].should  == 2.0

                result = @report.run(:end_date => Time.now - 3.send(grouping)).to_a

                result[9][1].should  == 2.0
                result[8][1].should  == 0.0
                result[7][1].should  == 0.0
              end

            end

          end

        end

        after(:all) do
          User.destroy_all
        end

      end

    end

    describe 'for grouping week with data ranging over two years' do

      describe 'with the first week of the second year belonging to the first year' do

        before(:all) do
          User.create!(:login => 'test 1', :created_at => DateTime.new(2008, 12, 22))
          User.create!(:login => 'test 2', :created_at => DateTime.new(2008, 12, 29))
          User.create!(:login => 'test 3', :created_at => DateTime.new(2009, 1, 4))
          User.create!(:login => 'test 4', :created_at => DateTime.new(2009, 1, 5))
          User.create!(:login => 'test 5', :created_at => DateTime.new(2009, 1, 12))

          Time.stub!(:now).and_return(DateTime.new(2009, 1, 25))
        end

        it 'should return correct data for aggregation :count' do
          @report = Saulabs::Reportable::Report.new(User, :registrations,
            :aggregation => :count,
            :grouping    => :week,
            :limit       => 10
          )
          result = @report.run.to_a

          result[9][1].should  == 0.0
          result[8][1].should  == 1.0
          result[7][1].should  == 1.0
          result[6][1].should  == 2.0
          result[5][1].should  == 1.0
        end

      end

      describe 'with the first week of the second year belonging to the second year' do

        before(:all) do
          User.create!(:login => 'test 1', :created_at => DateTime.new(2009, 12, 21))
          User.create!(:login => 'test 2', :created_at => DateTime.new(2009, 12, 28))
          User.create!(:login => 'test 3', :created_at => DateTime.new(2010, 1, 3))
          User.create!(:login => 'test 4', :created_at => DateTime.new(2010, 1, 4))
          User.create!(:login => 'test 5', :created_at => DateTime.new(2010, 1, 11))

          Time.stub!(:now).and_return(DateTime.new(2010, 1, 25))
        end

        it 'should return correct data for aggregation :count' do
          @report = Saulabs::Reportable::Report.new(User, :registrations,
            :aggregation => :count,
            :grouping    => :week,
            :limit       => 10
          )
          result = @report.run.to_a

          result[9][1].should  == 0.0
          result[8][1].should  == 1.0
          result[7][1].should  == 1.0
          result[6][1].should  == 2.0
          result[5][1].should  == 1.0
        end

      end

    end

    after do
      Saulabs::Reportable::ReportCache.destroy_all
    end

    after(:all) do
      User.destroy_all
    end

  end

  describe '#read_data' do

    it 'should invoke the aggregation method on the model' do
      @report = Saulabs::Reportable::Report.new(User, :registrations, :aggregation => :count)
      User.should_receive(:count).once.and_return([])

      @report.send(:read_data, Time.now, 5.days.from_now, { :grouping => @report.options[:grouping], :conditions => [] })
    end

    it 'should setup the conditions' do
      @report.should_receive(:setup_conditions).once.and_return([])

      @report.send(:read_data, Time.now, 5.days.from_now, { :grouping => @report.options[:grouping], :conditions => [] })
    end

  end

  describe '#setup_conditions' do

    before do
      @begin_at = Time.now
      @end_at = 5.days.from_now
      @created_at_column_clause = "#{ActiveRecord::Base.connection.quote_table_name('users')}.#{ActiveRecord::Base.connection.quote_column_name('created_at')}"
    end

    it 'should return conditions for date_column BETWEEN begin_at and end_at only when no custom conditions are specified and both begin and end date are specified' do
      @report.send(:setup_conditions, @begin_at, @end_at).should == ["#{@created_at_column_clause} BETWEEN ? AND ?", @begin_at, @end_at]
    end

    it 'should return conditions for date_column >= begin_at when no custom conditions and a begin_at are specified' do
      @report.send(:setup_conditions, @begin_at, nil).should == ["#{@created_at_column_clause} >= ?", @begin_at]
    end

    it 'should return conditions for date_column <= end_at when no custom conditions and a end_at are specified' do
      @report.send(:setup_conditions, nil, @end_at).should == ["#{@created_at_column_clause} <= ?", @end_at]
    end

    it 'should raise an argument error when neither begin_at or end_at are specified' do
      lambda {@report.send(:setup_conditions, nil, nil)}.should raise_error(ArgumentError)
    end

    it 'should return conditions for date_column BETWEEN begin_at and end_date only when an empty Hash of custom conditions is specified' do
      @report.send(:setup_conditions, @begin_at, @end_at, {}).should == ["#{@created_at_column_clause} BETWEEN ? AND ?", @begin_at, @end_at]
    end

    it 'should return conditions for date_column BETWEEN begin_at and end_date only when an empty Array of custom conditions is specified' do
      @report.send(:setup_conditions, @begin_at, @end_at, []).should == ["#{@created_at_column_clause} BETWEEN ? AND ?", @begin_at, @end_at]
    end

    it 'should correctly include custom conditions if they are specified as a Hash' do
      custom_conditions = { :first_name => 'first name', :last_name => 'last name' }

      conditions = @report.send(:setup_conditions, @begin_at, @end_at, custom_conditions)
      # cannot directly check for string equqlity here since hashes are not ordered and so there is no way to now in which order the conditions are added to the SQL clause
      conditions[0].should =~ (/#{ActiveRecord::Base.connection.quote_table_name('users')}.#{ActiveRecord::Base.connection.quote_column_name('first_name')} = #{ActiveRecord::Base.connection.quote('first name')}/)
      conditions[0].should =~ (/#{ActiveRecord::Base.connection.quote_table_name('users')}.#{ActiveRecord::Base.connection.quote_column_name('last_name')} = #{ActiveRecord::Base.connection.quote('last name')}/)
      conditions[0].should =~ (/#{@created_at_column_clause} BETWEEN \? AND \?/)
      conditions[1].should == @begin_at
      conditions[2].should == @end_at
    end

    it 'should correctly include custom conditions if they are specified as an Array' do
      custom_conditions = ['first_name = ? AND last_name = ?', 'first name', 'last name']

      @report.send(:setup_conditions, @begin_at, @end_at, custom_conditions).should == ["first_name = #{ActiveRecord::Base.connection.quote('first name')} AND last_name = #{ActiveRecord::Base.connection.quote('last name')} AND #{@created_at_column_clause} BETWEEN ? AND ?", @begin_at, @end_at]
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

    it 'should raise an error if an end date is specified that is not a DateTime' do
      lambda { @report.send(:ensure_valid_options, { :end_date => 'today' }) }.should raise_error(ArgumentError)
    end

    it 'should raise an error if an end date is specified that is in the future' do
      lambda { @report.send(:ensure_valid_options, { :end_date => (DateTime.now + 1.month) }) }.should raise_error(ArgumentError)
    end

    it 'should raise an error if both an end date and :live_data = true are specified' do
      lambda { @report.send(:ensure_valid_options, { :end_date => DateTime.now, :live_data => true }) }.should raise_error(ArgumentError)
    end

    it 'should not raise an error if both an end date and :live_data = false are specified' do
      lambda { @report.send(:ensure_valid_options, { :end_date => DateTime.now, :live_data => false }) }.should_not raise_error
    end

    describe 'for context :initialize' do

      it 'should not raise an error if valid options are specified' do
        lambda { @report.send(:ensure_valid_options, {
            :limit        => 100,
            :aggregation  => :count,
            :grouping     => :day,
            :date_column  => :created_at,
            :value_column => :id,
            :conditions   => [],
            :live_data    => true
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
        lambda { @report.send(:ensure_valid_options, { :limit => 100, :conditions => [], :grouping => :week, :live_data => true }, :run)
        }.should_not raise_error(ArgumentError)
      end

      it 'should raise an error if an unsupported option is specified' do
        lambda { @report.send(:ensure_valid_options, { :aggregation => :sum }, :run) }.should raise_error(ArgumentError)
      end

    end

  end

end
