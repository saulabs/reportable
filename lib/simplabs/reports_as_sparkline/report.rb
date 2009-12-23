module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # The Report class that does all the data retrieval and calculations
    class Report

      attr_reader :klass, :name, :date_column, :value_column, :aggregation, :options

      # ==== Parameters
      # * <tt>klass</tt> - The model the report works on (This is the class you invoke Simplabs::ReportsAsSparkline::ClassMethods#reports_as_sparkline on)
      # * <tt>name</tt> - The name of the report (as in Simplabs::ReportsAsSparkline::ClassMethods#reports_as_sparkline)
      #
      # ==== Options
      #
      # * <tt>:date_column</tt> - The name of the date column over that the records are aggregated (defaults to <tt>created_at</tt>)
      # * <tt>:value_column</tt> - The name of the column that holds the values to sum up when using aggregation <tt>:sum</tt>
      # * <tt>:aggregation</tt> - The aggregation to use (one of <tt>:count</tt>, <tt>:sum</tt>, <tt>:minimum</tt>, <tt>:maximum</tt> or <tt>:average</tt>); when using anything other than <tt>:count</tt>, <tt>:value_column</tt> must also be specified (<b>If you really want to e.g. sum up the values in the <tt>id</tt> column, you have to explicitely say so.</b>); (defaults to <tt>:count</tt>)
      # * <tt>:grouping</tt> - The period records are grouped on (<tt>:hour</tt>, <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt>); <b>Beware that <tt>reports_as_sparkline</tt> treats weeks as starting on monday!</b>
      # * <tt>:limit</tt> - The number of reporting periods to get (see <tt>:grouping</tt>), (defaults to 100)
      # * <tt>:conditions</tt> - Conditions like in <tt>ActiveRecord::Base#find</tt>; only records that match the conditions are reported; <b>Beware that when conditions are specified, caching is disabled!</b>
      # * <tt>:live_data</tt> - Specifies whether data for the current reporting period is to be read; <b>if <tt>:live_data</tt> is <tt>true</tt>, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to <tt>false</tt>)</b>
      # * <tt>:end_date</tt> - When specified, the report will only include data for the <tt>:limit</tt> reporting periods until this date.
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
          :live_data  => options[:live_data] || false,
          :end_date   => options[:end_date] || false
        }
        @options.merge!(options)
        @options.freeze
      end

      # Runs the report and returns an array of array of DateTimes and Floats
      #
      # ==== Options
      # * <tt>:grouping</tt> - The period records are grouped on (<tt>:hour</tt>, <tt>:day</tt>, <tt>:week</tt>, <tt>:month</tt>); <b>Beware that <tt>reports_as_sparkline</tt> treats weeks as starting on monday!</b>
      # * <tt>:limit</tt> - The number of reporting periods to get (see <tt>:grouping</tt>), (defaults to 100)
      # * <tt>:conditions</tt> - Conditions like in <tt>ActiveRecord::Base#find</tt>; only records that match the conditions are reported
      # * <tt>:live_data</tt> - Specifies whether data for the current reporting period is to be read; <b>if <tt>:live_data</tt> is <tt>true</tt>, you will experience a performance hit since the request cannot be satisfied from the cache only (defaults to <tt>false</tt>)</b>
      # * <tt>:end_date</tt> - When specified, the report will only include data for the <tt>:limit</tt> reporting periods until this date.
      def run(options = {})
        options = options_for_run(options)
        ReportCache.process(self, options) do |begin_at, end_at|
          read_data(begin_at, end_at, options)
        end
      end

      private

        def options_for_run(options = {})
          options = options.dup
          ensure_valid_options(options, :run)
          options.reverse_merge!(@options)
          options[:grouping] = Grouping.new(options[:grouping]) unless options[:grouping].is_a?(Grouping)
          return options
        end

        def read_data(begin_at, end_at, options)
          conditions = setup_conditions(begin_at, end_at, options[:conditions])
          @klass.send(@aggregation,
            @value_column,
            :conditions => conditions,
            :group      => options[:grouping].to_sql(@date_column),
            :order      => "#{options[:grouping].to_sql(@date_column)} ASC",
            :limit      => options[:limit]
          )
        end

        def setup_conditions(begin_at, end_at, custom_conditions = [])
          conditions = [@klass.send(:sanitize_sql_for_conditions, custom_conditions) || '']
          conditions[0] += "#{(conditions[0].blank? ? '' : ' AND ')}#{ActiveRecord::Base.connection.quote_table_name(@klass.table_name)}.#{ActiveRecord::Base.connection.quote_column_name(@date_column.to_s)} "
          conditions[0] += if begin_at && end_at
            'BETWEEN ? AND ?'
          elsif begin_at
            '>= ?'
          elsif end_at
            '<= ?'
          else
            raise ArgumentError.new('You must pass either begin_at, end_at or both to setup_conditions.')
          end
          conditions << begin_at if begin_at
          conditions << end_at if end_at
          conditions
        end

        def ensure_valid_options(options, context = :initialize)
          case context
            when :initialize
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}!") unless [:limit, :aggregation, :grouping, :date_column, :value_column, :conditions, :live_data, :end_date].include?(k)
              end
              raise ArgumentError.new("Invalid aggregation #{options[:aggregation]}!") if options[:aggregation] && ![:count, :sum, :maximum, :minimum, :average].include?(options[:aggregation])
              raise ArgumentError.new('The name of the column holding the value to sum has to be specified for aggregation :sum!') if [:sum, :maximum, :minimum, :average].include?(options[:aggregation]) && !options.key?(:value_column)
            when :run
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}!") unless [:limit, :conditions, :grouping, :live_data, :end_date].include?(k)
              end
          end
          raise ArgumentError.new('Options :live_data and :end_date may not both be specified!') if options[:live_data] && options[:end_date]
          raise ArgumentError.new("Invalid grouping #{options[:grouping]}!") if options[:grouping] && ![:hour, :day, :week, :month].include?(options[:grouping])
          raise ArgumentError.new("Invalid conditions: #{options[:conditions].inspect}!") if options[:conditions] && !options[:conditions].is_a?(Array) && !options[:conditions].is_a?(Hash)
          raise ArgumentError.new("Invalid end date: #{options[:end_date].inspect}; must be a DateTime!") if options[:end_date] && !options[:end_date].is_a?(DateTime) && !options[:end_date].is_a?(Time)
          raise ArgumentError.new('End date may not be in the future!') if options[:end_date] && options[:end_date] > DateTime.now
        end

    end

  end

end
