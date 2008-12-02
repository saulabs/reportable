module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class CumulatedReport < Report

      def run(options = {})
        CumulatedReport.cumulate!(super)
      end

      protected

        def self.cumulate!(data)
          acc = 0
          data.collect do |element|
            acc += element[1].to_i
            [element[0], acc]
          end
        end

    end

  end

end
