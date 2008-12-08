module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Grouping

      @@allowed_groupings = 

      def initialize(grouping)
        raise ArgumentError.new("Invalid grouping #{grouping}") unless [:hour, :day, :week, :month].include?(grouping)
        @identifier = grouping
      end

      def identifier
        @identifier.to_s
      end

      def to_reporting_period(date_time)
        return case @identifier
          when :hour
            DateTime.new(date_time.year, date_time.month, date_time.day, date_time.hour)
          when :day
            date_time.to_date
          when :week
            date_time = (date_time - date_time.wday.days) + 1
            Date.new(date_time.year, date_time.month, date_time.day)
          when :month
            Date.new(date_time.year, date_time.month)
        end
      end

      def first_reporting_period(limit)
        return case @identifier
          when :hour
            to_reporting_period(Time.now - limit.hours)
          when :day
            to_reporting_period(Time.now - limit.days)
          when :week
            to_reporting_period(Time.now - limit.weeks)
          when :month
            date = Time.now - limit.months
            Date.new(date.year, date.month, 1)
        end
      end

      def to_sql(date_column_name)
        return case ActiveRecord::Base.connection.class.to_s
          when 'ActiveRecord::ConnectionAdapters::MysqlAdapter'
            mysql_format(date_column_name)
          when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
            sqlite_format(date_column_name)
          when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
            postgresql_format(date_column_name)
        end
      end

      private

        def mysql_format(date_column_name)
          return case @identifier
            when :hour
              "DATE_FORMAT(#{date_column_name}, '%Y/%m/%d/%H')"
            when :day
              "DATE_FORMAT(#{date_column_name}, '%Y/%m/%d')"
            when :week
              "DATE_FORMAT(#{date_column_name}, '%Y-%u')"
            when :month
              "DATE_FORMAT(#{date_column_name}, '%Y/%m')"
          end
        end

        def sqlite_format(date_column_name)
          return case @identifier
            when :hour
              "strftime('%Y/%m/%d/%H', #{date_column_name})"
            when :day
              "strftime('%Y/%m/%d', #{date_column_name})"
            when :week
              "strftime('%Y-%W', #{date_column_name})"
            when :month
              "strftime('%Y/%m', #{date_column_name})"
          end
        end

        def postgresql_format(date_column_name)
          return case @identifier
            when :hour
              "date_trunc('hour', #{date_column_name})"
            when :day
              "date_trunc('day', #{date_column_name})"
            when :week
              "date_trunc('week', #{date_column_name})"
            when :month
              "date_trunc('month', #{date_column_name})"
          end
        end

    end

  end

end
