module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportingPeriod

      attr_reader :date_time, :grouping

      def initialize(grouping, date_time = DateTime.now)
        @grouping  = grouping
        @date_time = parse_date_time(date_time)
      end

      def self.first(grouping, limit)
        return case grouping.identifier
          when :hour
            self.new(grouping, DateTime.now - limit.hours)
          when :day
            self.new(grouping, DateTime.now - limit.days)
          when :week
            self.new(grouping, DateTime.now - limit.weeks)
          when :month
            date = DateTime.now - limit.months
            self.new(grouping, Date.new(date.year, date.month, 1))
        end
      end

      def self.from_db_string(grouping, db_string) #:nodoc:
        parts = grouping.date_parts_from_db_string(db_string)
        result = case grouping.identifier
          when :hour
            self.new(grouping, DateTime.new(parts[0], parts[1], parts[2], parts[3], 0, 0))
          when :day
            self.new(grouping, Date.new(parts[0], parts[1], parts[2]))
          when :week
            self.new(grouping, Date.commercial(parts[0], parts[1]))
          when :month
            self.new(grouping, Date.new(parts[0], parts[1], 1))
        end
        result
      end

      def previous
        return case @grouping.identifier
          when :hour
            self.class.new(@grouping, @date_time - 1.hour)
          when :day
            self.class.new(@grouping, @date_time - 1.day)
          when :week
            self.class.new(@grouping, @date_time - 1.week)
          when :month
            self.class.new(@grouping, @date_time - 1.month)
        end
      end

      def ==(other) #:nodoc:
        if other.class == Kvlr::ReportsAsSparkline::ReportingPeriod
          return @date_time.to_s == other.date_time.to_s && @grouping.identifier.to_s == other.grouping.identifier.to_s
        end
        false
      end

      private

        def parse_date_time(date_time)
          return case @grouping.identifier
            when :hour
              DateTime.new(date_time.year, date_time.month, date_time.day, date_time.hour)
            when :day
              date_time.to_date
            when :week
              date_time = (date_time - date_time.wday.days) + 1
              Date.new(date_time.year, date_time.month, date_time.day)
            when :month
              Date.new(date_time.year, date_time.month, 1)
          end
        end

    end

  end

end
