require 'saulabs/reportable/report'

module Saulabs

  module Reportable

    # A special report class that cumulates all data (see {Saulabs::Reportable::Report})
    #
    # @example Cumulated reports as opposed to regular reports
    #
    #  [[<DateTime today>, 1], [<DateTime yesterday>, 2], [<DateTime two days ago>, 4], etc.] # result of a regular report 
    #  [[<DateTime today>, 7], [<DateTime yesterday>, 6], [<DateTime two days ago>, 4], etc.] # result of a cumulated report for the same dataset
    #
    class CumulatedReport < Report

      # Runs the report (see {Saulabs::Reportable::Report#run})
      #
      def run(options = {})
        cumulate(super, options_for_run(options))
      end

      private

        def cumulate(data, options)
          first_reporting_period = ReportingPeriod.first(options[:grouping], options[:limit], options[:end_date])
          acc = initial_cumulative_value(first_reporting_period.date_time, options)
          result = []
          data.to_a.each do |element|
            acc += element[1].to_f
            result << [element[0], acc]
          end
          result
        end

        def initial_cumulative_value(date, options)
          conditions = setup_conditions(nil, date, options[:conditions])
          @klass.where(conditions).calculate(@aggregation, @value_column)
        end

    end

  end

end
