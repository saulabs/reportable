require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::CumulatedReport do

  describe '#run' do

    describe do

      before do
        User.create!(:login => 'test 1', :created_at => Time.now - 1.week,  :profile_visits => 1)
        User.create!(:login => 'test 2', :created_at => Time.now - 2.weeks, :profile_visits => 2)
        User.create!(:login => 'test 3', :created_at => Time.now - 2.weeks, :profile_visits => 3)
      end

      it 'should return correct data for :aggregation => :count' do
        result = User.cumulated_registrations_report.to_a

        result[0][1].should == 1
        result[1][1].should == 3
      end

      it 'should return correct data for :aggregation => :sum' do
        result = User.cumulated_registrations_report(:aggregation => :sum, :value_column_name => :profile_visits).to_a

        result[0][1].should == 1
        result[1][1].should == 6
      end

      it 'should return correct data with custom conditions' do
        result = User.cumulated_registrations_report(:conditions => ['login IN (?)', ['test 1', 'test 2']]).to_a

        result[0][1].should == 1
        result[1][1].should == 2
      end

      after do
        User.destroy_all
      end

    end

  end

end
