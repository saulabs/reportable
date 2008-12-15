module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base #:nodoc:

      def self.process(report, limit, no_cache = false, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = []
          last_reporting_period_to_read = ReportingPeriod.first(report.grouping, limit)
          unless no_cache
            cached_data = self.find(
              :all,
              :conditions => {
                :model_name  => report.klass.to_s,
                :report_name => report.name.to_s,
                :grouping    => report.grouping.identifier.to_s,
                :aggregation => report.aggregation.to_s
              },
              :limit => limit,
              :order => 'reporting_period ASC'
            )
            last_reporting_period_to_read = ReportingPeriod.new(report.grouping, cached_data.last.reporting_period) unless cached_data.empty?
          end
          new_data = yield(last_reporting_period_to_read.date_time)
          prepare_result(new_data, cached_data, last_reporting_period_to_read, report, no_cache)[0..(limit - 1)]
        end
      end

      private

        def self.prepare_result(new_data, cached_data, last_reporting_period_to_read, report, no_cache = false)
          new_data.map! { |data| [ReportingPeriod.from_db_string(report.grouping, data[0]), data[1]] }
          result = []
          reporting_period = ReportingPeriod.new(report.grouping)
          while reporting_period != last_reporting_period_to_read
            data = new_data.detect { |data| data[0] == reporting_period }
            cached = self.new(
              :model_name       => report.klass.to_s,
              :report_name      => report.name.to_s,
              :grouping         => report.grouping.identifier.to_s,
              :aggregation      => report.aggregation.to_s,
              :reporting_period => reporting_period.date_time,
              :value            => (data ? data[1] : 0.0)
            )
            cached.save! unless no_cache
            result << [reporting_period.date_time, cached.value]
            reporting_period = reporting_period.previous
          end
          data = (new_data.first && new_data.first[0] == last_reporting_period_to_read) ? new_data.first : nil
          unless no_cache
            cached = cached_data.last || nil
            cached.update_attributes!(:value => data[1]) unless cached.nil? || data.nil?
          end
          result << [last_reporting_period_to_read.date_time, data ? data[1] : 0.0]
          result += (cached_data.map { |cached| [cached.reporting_period, cached.value] }).reverse
          result
        end

    end

  end

end
