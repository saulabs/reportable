module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base

      def self.cached_transaction(report, grouping, limit, date_column_name, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        self.transaction do
          cached_data = self.find(
            :all,
            :conditions => { :model_name => report.klass.to_s, :report_name => report.name.to_s, :report_grouping => grouping.identifier.to_s },
            :limit => limit,
            :order => "#{date_column_name.to_s} DESC"
          )
          last_reporting_period_to_read = get_last_reporting_period(cached_data, grouping, grouping.first_reporting_period(limit))
          new_data = yield(last_reporting_period_to_read)
          return update_cache(new_data, cached_data, report, grouping)
        end
      end

      private

        def self.get_last_reporting_period(cached_data, grouping, acc)
          return acc if cached_data.empty?
          period = grouping.to_reporting_period(DateTime.parse(cached_data[0].reporting_period))
          cached_data[1..-2].each_with_index do |cached, i|
            if grouping.next_reporting_period(grouping.to_reporting_period(DateTime.parse(cached.reporting_period))) != grouping.to_reporting_period(DateTime.parse(cached_data[i + 1].reporting_period))
              return cached
            end
          end
          return grouping.to_reporting_period(DateTime.parse(cached_data[-1].reporting_period))
        end

        def self.update_cache(new_data, cached_data, report, grouping)
          rows_to_write = (0..-1)
          if cached_data.size > 0 && new_data.size > 0
            cached_data.last.update_attributes!(:value => new_data.first[1])
            rows_to_write = (1..-1)
          end
          for row in (new_data[rows_to_write] || [])
            self.create!(
              :model_name => report.klass.to_s,
              :report_name => report.name.to_s,
              :report_grouping => grouping.identifier.to_s,
              :reporting_period => grouping.to_reporting_period(DateTime.parse(row[0])),
              :value => row[1]
            )
          end
          result = cached_data.map { |cached| [Datetime.parse(cached.reporting_period), cached.value] }
          result += new_data.map { |data| [DateTime.parse(data[0]), data[1]] }
        end

    end

  end

end
