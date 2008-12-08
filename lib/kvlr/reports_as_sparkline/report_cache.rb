module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base

      def self.cached_transaction(report, limit, no_cache = false, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        return yield(report.grouping.first_reporting_period(limit)) if no_cache
        self.transaction do
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
          last_reporting_period_to_read = if cached_data.empty? 
              report.grouping.first_reporting_period(limit)
            else
              report.grouping.to_reporting_period(cached_data.last.reporting_period)
            end
          new_data = yield(last_reporting_period_to_read)
          return update_cache(new_data, cached_data, report)
        end
      end

      private

        def self.update_cache(new_data, cached_data, report)
          rows_to_write = (0..-1)
          if cached_data.size > 0 && new_data.size > 0
            cached_data.last.update_attributes!(:value => new_data.first[1])
            rows_to_write = (1..-1)
          end
          for row in (new_data[rows_to_write] || [])
            self.create!(
              :model_name       => report.klass.to_s,
              :report_name      => report.name.to_s,
              :grouping         => report.grouping.identifier.to_s,
              :aggregation      => report.aggregation.to_s,
              :reporting_period => report.grouping.to_reporting_period(DateTime.parse(row[0])),
              :value            => row[1]
            )
          end
          result = cached_data.map { |cached| [cached.reporting_period, cached.value] }
          result += new_data.map { |data| [DateTime.parse(data[0]), data[1]] }
        end

    end

  end

end
