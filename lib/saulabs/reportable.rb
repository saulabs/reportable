module Saulabs

  module Reportable

    # Includes the {Saulabs::Reportable.reportable} method into +base+.
    #
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods

      # Generates a report on a model. That report can then be executed via the new method +<name>_report+ (see documentation of {Saulabs::Reportable::Report#run}).
      # 
      # @param [String] name
      #   the name of the report, also defines the name of the generated report method (+<name>_report+)
      # @param [Hash] options
      #   the options to generate the reports with
      #
      # @option options [Symbol] :date_column (created_at)
      #   the name of the date column over that the records are aggregated
      # @option options [String, Symbol] :value_column (:id)
      #   the name of the column that holds the values to aggregate when using a calculation aggregation like +:sum+
      # @option options [Symbol] :aggregation (:count)
      #   the aggregation to use (one of +:count+, +:sum+, +:minimum+, +:maximum+ or +:average+); when using anything other than +:count+, +:value_column+ must also be specified
      # @option options [Symbol] :grouping (:day)
      #   the period records are grouped in (+:hour+, +:day+, +:week+, +:month+); <b>Beware that <tt>reportable</tt> treats weeks as starting on monday!</b>
      # @option options [Fixnum] :limit (100)
      #   the number of reporting periods to get (see +:grouping+)
      # @option options [Hash] :conditions ({})
      #   conditions like in +ActiveRecord::Base#find+; only records that match these conditions are reported;
      # @option options [Boolean] :live_data (false)
      #   specifies whether data for the current reporting period is to be read; <b>if +:live_data+ is +true+, you will experience a performance hit since the request cannot be satisfied from the cache alone</b>
      # @option options [DateTime, Boolean] :end_date (false)
      #   when specified, the report will only include data for the +:limit+ reporting periods until this date.
      #
      # @example Declaring reports on a model
      #
      #  class User < ActiveRecord::Base
      #    reportable :registrations, :aggregation => :count
      #    reportable :activations,   :aggregation => :count, :date_column => :activated_at
      #    reportable :total_users,   :cumulate => true
      #    reportable :rake,          :aggregation => :sum,   :value_column => :profile_visits
      #  end
      def reportable(name, options = {})
        (class << self; self; end).instance_eval do
          define_method "#{name.to_s}_report".to_sym do |*args|
            if options.delete(:cumulate)
              report = Saulabs::Reportable::CumulatedReport.new(self, name, options)
            else
              report = Saulabs::Reportable::Report.new(self, name, options)
            end
            raise ArgumentError.new unless args.length == 0 || (args.length == 1 && args[0].is_a?(Hash))
            report.run(args.length == 0 ? {} : args[0])
          end
        end
      end

    end

  end

end
