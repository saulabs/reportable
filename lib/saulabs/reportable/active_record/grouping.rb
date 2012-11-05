module Saulabs
  module Reportable
    module ActiveRecord
      # The grouping specifies which records are grouped into one {Saulabs::Reportable::ReportingPeriod}.
      #
      class Grouping
        # Initializes a new grouping.
        #
        # @param [Symbol] identifier
        #   the identifier of the grouping (one of +:hour+, +:day+, +:week+ or +:month+)
        #
        def initialize(identifier)
          raise ArgumentError.new("Invalid grouping #{identifier}") unless [:hour, :day, :week, :month].include?(identifier)
          @identifier = identifier
        end

        # Gets the identifier of the grouping.
        #
        # @return [Symbol]
        #   the identifier of the grouping.
        #
        def identifier
          @identifier
        end

        # Gets an array of date parts from a DB string.
        #
        # @param [String] db_string
        #   the DB string to get the date parts from
        #
        # @return [Array<Fixnum>]
        #   array of numbers that represent the values of the date
        #
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

        # Converts the grouping into a DB specific string that can be used to group records.
        #
        # @param [String] date_column
        #   the name of the DB column that holds the date
        #
        def to_sql(date_column)
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
              db_string.split(@identifier == :day ? '-' : '/').map(&:to_i)
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
                "DATE(#{date_column})"
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
end
