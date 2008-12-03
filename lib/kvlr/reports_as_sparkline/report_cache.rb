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
          write_to_cache(new_data, report, grouping)
          return cached_data + new_data
        end
      end

      private

        def self.get_last_reporting_period(cached_data, grouping, acc)
          return acc if cached_data.empty?
          if cached_data.any? { |cache| cache.reporting_period == acc } && !cached_data.any? { |cache| cache.reporting_period == grouping.next_reporting_period(acc) }
            return acc
          else
            self.get_last_reporting_period(cached_data, grouping, grouping.next_reporting_period(acc))
          end
        end

        def self.write_to_cache(data, report, grouping)
          for row in data
            cached = self.find(:first, :conditions => {
              :model_name       => report.klass.to_s,
              :report_name      => report.name.to_s,
              :report_grouping  => grouping.identifier.to_s,
              :reporting_period => grouping.to_reporting_period(DateTime.parse(row[0]))
            })
            if cached
              cached.update_attributes!(:value => row[1])
            else
              self.create!(
                :model_name       => report.klass.to_s,
                :report_name      => report.name.to_s,
                :report_grouping  => grouping.identifier.to_s,
                :reporting_period => grouping.to_reporting_period(DateTime.parse(row[0])),
                :value            => row[1]
              )
            end
          end
        end

    end

  end

end
