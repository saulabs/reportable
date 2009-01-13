module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # The Report class that does all the data retrieval and calculations
    class Report

      attr_reader :klass, :name, :date_column, :value_column, :aggregation, :options

      # ==== Parameters
      # * <tt>klass</tt> - The model the report works on (This is the class you invoke Kvlr::ReportsAsSparkline::ClassMethods#reports_as_sparkline on)
      # * <tt>name</tt> - The name of the report (as in Kvlr::ReportsAsSparkline::ClassMethods#reports_as_sparkline)
      #
      # ==== Options
      #
      # * <tt>:date_column</tt> - The name of the date column on that the records are aggregated
      # * <tt>:value_column</tt> - The name of the column that holds the value to sum for aggregation :sum
      # * <tt>:aggregation</tt> - The aggregation to use (either :count or :sum); when using :sum, :value_column must also be specified
      # * <tt>:grouping</tt> - The period records are grouped on (:hour, :day, :week, :month)
      # * <tt>:limit</tt> - The number of periods to get (see :grouping)
      # * <tt>:conditions</tt> - Conditions like in ActiveRecord::Base#find; only records that match there conditions are reported on
      def initialize(klass, name, options = {})
        ensure_valid_options(options)
        @klass        = klass
        @name         = name
        @date_column  = (options[:date_column] || 'created_at').to_s
        @value_column = (options[:value_column] || (options[:aggregation] != :sum ? 'id' : name)).to_s
        @aggregation  = options[:aggregation] || :count
        @options = {
          :limit      => options[:limit] || 100,
          :conditions => options[:conditions] || [],
          :grouping   => Grouping.new(options[:grouping] || :day)
        }
        @options.merge!(options)
        @options.freeze
      end

      # Runs the report and returns an array of array of DateTimes and Floats
      #
      # ==== Options
      # * <tt>:limit</tt> - The number of periods to get
      # * <tt>:conditions</tt> - Conditions like in ActiveRecord::Base#find; only records that match there conditions are reported on (<b>Beware that when you specify conditions here, caching will be disabled</b>)
      # * <tt>:grouping</tt> - The period records are grouped on (:hour, :day, :week, :month)
      def run(options = {})
        ensure_valid_options(options, :run)
        custom_conditions = options.key?(:conditions)
        options.reverse_merge!(@options)
        options[:grouping] = Grouping.new(options[:grouping]) unless options[:grouping].is_a?(Grouping)
        ReportCache.process(self, options[:limit], options[:grouping], custom_conditions) do |begin_at|
          read_data(begin_at, options[:grouping], options[:conditions])
        end
      end

      private

        def read_data(begin_at, grouping, conditions = []) #:nodoc:
          conditions = setup_conditions(begin_at, conditions)
          @klass.send(@aggregation,
            @value_column,
            :conditions => conditions,
            :group => grouping.to_sql(@date_column),
            :order => "#{grouping.to_sql(@date_column)} ASC"
          )
        end

        def setup_conditions(begin_at, custom_conditions = []) #:nodoc:
          conditions = ['']
          if custom_conditions.is_a?(Hash)
            conditions = [custom_conditions.map{ |k, v| "#{k.to_s} = ?" }.join(' AND '), *custom_conditions.map{ |k, v| v }]
          elsif custom_conditions.size > 0
            conditions = [(custom_conditions[0] || ''), *custom_conditions[1..-1]]
          end
          conditions[0] += "#{(conditions[0].blank? ? '' : ' AND ') + @date_column.to_s} >= ?"
          conditions << begin_at
        end

        def ensure_valid_options(options, context = :initialize) #:nodoc:
          case context
            when :initialize
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :aggregation, :grouping, :date_column, :value_column, :conditions].include?(k)
              end
              raise ArgumentError.new("Invalid aggregation #{options[:aggregation]}") if options[:aggregation] && ![:count, :sum].include?(options[:aggregation])
              raise ArgumentError.new('The name of the column holding the value to sum has to be specified for aggregation :sum') if options[:aggregation] == :sum && !options.key?(:value_column)
            when :run
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :conditions, :grouping].include?(k)
              end
          end
          raise ArgumentError.new("Invalid grouping #{options[:grouping]}") if options[:grouping] && ![:hour, :day, :week, :month].include?(options[:grouping])
          raise ArgumentError.new("Invalid conditions: #{options[:conditions].inspect}") if options[:conditions] && !options[:conditions].is_a?(Array) && !options[:conditions].is_a?(Hash)
        end

    end

  end

end
