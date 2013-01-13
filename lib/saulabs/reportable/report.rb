require 'saulabs/reportable/grouping'
require 'saulabs/reportable/report_cache'

module Saulabs

  module Reportable

    # The Report class that does all the data retrieval and calculations.
    #
    class Report

      # the model the report works on (This is the class you invoke {Saulabs::Reportable::ClassMethods#reportable} on)
      #
      attr_reader :klass

      # the name of the report (as in {Saulabs::Reportable::ClassMethods#reportable})
      #
      attr_reader :name

      # the name of the date column over that the records are aggregated
      #
      attr_reader :date_column

      # the name of the column that holds the values to aggregate when using a calculation aggregation like +:sum+
      #
      attr_reader :value_column

      # the aggregation to use (one of +:count+, +:sum+, +:minimum+, +:maximum+ or +:average+); when using anything other than +:count+, +:value_column+ must also be specified
      #
      attr_reader :aggregation

      # options for the report
      #
      attr_reader :options

      # Initializes a new {Saulabs::Reportable::Report}
      #
      # @param [Class] klass
      #   the model the report works on (This is the class you invoke {Saulabs::Reportable::ClassMethods#reportable} on)
      # @param [String] name
      #   the name of the report (as in {Saulabs::Reportable::ClassMethods#reportable})
      # @param [Hash] options
      #   options for the report creation
      #
      # @option options [Symbol] :date_column (created_at)
      #   the name of the date column over that the records are aggregated
      # @option options [String, Symbol] :value_column (:id)
      #   the name of the column that holds the values to aggregate when using a calculation aggregation like +:sum+
      # @option options [Symbol] :aggregation (:count)
      #   the aggregation to use (one of +:count+, +:sum+, +:minimum+, +:maximum+ or +:average+); when using anything other than +:count+, +:value_column+ must also be specified
      # @option options [Symbol] :grouping (:day)
      #   the period records are grouped in (+:hour+, +:day+, +:week+, +:month+); <b>Beware that <tt>reportable</tt> treats weeks as starting on monday!</b>
      # @option options [Fixnum] :limit (100)
      #   the number of reporting periods to get (see +:grouping+)
      # @option options [Hash] :conditions ({})
      #   conditions like in +ActiveRecord::Base#find+; only records that match these conditions are reported;
      # @option options [Boolean] :live_data (false)
      #   specifies whether data for the current reporting period is to be read; <b>if +:live_data+ is +true+, you will experience a performance hit since the request cannot be satisfied from the cache alone</b>
      # @option options [DateTime, Boolean] :end_date (false)
      #   when specified, the report will only include data for the +:limit+ reporting periods until this date.
      # @option options [Boolean] :cacheable (true)
      #   when set to false, the report will never use the cache, which allows reuse of a named report with different conditions
      #
      def initialize(klass, name, options = {})
        ensure_valid_options(options)
        @klass        = klass
        @name         = name
        @date_column  = (options[:date_column] || 'created_at').to_s
        @aggregation  = options[:aggregation] || :count
        @value_column = (options[:value_column] || (@aggregation == :count ? 'id' : name)).to_s
        @options = {
          :limit      => options[:limit] || 100,
          :distinct   => options[:distinct] || false,
          :conditions => options[:conditions] || [],
          :grouping   => Grouping.new(options[:grouping] || :day),
          :live_data  => options[:live_data] || false,
          :end_date   => options[:end_date] || false,
          :cacheable  => ( options[:cacheable] == false ? false : true )
        }
        @options.merge!(options)
        @options.freeze
      end

      # Runs the report and returns an array of array of DateTimes and Floats
      #
      # @param [Hash] options
      #   options to run the report with
      #
      # @option options [Symbol] :grouping (:day)
      #   the period records are grouped in (+:hour+, +:day+, +:week+, +:month+); <b>Beware that <tt>reportable</tt> treats weeks as starting on monday!</b>
      # @option options [Fixnum] :limit (100)
      #   the number of reporting periods to get (see +:grouping+)
      # @option options [Hash] :conditions ({})
      #   conditions like in +ActiveRecord::Base#find+; only records that match these conditions are reported;
      # @option options [Boolean] :live_data (false)
      #   specifies whether data for the current reporting period is to be read; <b>if +:live_data+ is +true+, you will experience a performance hit since the request cannot be satisfied from the cache alone</b>
      # @option options [DateTime, Boolean] :end_date (false)
      #   when specified, the report will only include data for the +:limit+ reporting periods until this date.
      #
      # @option options [Boolean] :cacheable (true)
      #   when set to false, the report will never use the cache, which allows reuse of a named report with different conditions
      #
      # @return [Array<Array<DateTime, Float>>]
      #   the result of the report as pairs of {DateTime}s and {Float}s
      #
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
            :distinct   => options[:distinct],
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
                raise ArgumentError.new("Invalid option #{k}!") unless [:limit, :aggregation, :grouping, :distinct, :date_column, :value_column, :conditions, :live_data, :end_date, :cacheable].include?(k)
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
