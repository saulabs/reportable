module Simplabs #:nodoc:

  module ReportsAsSparkline

    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods

      # Generates a report on a model. That report can then be executed via the new method <tt><name>_report</tt> (see documentation of Simplabs::ReportsAsSparkline::Report#run).
      # 
      # ==== Parameters
      #
      # * <tt>name</tt> - The name of the report, defines the name of the generated report method (<tt><name>_report</tt>)
      #
      # ==== Options
      #
      # * <tt>:date_column</tt> - The name of the date column over that the records are aggregated (defaults to <tt>created_at</tt>)
      # * <tt>:value_column</tt> - The name of the column that holds the values to sum up when using aggregation <tt>:sum</tt>
      # * <tt>:aggregation</tt> - The aggregation to use (one of <tt>:count</tt>, <tt>:sum</tt>, <tt>:minimum</tt>, <tt>:maximum</tt> or <tt>:average</tt>); when using anything other than <tt>:count</tt>, <tt>:value_column</tt> must also be specified (<b>If you really want to e.g. sum up the values in the <tt>id</tt> column, you have to explicitely say so.</b>); (defaults to <tt>:count</tt>)
      # * <tt>:grouping</tt> - The period records are grouped on (<tt>:hour</tt>, <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt>); <b>Beware that <tt>reports_as_sparkline</tt> treats weeks as starting on monday!</b>
      # * <tt>:limit</tt> - The number of reporting periods to get (see <tt>:grouping</tt>), (defaults to 100)
      # * <tt>:conditions</tt> - Conditions like in <tt>ActiveRecord::Base#find</tt>; only records that match the conditions are reported; <b>Beware that when conditions are specified, caching is disabled!</b>
      # * <tt>:live_data</tt> - Specifies whether data for the current reporting period is to be read; <b>if <tt>:live_data</tt> is <tt>true</tt>, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to <tt>false</tt>)</b>
      # * <tt>:end_date</tt> - When specified, the report will only include data for the <tt>:limit</tt> reporting periods until this date.
      #
      # ==== Examples
      #
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
              report = Simplabs::ReportsAsSparkline::CumulatedReport.new(self, name, options)
            else
              report = Simplabs::ReportsAsSparkline::Report.new(self, name, options)
            end
            raise ArgumentError.new unless args.length == 0 || (args.length == 1 && args[0].is_a?(Hash))
            report.run(args.length == 0 ? {} : args[0])
          end
        end
      end

    end

  end

end
