require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Kvlr::ReportsAsSparkline::Grouping do

  describe '#new' do

    it 'should raise an error if an unsupported grouping is specified' do
      lambda { Kvlr::ReportsAsSparkline::Grouping.new(:unsupported) }.should raise_error(ArgumentError)
    end

  end

  describe '.to_sql' do

    describe 'for MySQL' do

      before do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::MysqlAdapter)
      end

      it 'should use DATE_FORMAT with format string "%Y/%m/%d/%H" for grouping :hour' do
        Kvlr::ReportsAsSparkline::Grouping.new(:hour).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m/%d/%H')"
      end

      it 'should use DATE_FORMAT with format string "%Y/%m/%d" for grouping :day' do
        Kvlr::ReportsAsSparkline::Grouping.new(:day).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m/%d')"
      end

      it 'should use DATE_FORMAT with format string "%Y/%u" for grouping :week' do
        Kvlr::ReportsAsSparkline::Grouping.new(:week).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%u')"
      end

      it 'should use DATE_FORMAT with format string "%Y/%m" for grouping :month' do
        Kvlr::ReportsAsSparkline::Grouping.new(:month).send(:to_sql, 'created_at').should == "DATE_FORMAT(created_at, '%Y/%m')"
      end

    end

    describe 'for PostgreSQL' do

      before do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      end

      it 'should use date_trunc with trunc "hour" for grouping :hour' do
        Kvlr::ReportsAsSparkline::Grouping.new(:hour).send(:to_sql, 'created_at').should == "date_trunc('hour', created_at)"
      end

      it 'should use date_trunc with trunc "day" for grouping :day' do
        Kvlr::ReportsAsSparkline::Grouping.new(:day).send(:to_sql, 'created_at').should == "date_trunc('day', created_at)"
      end

      it 'should use date_trunc with trunc "week" for grouping :week' do
        Kvlr::ReportsAsSparkline::Grouping.new(:week).send(:to_sql, 'created_at').should == "date_trunc('week', created_at)"
      end

      it 'should use date_trunc with trunc "month" for grouping :month' do
        Kvlr::ReportsAsSparkline::Grouping.new(:month).send(:to_sql, 'created_at').should == "date_trunc('month', created_at)"
      end

    end

    describe 'for SQLite3' do

      before do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
      end

      it 'should use strftime with format string "%Y/%m/%d/%H" for grouping :hour' do
        Kvlr::ReportsAsSparkline::Grouping.new(:hour).send(:to_sql, 'created_at').should == "strftime('%Y/%m/%d/%H', created_at)"
      end

      it 'should use strftime with format string "%Y/%m/%d" for grouping :day' do
        Kvlr::ReportsAsSparkline::Grouping.new(:day).send(:to_sql, 'created_at').should == "strftime('%Y/%m/%d', created_at)"
      end

      it 'should use strftime with format string "%Y/%W" for grouping :week' do
        Kvlr::ReportsAsSparkline::Grouping.new(:week).send(:to_sql, 'created_at').should == "strftime('%Y/%W', created_at)"
      end

      it 'should use strftime with format string "%Y/%m" for grouping :month' do
        Kvlr::ReportsAsSparkline::Grouping.new(:month).send(:to_sql, 'created_at').should == "strftime('%Y/%m', created_at)"
      end

    end

  end

  describe '#date_parts_from_db_string' do
=begin
    for grouping in [[:hour, '2008/12/31/12'], [:day, '2008/12/31'], [:month, '2008/12']] do

      it "should split the string with '/' for grouping :#{grouping[0].to_s}" do
        db_string = grouping[1]

        Kvlr::ReportsAsSparkline::Grouping.new(grouping[0]).date_parts_from_db_string(db_string).should == db_string.split('/').map(&:to_i)
      end

    end
=end
    describe 'for SQLite3' do

      it 'should split the string with "/" and increment the week by 1 for grouping :week' do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::SQLite3Adapter)
        db_string = '2008/2'
        expected = [2008, 3]

        Kvlr::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string(db_string).should == expected
      end

    end

    describe 'for PostgreSQL' do

      before do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      end

      it 'should split the date part of the string with "-" for grouping :day' do
        Kvlr::ReportsAsSparkline::Grouping.new(:day).date_parts_from_db_string('2008-12-03 00:00:00').should == [2008, 12, 03]
      end

      it 'should split the date part of the string with "-" for grouping :week' do
        Kvlr::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string('2008-12-01 00:00:00').should == [2008, 49]
      end

    end

    describe 'for MySQL' do

      it 'should split the string with "/" for grouping :week' do
        ActiveRecord::Base.connection.stub!(:class).and_return(ActiveRecord::ConnectionAdapters::MysqlAdapter)
        db_string = '2008/2'
        expected = [2008, 2]

        Kvlr::ReportsAsSparkline::Grouping.new(:week).date_parts_from_db_string(db_string).should == expected
      end

    end

  end

end

class ActiveRecord::ConnectionAdapters::MysqlAdapter; end
class ActiveRecord::ConnectionAdapters::SQLite3Adapter; end
class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter; end
