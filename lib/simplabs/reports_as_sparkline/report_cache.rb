module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base #:nodoc:

      set_table_name :reports_as_sparkline_cache

      def self.process(report, options, cache = true, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = []
          first_reporting_period = ReportingPeriod.first(options[:grouping], options[:limit], options[:end_date])
          last_reporting_period = options[:end_date] ? ReportingPeriod.new(options[:grouping], options[:end_date]) : nil

          if cache
            cached_data = find_cached_data(report, options, first_reporting_period, last_reporting_period)
            first_cached_reporting_period = cached_data.empty? ? nil : ReportingPeriod.new(options[:grouping], cached_data.first.reporting_period)
            last_cached_reporting_period = cached_data.empty? ? nil : ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period)
          end

          new_data = if !options[:live_data] && last_cached_reporting_period == ReportingPeriod.new(options[:grouping]).previous
            []
          else
            end_date = options[:live_data] ? nil : last_reporting_period && last_reporting_period.date_time
            yield((last_cached_reporting_period.next rescue first_reporting_period).date_time, end_date)
          end

          prepare_result(new_data, cached_data, report, options, cache)
        end
      end

      private

        def self.prepare_result(new_data, cached_data, report, options, cache = true)
          new_data = new_data.map { |data| [ReportingPeriod.from_db_string(options[:grouping], data[0]), data[1]] }
          result = cached_data.map { |cached| [cached.reporting_period, cached.value] }
          last_reporting_period = ReportingPeriod.new(options[:grouping], options[:end_date])
          reporting_period = cached_data.empty? ? ReportingPeriod.first(options[:grouping], options[:limit], options[:end_date]) : ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period).next
          while reporting_period < last_reporting_period
            cached = build_cached_data(report, options[:grouping], options[:limit], reporting_period, find_value(new_data, reporting_period))
            cached.save! if cache
            result << [reporting_period.date_time, cached.value]
            reporting_period = reporting_period.next
          end
          if options[:live_data]
            result << [last_reporting_period.date_time, find_value(new_data, last_reporting_period)]
          end
          result
        end

        def self.find_value(data, reporting_period)
          data = data.detect { |d| d[0] == reporting_period }
          data ? data[1] : 0.0
        end

        def self.build_cached_data(report, grouping, limit, reporting_period, value)
          self.new(
            :model_name       => report.klass.to_s,
            :report_name      => report.name.to_s,
            :grouping         => grouping.identifier.to_s,
            :aggregation      => report.aggregation.to_s,
            :reporting_period => reporting_period.date_time,
            :value            => value,
            :run_limit        => limit
          )
        end

        def self.find_cached_data(report, options, first_reporting_period, last_reporting_period)
          conditions = [
            'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND run_limit = ?',
            report.klass.to_s,
            report.name.to_s,
            options[:grouping].identifier.to_s,
            report.aggregation.to_s,
            options[:limit]
          ]
          if last_reporting_period
            conditions.first << ' AND reporting_period BETWEEN ? AND ?'
            conditions << first_reporting_period.date_time
            conditions << last_reporting_period.date_time
          else
            conditions.first << ' AND reporting_period >= ?'
            conditions << first_reporting_period.date_time
          end
          self.find(
            :all,
            :conditions => conditions,
            :limit => options[:limit],
            :order => 'reporting_period ASC'
          )
        end

    end

  end

end
