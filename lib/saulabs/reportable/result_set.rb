module Saulabs

  module Reportable

    # A result set as it is returned by the report methods.
    # This is basically a subclass of +Array+ that adds two
    # attributes, +model_class_name+ and +report_name+ that store
    # the name of the model and the report the result set
    # was generated from.
    #
    class ResultSet

      # the name of the model the result set is based on
      #
      attr_reader :model_class_name

      # the name of the report the result is based on
      #
      attr_reader :report_name

      # array representation of the result
      #
      def to_a
        @results
      end

      # Initializes a new result set.
      #
      # @param [Array] array
      #   the array that is the actual result
      # @param [String] model_class_name
      #   the name of the model the result set is based on
      # @param [String] report_name
      #   the name of the report the result is based on
      #
      def initialize(array, model_class_name, report_name)
        @results = array
        @model_class_name  = model_class_name
        @report_name = report_name.to_s
      end

    end

  end

end
