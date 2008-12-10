module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class CumulatedReport < Report

      def run(options = {})
        cumulate(super)
      end

      protected

        def cumulate(data)
          acc = 0.0
          result = []
          data.reverse_each do |element|
            acc += element[1].to_f
            result << [element[0], acc]
          end
          result.reverse
        end

    end

  end

end
