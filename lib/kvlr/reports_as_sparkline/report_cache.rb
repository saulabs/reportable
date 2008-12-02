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
          last_reporting_period_to_read = get_last_reporting_period(cached_data, grouping)
          new_data = yield(last_reporting_period_to_read)
          #TODO: write new data
        end
        #TODO: combine data read from cache and newly read data and return
      end

      private

        def self.get_last_reporting_period(cached_data, grouping, acc = nil)
          acc ||= grouping.to_reporting_period(Time.now)
          return acc if cached_data.empty?
          acc = grouping.previous_reporting_period(acc)
          if cached_data.any? { |cache| cache.reporting_period == acc }
            return acc
          else
            self.get_last_reporting_period(cached_data, grouping, acc)
          end
        end

    end

  end

end
