module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base

      serialize :reporting_period, Kvlr::ReportsAsSparkline::ReportingPeriod

      def self.process(report, limit, no_cache = false, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = if no_cache
              []
            else
              self.find(
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
            end
          last_reporting_period_to_read = if cached_data.empty?
              ReportingPeriod.first(report.grouping, limit)
            else
              cached_data.last.reporting_period
            end
          new_data = yield(last_reporting_period_to_read.date_time)
          update_cache(new_data, cached_data, last_reporting_period_to_read, report, no_cache)
        end
      end

      private

        def self.update_cache(new_data, cached_data, last_reporting_period_to_read, report, no_cache = false)
          new_data.map! { |data| [ReportingPeriod.from_db_string(report.grouping, data[0]), data[1]] }
          current_reporting_period = ReportingPeriod.new(report.grouping)
          reporting_period = current_reporting_period
          result = []
          begin
            data = new_data.detect { |data| data[0] == reporting_period }
            if data && cached = cached_data.detect { |cached| cached.reporting_period == data[0] }
              if no_cache
                cached.update_attributes!(:value => data[1])
              else
                cached.value = data[1]
              end
            else
              data = self.new(
                :model_name       => report.klass.to_s,
                :report_name      => report.name.to_s,
                :grouping         => report.grouping.identifier.to_s,
                :aggregation      => report.aggregation.to_s,
                :reporting_period => reporting_period,
                :value            => (data ? data[1] : 0)
              )
              data.save! unless no_cache
              data = [data.reporting_period, data.value]
            end
            result << data
            reporting_period = reporting_period.previous
          end while (reporting_period != last_reporting_period_to_read)
          result.map { |r| [r[0].date_time, r[1]] }
        end

    end

  end

end
