module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base

      serialize :reporting_period, Kvlr::ReportsAsSparkline::ReportingPeriod

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
              :order => 'reporting_period DESC'
            )
            last_reporting_period_to_read = cached_data.last.reporting_period unless cached_data.empty?
          end
          new_data = yield(last_reporting_period_to_read.date_time)
          prepare_result(new_data, cached_data, last_reporting_period_to_read, report, no_cache)
        end
      end

      private

        def self.prepare_result(new_data, cached_data, last_reporting_period_to_read, report, no_cache = false)
          new_data.map! { |data| [ReportingPeriod.from_db_string(report.grouping, data[0]), data[1]] }
          reporting_period = ReportingPeriod.new(report.grouping)
          result = []
          begin
            data = new_data.detect { |data| data[0] == reporting_period }
            cached = self.new(
              :model_name       => report.klass.to_s,
              :report_name      => report.name.to_s,
              :grouping         => report.grouping.identifier.to_s,
              :aggregation      => report.aggregation.to_s,
              :reporting_period => reporting_period,
              :value            => (data ? data[1] : 0)
            )
            cached.save! unless no_cache
            result << [cached.reporting_period.date_time, cached.value]
            reporting_period = reporting_period.previous
          end while reporting_period != last_reporting_period_to_read
          unless no_cache
            cached = cached_data.last || nil
            data = (new_data.first && new_data.first[0] == last_reporting_period_to_read) ? new_data.first : nil
            cached.update_attributes!(:value => data[1]) unless cached.nil? || data.nil?
          end
          result
        end

    end

  end

end
