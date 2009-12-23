module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # The ReportCache class is a regular +ActiveRecord+ model and represents cached results for single reporting periods (table name is +reports_as_sparkline_cache+)
    # ReportCache instances are identified by the combination of +model_name+, +report_name+, +grouping+, +aggregation+ and +reporting_period+
    class ReportCache < ActiveRecord::Base

      set_table_name :reports_as_sparkline_cache

      self.skip_time_zone_conversion_for_attributes = [:reporting_period]

      # Clears the cache for the specified +klass+ and +report+
      #
      # === Parameters
      # * <tt>klass</tt> - The model the report to clear the cache for works on
      # * <tt>report</tt> - The name of the report to clear the cache for
      #
      # === Example
      # To clear the cache for a report defined as
      #  class User < ActiveRecord::Base
      #    reports_as_sparkline :registrations
      #  end
      # just do
      #  Simplabs::ReportsAsSparkline::ReportCache.clear_for(User, :registrations)
      def self.clear_for(klass, report)
        self.delete_all(:conditions => {
          :model_name  => klass.name,
          :report_name => report.to_s
        })
      end

      def self.process(report, options, &block) #:nodoc:
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = read_cached_data(report, options)
          new_data = read_new_data(cached_data, options, &block)
          prepare_result(new_data, cached_data, report, options)
        end
      end

      private

        def self.prepare_result(new_data, cached_data, report, options)
          new_data = new_data.map { |data| [ReportingPeriod.from_db_string(options[:grouping], data[0]), data[1]] }
          cached_data.map! { |cached| [ReportingPeriod.new(options[:grouping], cached.reporting_period), cached.value] }
          current_reporting_period = ReportingPeriod.current(options[:grouping])
          reporting_period = get_first_reporting_period(options)
          result = []
          while reporting_period < (options[:end_date] ? ReportingPeriod.new(options[:grouping], options[:end_date]).next : current_reporting_period)
            if cached = cached_data.find { |cached| reporting_period == cached[0] }
              result << [cached[0].date_time, cached[1]]
            else
              new_cached = build_cached_data(report, options[:grouping], options[:conditions], reporting_period, find_value(new_data, reporting_period))
              new_cached.save!
              result << [reporting_period.date_time, new_cached.value]
            end
            reporting_period = reporting_period.next
          end
          if options[:live_data]
            result << [current_reporting_period.date_time, find_value(new_data, current_reporting_period)]
          end
          result
        end

        def self.find_value(data, reporting_period)
          data = data.detect { |d| d[0] == reporting_period }
          data ? data[1] : 0.0
        end

        def self.build_cached_data(report, grouping, condition, reporting_period, value)
          self.new(
            :model_name       => report.klass.to_s,
            :report_name      => report.name.to_s,
            :grouping         => grouping.identifier.to_s,
            :aggregation      => report.aggregation.to_s,
            :condition        => condition.to_s,
            :reporting_period => reporting_period.date_time,
            :value            => value
          )
        end

        def self.read_cached_data(report, options)
          conditions = [
            'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND condition = ?',
            report.klass.to_s,
            report.name.to_s,
            options[:grouping].identifier.to_s,
            report.aggregation.to_s,
            options[:conditions].to_s
          ]
          first_reporting_period = get_first_reporting_period(options)
          last_reporting_period = get_last_reporting_period(options)
          if last_reporting_period
            conditions.first << ' AND reporting_period BETWEEN ? AND ?'
            conditions << first_reporting_period.date_time
            conditions << last_reporting_period.date_time
          else
            conditions.first << ' AND reporting_period >= ?'
            conditions << first_reporting_period.date_time
          end
          self.all(
            :conditions => conditions,
            :limit      => options[:limit],
            :order      => 'reporting_period ASC'
          )
        end

        def self.read_new_data(cached_data, options, &block)
          if !options[:live_data] && cached_data.length == options[:limit]
            []
          else
            first_reporting_period_to_read = if cached_data.length < options[:limit]
              get_first_reporting_period(options)
            else
              ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period).next
            end
            last_reporting_period_to_read = options[:end_date] ? ReportingPeriod.new(options[:grouping], options[:end_date]).last_date_time : nil
            yield(first_reporting_period_to_read.date_time, last_reporting_period_to_read)
          end
        end

        def self.get_first_reporting_period(options)
          if options[:end_date]
            ReportingPeriod.first(options[:grouping], options[:limit] - 1, options[:end_date])
          else
            ReportingPeriod.first(options[:grouping], options[:limit])
          end
        end

        def self.get_last_reporting_period(options)
          return ReportingPeriod.new(options[:grouping], options[:end_date]) if options[:end_date]
        end

    end

  end

end
