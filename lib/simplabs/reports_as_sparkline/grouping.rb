module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Grouping #:nodoc:

      def initialize(identifier)
        raise ArgumentError.new("Invalid grouping #{identifier}") unless [:hour, :day, :week, :month].include?(identifier)
        @identifier = identifier
      end

      def identifier
        @identifier
      end

      def date_parts_from_db_string(db_string)
        case ActiveRecord::Base.connection.adapter_name
          when /mysql/i
            from_mysql_db_string(db_string)
          when /sqlite/i
            from_sqlite_db_string(db_string)
          when /postgres/i
            from_postgresql_db_string(db_string)
        end
      end

      def to_sql(date_column) #:nodoc:
        case ActiveRecord::Base.connection.adapter_name
          when /mysql/i
            mysql_format(date_column)
          when /sqlite/i
            sqlite_format(date_column)
          when /postgres/i
            postgresql_format(date_column)
        end
      end

      private

        def from_mysql_db_string(db_string)
          if @identifier == :week
            parts = [db_string[0..3], db_string[4..5]].map(&:to_i)
          else
            db_string.split('/').map(&:to_i)
          end
        end

        def from_sqlite_db_string(db_string)
          if @identifier == :week
            parts = db_string.split('-').map(&:to_i)
            date = Date.new(parts[0], parts[1], parts[2])
            return [date.cwyear, date.cweek]
          end
          db_string.split('/').map(&:to_i)
        end

        def from_postgresql_db_string(db_string)
          case @identifier
            when :hour
              return (db_string[0..9].split('-') + [db_string[11..12]]).map(&:to_i)
            when :day
              return db_string[0..9].split('-').map(&:to_i)
            when :week
              parts = db_string[0..9].split('-').map(&:to_i)
              date = Date.new(parts[0], parts[1], parts[2])
              return [date.cwyear, date.cweek]
            when :month
              return db_string[0..6].split('-')[0..1].map(&:to_i)
          end
        end

        def mysql_format(date_column)
          case @identifier
            when :hour
              "DATE_FORMAT(#{date_column}, '%Y/%m/%d/%H')"
            when :day
              "DATE_FORMAT(#{date_column}, '%Y/%m/%d')"
            when :week
              "YEARWEEK(#{date_column}, 3)"
            when :month
              "DATE_FORMAT(#{date_column}, '%Y/%m')"
          end
        end

        def sqlite_format(date_column)
          case @identifier
            when :hour
              "strftime('%Y/%m/%d/%H', #{date_column})"
            when :day
              "strftime('%Y/%m/%d', #{date_column})"
            when :week
              "date(#{date_column}, 'weekday 0')"
            when :month
              "strftime('%Y/%m', #{date_column})"
          end
        end

        def postgresql_format(date_column)
          case @identifier
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
