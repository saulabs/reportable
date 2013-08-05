module Saulabs

  module Reportable

    # A reporting period is a specific hour or a specific day etc. depending on the used {Saulabs::Reportable::Grouping}.
    #
    class ReportingPeriod

      # The actual +DateTime the reporting period represents
      #
      attr_reader :date_time

      # The {Saulabs::Reportable::Grouping} of the reporting period
      #
      attr_reader :grouping

      # Initializes a new reporting period.
      #
      # @param [Saulabs::Reportable::Grouping] grouping
      #   the grouping the generate the reporting period for
      # @param [DateTime] date_time
      #   the +DateTime+ to generate the reporting period for
      #
      def initialize(grouping, date_time = nil)
        @grouping  = grouping
        @date_time = parse_date_time(date_time || DateTime.now)
      end

      # Gets a reporting period relative to the current one.
      #
      # @param [Fixnum] offset
      #   the offset to get the reporting period for
      #
      # @return [Saulabs::Reportable::ReportingPeriod]
      #   the reporting period relative by offset to the current one
      #
      # @example Getting the reporting period one week later
      #
      #   reporting_period = Saulabs::Reportable::ReportingPeriod.new(:week, DateTime.now)
      #   next_week = reporting_period.offset(1)
      #
      def offset(offset)
        self.class.new(@grouping, @date_time + offset.send(@grouping.identifier))
      end

      # Gets the first reporting period for a grouping and a limit (optionally relative to and end date).
      #
      # @param [Saulabs::ReportingPeriod::Grouping] grouping
      #   the grouping to get the first reporting period for
      # @param [Fixnum] limit
      #   the limit to get the first reporting period for
      # @param [DateTime] end_date
      #   the end date to get the first reporting period for (the first reporting period is then +end_date+ - +limit+ * +grouping+)
      #
      # @return [Saulabs::Reportable::ReportingPeriod]
      #   the first reporting period for the grouping, limit and optionally end date
      #
      def self.first(grouping, limit, end_date = nil)
        self.new(grouping, end_date).offset(-limit)
      end

      # Gets a reporting period from a DB date string.
      #
      # @param [Saulabs::Reportable::Grouping] grouping
      #   the grouping to get the reporting period for
      # @param [String] db_string
      #   the DB string to parse and get the reporting period for
      #
      # @return [Saulabs::Reportable::ReportingPeriod]
      #   the reporting period for the {Saulabs::Reportable::Grouping} as parsed from the db string
      #
      def self.from_db_string(grouping, db_string)
        return self.new(grouping, db_string) if db_string.is_a?(Date) || db_string.is_a?(Time)
        parts = grouping.date_parts_from_db_string(db_string.to_s)
        case grouping.identifier
          when :hour
            self.new(grouping, DateTime.new(parts[0], parts[1], parts[2], parts[3], 0, 0))
          when :day
            self.new(grouping, Date.new(parts[0], parts[1], parts[2]))
          when :week
            self.new(grouping, Date.commercial(parts[0], parts[1], 1))
          when :month
            self.new(grouping, Date.new(parts[0], parts[1], 1))
        end
      end

      # Gets the next reporting period.
      #
      # @return [Saulabs::Reportable::ReportingPeriod]
      #   the reporting period after the current one
      #
      def next
        self.offset(1)
      end

      # Gets the previous reporting period.
      #
      # @return [Saulabs::Reportable::ReportingPeriod]
      #   the reporting period before the current one
      #
      def previous
        self.offset(-1)
      end

      # Gets whether the reporting period +other+ is equal to the current one.
      #
      # @param [Saulabs::Reportable::ReportingPeriod] other
      #   the reporting period to check for whether it is equal to the current one
      #
      # @return [Boolean]
      #   true if +other+ is equal to the current reporting period, false otherwise
      #
      def ==(other)
        if other.is_a?(Saulabs::Reportable::ReportingPeriod)
          @date_time == other.date_time && @grouping.identifier == other.grouping.identifier
        elsif other.is_a?(Time) || other.is_a?(DateTime)
          @date_time == parse_date_time(other)
        else
          raise ArgumentError.new("Can only compare instances of #{self.class.name}")
        end
      end

      # Gets whether the reporting period +other+ is smaller to the current one.
      #
      # @param [Saulabs::Reportable::ReportingPeriod] other
      #   the reporting period to check for whether it is smaller to the current one
      #
      # @return [Boolean]
      #   true if +other+ is smaller to the current reporting period, false otherwise
      #
      def <(other)
        if other.is_a?(Saulabs::Reportable::ReportingPeriod)
          return @date_time < other.date_time
        elsif other.is_a?(Time) || other.is_a?(DateTime)
          @date_time < parse_date_time(other)
        else
          raise ArgumentError.new("Can only compare instances of #{self.class.name}")
        end
      end

      # Gets the latest point in time that is included the reporting period. The latest point in time included in a reporting period
      # for grouping hour would be that hour and 59 minutes and 59 seconds.
      #
      # @return [DateTime]
      #   the latest point in time that is included in the reporting period
      #
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
