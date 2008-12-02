module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Grouping

      attr_reader :identifier

      @@allowed_groupings = [:month, :week, :day, :hour]

      def initialize(grouping)
        raise ArgumentError.new("Argument grouping must be one of #{@@allowed_groupings.map(&:to_s).join(', ')}") unless @@allowed_groupings.include?(grouping)
        @grouping = grouping
      end

      def to_reporting_period(date_time)
        return case @grouping
          when :day
            date_time.to_date
          when :week
            date_time = (date_time - date_time.wday.days) + 1
            Date.new(date_time.year, date_time.month, date_time.day)
          when :month
            Date.new(date_time.year, date_time.month)
          when :hour
            DateTime.new(date_time.year, date_time.month, date_time.day, date_time.hour)
          end
      end

      def previous_reporting_period(period)
        return case @grouping
          when :day
            period - 1.day
          when :week
            period - 1.week
          when :month
            period -= 1.month
            Date.new(period.year, period.month, 1)
          when :hour
            period - 1.hour
          end
      end

      def to_sql(date_column_name)
        #TODO: DATE_FORMAT's format string is different on different RDBMs => custom format string for all supported RDBMs needed!
        # => this can be implemented using ActiveRecord::Base.connection.class
        return case @grouping
          when :day
            "DATE_FORMAT(#{date_column_name}, '%Y/%m/%d')"
          when :week
            "DATE_FORMAT(#{date_column_name}, '%Y-%u')"
          when :month
            "DATE_FORMAT(#{date_column_name}, '%Y/%m')"
          when :hour
            "DATE_FORMAT(#{date_column_name}, '%Y/%m/%d/%H')"
          end
      end

    end

  end

end
