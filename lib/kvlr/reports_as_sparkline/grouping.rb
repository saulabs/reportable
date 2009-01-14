module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # This is the grouping a report uses to group records in the database
    class Grouping

      # ==== Parameters
      # * <tt>identifier</tt> - The identifier of the grouping - one of :hour, :day, :week or :month
      def initialize(identifier)
        raise ArgumentError.new("Invalid grouping #{identifier}") unless [:hour, :day, :week, :month].include?(identifier)
        @identifier = identifier
      end

      # Returns the Grouping's identifier
      def identifier
        @identifier
      end

      def date_parts_from_db_string(db_string) #:nodoc:
        if ActiveRecord::Base.connection.class.to_s == 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
          case @identifier
            when :hour
              return (db_string[0..9].split('-') + [db_string[11..12]]).map(&:to_i)
            when :day
              return db_string[0..9].split('-').map(&:to_i)
            when :week
              parts = db_string[0..9].split('-').map(&:to_i)
              date = Date.new(parts[0], parts[1], parts[2])
              return [date.year, date.cweek]
            when :month
              return db_string[0..6].split('-')[0..1].map(&:to_i)
          end
        else
          parts = db_string.split('/').map(&:to_i)
          return parts if ActiveRecord::Base.connection.class.to_s == 'ActiveRecord::ConnectionAdapters::MysqlAdapter'
          if @identifier == :week && parts[1] > 52
            parts[0] += 1
            parts[1] = 1
          end
          parts
        end
      end

      def to_sql(date_column) #:nodoc:
        return case ActiveRecord::Base.connection.class.to_s
          when 'ActiveRecord::ConnectionAdapters::MysqlAdapter'
            mysql_format(date_column)
          when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
            sqlite_format(date_column)
          when 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
            postgresql_format(date_column)
        end
      end

      private

        def mysql_format(date_column)
          return case @identifier
            when :hour
              "DATE_FORMAT(#{date_column}, '%Y/%m/%d/%H')"
            when :day
              "DATE_FORMAT(#{date_column}, '%Y/%m/%d')"
            when :week
              "DATE_FORMAT(#{date_column}, '%Y/%u')"
            when :month
              "DATE_FORMAT(#{date_column}, '%Y/%m')"
          end
        end

        def sqlite_format(date_column)
          return case @identifier
            when :hour
              "strftime('%Y/%m/%d/%H', #{date_column})"
            when :day
              "strftime('%Y/%m/%d', #{date_column})"
            when :week
              "strftime('%Y/%W', #{date_column})"
            when :month
              "strftime('%Y/%m', #{date_column})"
          end
        end

        def postgresql_format(date_column)
          return case @identifier
            when :hour
              "date_trunc('hour', #{date_column})"
            when :day
              "date_trunc('day', #{date_column})"
            when :week
              "date_trunc('week', #{date_column})"
            when :month
              "date_trunc('month', #{date_column})"
          end
        end

    end

  end

end
