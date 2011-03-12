require File.join(File.dirname(File.dirname(File.expand_path(__FILE__))),'spec_helper')

describe Saulabs::Reportable::CumulatedReport do

  before do
    @report = Saulabs::Reportable::CumulatedReport.new(User, :cumulated_registrations)
  end

  describe '#run' do

    it 'should cumulate the data' do
      @report.should_receive(:cumulate).once

      @report.run
    end

    it 'should return an array of the same length as the specified limit when :live_data is false' do
      @report = Saulabs::Reportable::CumulatedReport.new(User, :cumulated_registrations, :limit => 10, :live_data => false)

      @report.run.length.should == 10
    end

    it 'should return an array of the same length as the specified limit + 1 when :live_data is true' do
      @report = Saulabs::Reportable::CumulatedReport.new(User, :cumulated_registrations, :limit => 10, :live_data => true)

      @report.run.length.should == 11
    end
    
    for grouping in [:hour, :day, :week, :month] do

      describe "for grouping #{grouping.to_s}" do

        [true, false].each do |live_data|

          describe "with :live_data = #{live_data}" do

            before(:all) do
              User.delete_all
              User.create!(:login => 'test 1', :created_at => Time.now,                    :profile_visits => 2)
              User.create!(:login => 'test 2', :created_at => Time.now - 1.send(grouping), :profile_visits => 1)
              User.create!(:login => 'test 3', :created_at => Time.now - 3.send(grouping), :profile_visits => 2)
              User.create!(:login => 'test 4', :created_at => Time.now - 3.send(grouping), :profile_visits => 3)
            end

            describe 'the returned result' do

              before do
                @grouping = Saulabs::Reportable::Grouping.new(grouping)
                @report = Saulabs::Reportable::CumulatedReport.new(User, :cumulated_registrations,
                  :grouping  => grouping,
                  :limit     => 10,
                  :live_data => live_data
                )
                @result = @report.run
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
              @report = Saulabs::Reportable::CumulatedReport.new(User, :registrations,
                :aggregation => :count,
                :grouping    => grouping,
                :limit       => 10,
                :live_data   => live_data
              )
              result = @report.run

              result[10][1].should == 4.0 if live_data
              result[9][1].should  == 3.0
              result[8][1].should  == 2.0
              result[7][1].should  == 2.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :sum' do
              @report = Saulabs::Reportable::CumulatedReport.new(User, :registrations,
                :aggregation  => :sum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run()

              result[10][1].should == 8.0 if live_data
              result[9][1].should  == 6.0
              result[8][1].should  == 5.0
              result[7][1].should  == 5.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :count when custom conditions are specified' do
              @report = Saulabs::Reportable::CumulatedReport.new(User, :registrations,
                :aggregation => :count,
                :grouping    => grouping,
                :limit       => 10,
                :live_data   => live_data
              )
              result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2', 'test 4']])

              result[10][1].should == 3.0 if live_data
              result[9][1].should  == 2.0
              result[8][1].should  == 1.0
              result[7][1].should  == 1.0
              result[6][1].should  == 0.0
            end

            it 'should return correct data for aggregation :sum when custom conditions are specified' do
              @report = Saulabs::Reportable::CumulatedReport.new(User, :registrations,
                :aggregation  => :sum,
                :grouping     => grouping,
                :value_column => :profile_visits,
                :limit        => 10,
                :live_data    => live_data
              )
              result = @report.run(:conditions => ['login IN (?)', ['test 1', 'test 2', 'test 4']])

              result[10][1].should == 6.0 if live_data
              result[9][1].should  == 4.0
              result[8][1].should  == 3.0
              result[7][1].should  == 3.0
              result[6][1].should  == 0.0
            end

          end

          after(:all) do
            User.destroy_all
          end

        end

      end

    end

    after(:each) do
      Saulabs::Reportable::ReportCache.destroy_all
    end

  end

  describe '#cumulate' do

    it 'should correctly cumulate the given data' do
      first = (Time.now - 1.week).to_s
      second = Time.now.to_s
      data = [[first, 1], [second, 2]]

      @report.send(:cumulate, data, @report.send(:options_for_run, {})).should == [[first, 1.0], [second, 3.0]]
    end

  end

end
