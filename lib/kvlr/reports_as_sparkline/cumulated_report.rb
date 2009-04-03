module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # A special report class that cumulates all data (see Kvlr::ReportsAsSparkline::Report)
    #
    # ==== Examples
    #
    #  When Kvlr::ReportsAsSparkline::Report returns
    #
    #    [[<DateTime today>, 1], [<DateTime yesterday>, 2], etc.]
    #
    #  Kvlr::ReportsAsSparkline::CumulatedReport returns
    #
    #    [[<DateTime today>, 3], [<DateTime yesterday>, 2], etc.]
    class CumulatedReport < Report

      # Runs the report (see Kvlr::ReportsAsSparkline::Report#run)
      def run(options = {})
        cumulate(super, options_for_run(options))
      end

      protected

        def cumulate(data, options) #:nodoc:
          first_reporting_period = ReportingPeriod.first(options[:grouping], options[:limit], options[:end_date])
          acc = initial_cumulative_value(first_reporting_period.date_time, options)
          result = []
          data.each do |element|
            acc += element[1].to_f
            result << [element[0], acc]
          end
          result
        end

        def initial_cumulative_value(date, options)
          conditions = setup_conditions(nil, date, options[:conditions])
          @klass.send(@aggregation, @value_column, :conditions => conditions)
        end

    end

  end

end
