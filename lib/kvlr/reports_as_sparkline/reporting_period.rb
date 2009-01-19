module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # A ReportingPeriod is  - depending on the Grouping - either a specific hour, a day, a month or a year. All records falling into this period will be grouped together.
    class ReportingPeriod

      attr_reader :date_time, :grouping

      # ==== Parameters
      # * <tt>grouping</tt> - The Kvlr::ReportsAsSparkline::Grouping of the reporting period
      # * <tt>date_time</tt> - The DateTime that reporting period is created for
      def initialize(grouping, date_time = DateTime.now)
        @grouping  = grouping
        @date_time = parse_date_time(date_time)
      end

      # Returns the first reporting period for a grouping and a limit; e.g. the first reporting period for Grouping :day and limit 2 would be Time.now - 1.days
      # (since limit is 2, 2 reporting periods are included in the range, that is yesterday and today)
      #
      # ==== Parameters
      # * <tt>grouping</tt> - The Kvlr::ReportsAsSparkline::Grouping of the reporting period
      # * <tt>limit</tt> - The number of reporting periods until the first one
      def self.first(grouping, limit)
        return case grouping.identifier
          when :hour
            self.new(grouping, DateTime.now - (limit - 1).hours)
          when :day
            self.new(grouping, DateTime.now - (limit - 1).days)
          when :week
            self.new(grouping, DateTime.now - (limit - 1).weeks)
          when :month
            date = DateTime.now - (limit - 1).months
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
            self.new(grouping, Date.commercial(parts[0], parts[1], 1))
          when :month
            self.new(grouping, Date.new(parts[0], parts[1], 1))
        end
        result
      end

      # Returns the next reporting period (that is next hour/day/month/year)
      def next
        return case @grouping.identifier
          when :hour
            self.class.new(@grouping, @date_time + 1.hour)
          when :day
            self.class.new(@grouping, @date_time + 1.day)
          when :week
            self.class.new(@grouping, @date_time + 1.week)
          when :month
            self.class.new(@grouping, @date_time + 1.month)
        end
      end

      # Returns the previous reporting period (that is next hour/day/month/year)
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

      def <(other) #:nodoc:
        if other.class == Kvlr::ReportsAsSparkline::ReportingPeriod
          return @date_time < other.date_time
        end
        raise ArgumentError.new("Can only compare instances of #{Kvlr::ReportsAsSparkline::ReportingPeriod.klass}")
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
