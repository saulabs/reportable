module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base #:nodoc:

      def self.process(report, options, cache = true, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = []
          last_reporting_period_to_read = ReportingPeriod.first(options[:grouping], options[:limit])
          if cache
            cached_data = self.find(
              :all,
              :conditions => [
                'model_name = ? AND report_name = ? AND grouping = ? AND aggregation = ? AND reporting_period >= ?',
                report.klass.to_s,
                report.name.to_s,
                options[:grouping].identifier.to_s,
                report.aggregation.to_s,
                last_reporting_period_to_read.date_time
              ],
              :limit => options[:limit],
              :order => 'reporting_period ASC'
            )
            last_reporting_period_to_read = ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period).next unless cached_data.empty?
          end
          new_data = yield(last_reporting_period_to_read.date_time)
          prepare_result(new_data, cached_data, last_reporting_period_to_read, report, options[:grouping], cache)[0..(options[:limit] - 1)]
        end
      end

      private

        def self.prepare_result(new_data, cached_data, last_reporting_period_to_read, report, grouping, cache = true)
          new_data.map! { |data| [ReportingPeriod.from_db_string(grouping, data[0]), data[1]] }
          result = cached_data.map { |cached| [cached.reporting_period, cached.value] }
          current_reporting_period = ReportingPeriod.new(grouping)
          reporting_period = last_reporting_period_to_read
          while reporting_period < current_reporting_period
            cached = build_cached_data(report, grouping, reporting_period, find_value(new_data, reporting_period))
            cached.save! if cache
            result << [reporting_period.date_time, cached.value]
            reporting_period = reporting_period.next
          end
          result << [current_reporting_period.date_time, find_value(new_data, current_reporting_period)]
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

    end

  end

end
