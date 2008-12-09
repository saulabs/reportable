module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Grouping

      def initialize(grouping)
        raise ArgumentError.new("Invalid grouping #{grouping}") unless [:hour, :day, :week, :month].include?(grouping)
        @identifier = grouping
      end

      def identifier
        @identifier
      end

      def date_parts_from_db_string(db_string)
        parts = db_string.split('/').map(&:to_i)
        if @identifier == :week
          parts[1] += 1
        end
        parts
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
              "DATE_FORMAT(#{date_column_name}, '%Y/%u')"
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
              "strftime('%Y/%W', #{date_column_name})"
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
