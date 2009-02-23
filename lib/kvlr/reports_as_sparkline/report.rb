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
      # * <tt>:aggregation</tt> - The aggregation to use (one of :count, :sum, :minimum, :maximum or :average); when using anything other than :count, :value_column must also be specified (<b>If you really want to e.g. sumon the 'id' column, you have to explicitely say so.</b>)
      # * <tt>:grouping</tt> - The period records are grouped on (:hour, :day, :week, :month); <b>Beware that reports_as_sparkline treats weeks as starting on monday!</b>
      # * <tt>:limit</tt> - The number of periods to get (see :grouping)
      # * <tt>:conditions</tt> - Conditions like in ActiveRecord::Base#find; only records that match there conditions are reported on
      # * <tt>:live_data</tt> - Specified whether data for the current reporting period is read; if :live_data is true, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to false)
      def initialize(klass, name, options = {})
        ensure_valid_options(options)
        @klass        = klass
        @name         = name
        @date_column  = (options[:date_column] || 'created_at').to_s
        @aggregation  = options[:aggregation] || :count
        @value_column = (options[:value_column] || (@aggregation == :count ? 'id' : name)).to_s
        @options = {
          :limit      => options[:limit] || 100,
          :conditions => options[:conditions] || [],
          :grouping   => Grouping.new(options[:grouping] || :day),
          :live_data  => options[:live_data] || false
        }
        @options.merge!(options)
        @options.freeze
      end

      # Runs the report and returns an array of array of DateTimes and Floats
      #
      # ==== Options
      # * <tt>:limit</tt> - The number of periods to get
      # * <tt>:conditions</tt> - Conditions like in ActiveRecord::Base#find; only records that match there conditions are reported on (<b>Beware that when you specify conditions here, caching will be disabled</b>)
      # * <tt>:grouping</tt> - The period records are grouped on (:hour, :day, :week, :month); <b>Beware that reports_as_sparkline treats weeks as starting on monday!</b>
      # * <tt>:live_data</tt> - Specified whether data for the current reporting period is read; if :live_data is true, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to false)
      def run(options = {})
        ensure_valid_options(options, :run)
        custom_conditions = options.key?(:conditions)
        options.reverse_merge!(@options)
        options[:grouping] = Grouping.new(options[:grouping]) unless options[:grouping].is_a?(Grouping)
        ReportCache.process(self, options, !custom_conditions) do |begin_at|
          read_data(begin_at, options)
        end
      end

      private

        def read_data(begin_at, options)
          conditions = setup_conditions(begin_at, options[:conditions])
          @klass.send(@aggregation,
            @value_column,
            :conditions => conditions,
            :group => options[:grouping].to_sql(@date_column),
            :order => "#{options[:grouping].to_sql(@date_column)} ASC"
          )
        end

        def setup_conditions(begin_at, custom_conditions = [])
          conditions = ['']
          if custom_conditions.is_a?(Hash)
            conditions = [custom_conditions.map do |k, v|
              if v.nil?
                "#{k.to_s} IS NULL"
              elsif v.is_a?(Array) || v.is_a?(Range)
                "#{k.to_s} IN (?)"
              else
                "#{k.to_s} = ?"
              end
            end.join(' AND '), *custom_conditions.map { |k, v| v }.compact]
          elsif custom_conditions.size > 0
            conditions = [(custom_conditions[0] || ''), *custom_conditions[1..-1]]
          end
          conditions[0] += "#{(conditions[0].blank? ? '' : ' AND ') + @date_column.to_s} >= ?"
          conditions << begin_at
        end

        def ensure_valid_options(options, context = :initialize)
          case context
            when :initialize
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :aggregation, :grouping, :date_column, :value_column, :conditions, :live_data].include?(k)
              end
              raise ArgumentError.new("Invalid aggregation #{options[:aggregation]}") if options[:aggregation] && ![:count, :sum, :maximum, :minimum, :average].include?(options[:aggregation])
              raise ArgumentError.new('The name of the column holding the value to sum has to be specified for aggregation :sum') if [:sum, :maximum, :minimum, :average].include?(options[:aggregation]) && !options.key?(:value_column)
            when :run
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :conditions, :grouping, :live_data].include?(k)
              end
          end
          raise ArgumentError.new("Invalid grouping #{options[:grouping]}") if options[:grouping] && ![:hour, :day, :week, :month].include?(options[:grouping])
          raise ArgumentError.new("Invalid conditions: #{options[:conditions].inspect}") if options[:conditions] && !options[:conditions].is_a?(Array) && !options[:conditions].is_a?(Hash)
        end

    end

  end

end
