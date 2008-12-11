module Kvlr #:nodoc:

  module CoreExtensions #:nodoc:

    module DateTime

      ::DateTime.class_eval do

        # Converts the DateTime into a Kvlr::ReportsAsSparkline::ReportingPeriod
        def to_reporting_period(grouping)
          Kvlr::ReportsAsSparkline::ReportingPeriod.new(grouping, self)
        end

      end

    end

  end

end
