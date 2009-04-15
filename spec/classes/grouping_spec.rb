require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Simplabs::ReportsAsSparkline::Grouping do

  describe '#new' do

    it 'should raise an error if an unsupported grouping is specified' do
      lambda { Simplabs::ReportsAsSparkline::Grouping.new(:unsupported) }.should raise_error(ArgumentError)
    end

  end

  describe '#to_sql' do

    describe 'for MySQL' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('MySQL')
      end

      it 'should use DATE_FORMAT with format string "%Y/%m/%d/%H" for grouping :hour' do
        Simplabs::ReportsAsSparkline::Grouping.new(:hour).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m/%d/%H')"
      end

      it 'should use DATE_FORMAT with format string "%Y/%m/%d" for grouping :day' do
        Simplabs::ReportsAsSparkline::Grouping.new(:day).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m/%d')"
      end

      it 'should use YEARWEEK with mode 3 for grouping :week' do
        Simplabs::ReportsAsSparkline::Grouping.new(:week).send(:to_sql, 'created_at').should == "YEARWEEK(created_at, 3)"
      end

      it 'should use DATE_FORMAT with format string "%Y/%m" for grouping :month' do
        Simplabs::ReportsAsSparkline::Grouping.new(:month).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m')"
      end

    end

    describe 'for PostgreSQL' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('PostgreSQL')
      end

      for grouping in [:hour, :day, :week, :month] do

        it "should use date_trunc with truncation identifier \"#{grouping.to_s}\" for grouping :#{grouping.to_s}" do
          Simplabs::ReportsAsSparkline::Grouping.new(grouping).send(:to_sql, 'created_at').should == "date_trunc('#{grouping.to_s}', created_at)"
        end

      end

    end

    describe 'for SQLite3' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('SQLite')
      end

      it 'should use strftime with format string "%Y/%m/%d/%H" for grouping :hour' do
        Simplabs::ReportsAsSparkline::Grouping.new(:hour).send(:to_sql, 'created_at').should == "strftime('%Y/%m/%d/%H', created_at)"
      end

      it 'should use strftime with format string "%Y/%m/%d" for grouping :day' do
        Simplabs::ReportsAsSparkline::Grouping.new(:day).send(:to_sql, 'created_at').should == "strftime('%Y/%m/%d', created_at)"
      end

      it 'should use date with mode "weekday 0" for grouping :week' do
        Simplabs::ReportsAsSparkline::Grouping.new(:week).send(:to_sql, 'created_at').should == "date(created_at, 'weekday 0')"
      end

      it 'should use strftime with format string "%Y/%m" for grouping :month' do
        Simplabs::ReportsAsSparkline::Grouping.new(:month).send(:to_sql, 'created_at').should == "strftime('%Y/%m', created_at)"
      end

    end

  end

  describe '#date_parts_from_db_string' do

    describe 'for SQLite3' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('SQLite')
      end

      for grouping in [[:hour, '2008/12/31/12'], [:day, '2008/12/31'], [:month, '2008/12']] do

        it "should split the string with '/' for grouping :#{grouping[0].to_s}" do
          Simplabs::ReportsAsSparkline::Grouping.new(grouping[0]).date_parts_from_db_string(grouping[1]).should == grouping[1].split('/').map(&:to_i)
        end

      end

      it 'should split the string with "-" and return teh calendar year and week for grouping :week' do
        db_string = '2008-2-1'
        expected = [2008, 5]

        Simplabs::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string(db_string).should == expected
      end

    end

    describe 'for PostgreSQL' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('PostgreSQL')
      end

      it 'should split the date part of the string with "-" and read out the hour for grouping :hour' do
        Simplabs::ReportsAsSparkline::Grouping.new(:hour).date_parts_from_db_string('2008-12-03 06:00:00').should == [2008, 12, 03, 6]
      end

      it 'should split the date part of the string with "-" for grouping :day' do
        Simplabs::ReportsAsSparkline::Grouping.new(:day).date_parts_from_db_string('2008-12-03 00:00:00').should == [2008, 12, 03]
      end

      it 'should split the date part of the string with "-" and calculate the calendar week for grouping :week' do
        Simplabs::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string('2008-12-01 00:00:00').should == [2008, 49]
      end

      it 'should split the date part of the string with "-" and return year and month for grouping :month' do
        Simplabs::ReportsAsSparkline::Grouping.new(:month).date_parts_from_db_string('2008-12-01 00:00:00').should == [2008, 12]
      end

    end

    describe 'for MySQL' do

      before do
        ActiveRecord::Base.connection.stub!(:adapter_name).and_return('MySQL')
      end

      for grouping in [[:hour, '2008/12/31/12'], [:day, '2008/12/31'], [:month, '2008/12']] do

        it "should split the string with '/' for grouping :#{grouping[0].to_s}" do
          Simplabs::ReportsAsSparkline::Grouping.new(grouping[0]).date_parts_from_db_string(grouping[1]).should == grouping[1].split('/').map(&:to_i)
        end

      end

      it 'should use the first 4 numbers for the year and the last 2 numbers for the week for grouping :week' do
        db_string = '200852'
        expected = [2008, 52]

        Simplabs::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string(db_string).should == expected
      end

    end

  end

end
