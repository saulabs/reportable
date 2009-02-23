module Kvlr #:nodoc:

  module ReportsAsSparkline

    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      # Generates a report on a model. That report can then be executed via the new method <name>_report (see documentation of Kvlr::ReportsAsSparkline::Report#run).
      # 
      # ==== Parameters
      #
      # * <tt>name</tt> - The name of the report, defines the name of the generated report method (<name>_report)
      #
      # ==== Options
      #
      # * <tt>:date_column</tt> - The name of the date column on that the records are aggregated
      # * <tt>:value_column</tt> - The name of the column that holds the value to sum for aggregation :sum
      # * <tt>:aggregation</tt> - The aggregation to use (one of :count, :sum, :minimum, :maximum or :average); when using anything other than :count, :value_column must also be specified (<b>If you really want to e.g. sumon the 'id' column, you have to explicitely say so.</b>)
      # * <tt>:grouping</tt> - The period records are grouped on (:hour, :day, :week, :month); <b>Beware that reports_as_sparkline treats weeks as starting on monday!</b>
      # * <tt>:limit</tt> - The number of periods to get (see :grouping)
      # * <tt>:conditions</tt> - Conditions like in ActiveRecord::Base#find; only records that match there conditions are reported on
      # * <tt>:live_data</tt> - Specified whether data for the current reporting period is read; if :live_data is true, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to false)
      #
      # ==== Examples
      #
      #  class Game < ActiveRecord::Base
      #    reports_as_sparkline :games_per_day
      #    reports_as_sparkline :games_played_total, :cumulate => true
      #  end
      #  class User < ActiveRecord::Base
      #    reports_as_sparkline :registrations, :aggregation => :count
      #    reports_as_sparkline :activations,   :aggregation => :count, :date_column => :activated_at
      #    reports_as_sparkline :total_users,   :cumulate => true
      #    reports_as_sparkline :rake,          :aggregation => :sum,   :value_column => :profile_visits
      #  end
      def reports_as_sparkline(name, options = {})
        (class << self; self; end).instance_eval do
          define_method "#{name.to_s}_report".to_sym do |*args|
            if options.delete(:cumulate)
              report = Kvlr::ReportsAsSparkline::CumulatedReport.new(self, name, options)
            else
              report = Kvlr::ReportsAsSparkline::Report.new(self, name, options)
            end
            raise ArgumentError.new unless args.length == 0 || (args.length == 1 && args[0].is_a?(Hash))
            report.run(args.length == 0 ? {} : args[0])
          end
        end
      end

    end

  end

end
