module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportingPeriod #:nodoc:

      attr_reader :date_time, :grouping

      def initialize(grouping, date_time = nil)
        @grouping  = grouping
        @date_time = parse_date_time(date_time || DateTime.now)
      end

      def offset(offset)
        self.class.new(@grouping, @date_time + offset.send(@grouping.identifier))
      end

      def self.first(grouping, limit, end_date = nil)
        self.new(grouping, end_date).offset(-limit)
      end

      def self.current(grouping)
        self.new(grouping, Time.now)
      end

      def self.from_db_string(grouping, db_string)
        parts = grouping.date_parts_from_db_string(db_string)
        result = case grouping.identifier
          when :hour
            self.new(grouping, DateTime.new(parts[0], parts[1], parts[2], parts[3], 0, 0))
          when :day
            self.new(grouping, Date.new(parts[0], parts[1], parts[2]))
          when :week
            self.new(grouping, Date.commercial(parts[0], parts[1], 1))
          when :month
            self.new(grouping, Date.new(parts[0], parts[1], 1))
        end
        result
      end

      def next
        self.offset(1)
      end

      def previous
        self.offset(-1)
      end

      def ==(other)
        if other.is_a?(Simplabs::ReportsAsSparkline::ReportingPeriod)
          @date_time.to_s == other.date_time.to_s && @grouping.identifier.to_s == other.grouping.identifier.to_s
        elsif other.is_a?(Time) || other.is_a?(DateTime)
          @date_time == parse_date_time(other)
        else
          raise ArgumentError.new("Can only compare instances of #{self.class.name}")
        end
      end

      def <(other)
        if other.is_a?(Simplabs::ReportsAsSparkline::ReportingPeriod)
          return @date_time < other.date_time
        elsif other.is_a?(Time) || other.is_a?(DateTime)
          @date_time < parse_date_time(other)
        else
          raise ArgumentError.new("Can only compare instances of #{self.class.name}")
        end
      end

      def last_date_time
        case @grouping.identifier
          when :hour
            DateTime.new(@date_time.year, @date_time.month, @date_time.day, @date_time.hour, 59, 59)
          when :day
            DateTime.new(@date_time.year, @date_time.month, @date_time.day, 23, 59, 59)
          when :week
            date_time = (@date_time - @date_time.wday.days) + 7.days
            Date.new(date_time.year, date_time.month, date_time.day)
          when :month
            Date.new(@date_time.year, @date_time.month, (Date.new(@date_time.year, 12, 31) << (12 - @date_time.month)).day)
        end
      end

      private

        def parse_date_time(date_time)
          case @grouping.identifier
            when :hour
              DateTime.new(date_time.year, date_time.month, date_time.day, date_time.hour)
            when :day
              date_time.to_date
            when :week
              date_time = (date_time - date_time.wday.days) + 1.day
              Date.new(date_time.year, date_time.month, date_time.day)
            when :month
              Date.new(date_time.year, date_time.month, 1)
          end
        end

    end

  end

end
