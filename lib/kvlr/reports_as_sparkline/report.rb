module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Report

      attr_reader :klass, :name, :date_column_name, :value_column_name, :grouping, :aggregation

      def initialize(klass, name, options = {})
        ensure_valid_options(options)
        @klass             = klass
        @name              = name
        @date_column_name  = (options[:date_column_name] || 'created_at').to_s
        @value_column_name = (options[:value_column_name] || (options[:aggregation] != :sum ? 'id' : name)).to_s
        @aggregation       = options[:aggregation] || :count
        @grouping          = Grouping.new(options[:grouping] || :day)
        @options = {
          :limit             => options[:limit] || 100,
          :conditions        => options[:conditions] || []
        }
        @options.merge!(options)
      end

      def run(options = {})
        ensure_valid_options(options, :run)
        custom_conditions = options.key?(:conditions)
        options.reverse_merge!(@options)
        ReportCache.process(self, options[:limit], custom_conditions) do |begin_at|
          read_data(begin_at, options[:conditions])
        end
      end

      private

        def read_data(begin_at, conditions = []) #:nodoc:
          conditions = setup_conditions(begin_at, conditions)
          @klass.send(@aggregation,
            @value_column_name,
            :conditions => conditions,
            :group => @grouping.to_sql(@date_column_name),
            :order => "#{@grouping.to_sql(@date_column_name)} DESC"
          )
        end

        def setup_conditions(begin_at, custom_conditions = []) #:nodoc:
          conditions = ['']
          if custom_conditions.is_a?(Hash)
            conditions = [custom_conditions.map{ |k, v| "#{k.to_s} = ?" }.join(' AND '), *custom_conditions.map{ |k, v| v }]
          elsif custom_conditions.size > 0
            conditions = [(custom_conditions[0] || ''), *custom_conditions[1..-1]]
          end
          conditions[0] += "#{(conditions[0].blank? ? '' : ' AND ') + @date_column_name.to_s} >= ?"
          conditions << begin_at
        end

        def ensure_valid_options(options, context = :initialize) #:nodoc:
          case context
            when :initialize
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :aggregation, :grouping, :date_column_name, :value_column_name, :conditions].include?(k)
              end
              raise ArgumentError.new("Invalid aggregation #{options[:aggregation]}") if options[:aggregation] && ![:count, :sum].include?(options[:aggregation])
              raise ArgumentError.new("Invalid grouping #{options[:grouping]}") if options[:grouping] && ![:hour, :day, :week, :month].include?(options[:grouping])
              raise ArgumentError.new('The name of the column holding the value to sum has to be specified for aggregation :sum') if options[:aggregation] == :sum && !options.key?(:value_column_name)
            when :run
              options.each_key do |k|
                raise ArgumentError.new("Invalid option #{k}") unless [:limit, :conditions].include?(k)
              end
          end
          raise ArgumentError.new("Invalid conditions: #{options[:conditions].inspect}") if options[:conditions] && !options[:conditions].is_a?(Array) && !options[:conditions].is_a?(Hash)
        end

    end

  end

end
