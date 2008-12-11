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
        cumulate(super)
      end

      protected

        def cumulate(data) #:nodoc:
          acc = 0.0
          result = []
          data.reverse_each do |element|
            acc += element[1].to_f
            result << [element[0], acc]
          end
          result.reverse!
          result
        end

    end

  end

end
