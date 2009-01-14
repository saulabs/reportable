module Kvlr #:nodoc:

  module CoreExtensions #:nodoc:

    module DateTime

      ::DateTime.class_eval do

        # Converts the DateTime into a Kvlr::ReportsAsSparkline::ReportingPeriod
        def to_reporting_period(grouping)
          if grouping.is_a?(Symbol)
            grouping = Kvlr::ReportsAsSparkline::Grouping.new(grouping)
          elsif !grouping.is_a?(Kvlr::ReportsAsSparkline::Grouping)
            raise ArgumentError.new('grouping must be either an instance of Kvlr::ReportsAsSparkline::Grouping or a symbol.')
          end
          Kvlr::ReportsAsSparkline::ReportingPeriod.new(grouping, self)
        end

      end

    end

  end

end
