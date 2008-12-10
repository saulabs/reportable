module Simplabs

  module CoreExtensions

    module DateTime

      ::DateTime.class_eval do

        def to_reporting_period(grouping)
          Kvlr::ReportsAsSparkline::ReportsAsSparkline.new(grouping, self)
        end

      end

    end

  end

end
