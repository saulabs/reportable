module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base #:nodoc:

      def self.process(report, options, cache = true, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = []
          first_reporting_period = ReportingPeriod.first(options[:grouping], options[:limit])
          if cache
            cached_data = find_cached_data(report, options, first_reporting_period)
            last_cached_reporting_period = (ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period.date_time) rescue nil)
          end
          new_data = if !options[:live_data] && last_cached_reporting_period == ReportingPeriod.new(options[:grouping]).previous
            []
          else
            yield((last_cached_reporting_period.next rescue first_reporting_period).date_time)
          end
          prepare_result(new_data, cached_data, report, options, cache)
        end
      end

      private

        def self.prepare_result(new_data, cached_data, report, options, cache = true)
          new_data.map! { |data| [ReportingPeriod.from_db_string(options[:grouping], data[0]), data[1]] }
          result = cached_data.map { |cached| [cached.reporting_period, cached.value] }
          current_reporting_period = ReportingPeriod.new(options[:grouping])
          reporting_period = (cached_data.last.reporting_period.next rescue ReportingPeriod.first(options[:grouping], options[:limit]))
          while reporting_period < current_reporting_period
            cached = build_cached_data(report, options[:grouping], reporting_period, find_value(new_data, reporting_period))
            cached.save! if cache
            result << [reporting_period.date_time, cached.value]
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

        def self.build_cached_data(report, grouping, reporting_period, value)
          self.new(
            :model_name       => report.klass.to_s,
            :report_name      => report.name.to_s,
            :grouping         => grouping.identifier.to_s,
            :aggregation      => report.aggregation.to_s,
            :reporting_period => reporting_period.date_time,
            :value            => value
          )
        end

        def self.find_cached_data(report, options, first_reporting_period)
          self.find(
            :all,
            :conditions => [
              'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND reporting_period >= ?',
              report.klass.to_s,
              report.name.to_s,
              options[:grouping].identifier.to_s,
              report.aggregation.to_s,
              first_reporting_period.date_time
            ],
            :limit => options[:limit],
            :order => 'reporting_period ASC'
          )
        end

    end

  end

end
