module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Report

      attr_reader :klass, :name

      def initialize(klass, name, options = {})
        ensure_valid_options(options)
        @klass = klass
        @name  = name
        @options = {
          :limit             => options[:limit] || 100,
          :aggregation       => options[:aggregation] || :count,
          :grouping          => options[:grouping] || :day,
          :date_column_name  => (options[:date_column_name] || 'created_at').to_s,
          :value_column_name => (options[:value_column_name] || (options[:aggregation] != :sum ? 'id' : @name)).to_s,
          :conditions        => options[:conditions] || ['']
        }
        @options.merge!(options)
        @options[:conditions][0].freeze
      end

      def run(options = {})
        ensure_valid_options(options)
        options = @options.merge(options)
        grouping = Grouping.new(options[:grouping])
        ReportCache.cached_transaction(self, grouping, options[:limit], options[:date_column_name]) do |begin_at|
          conditions = [options[:conditions][0], *options[:conditions][1..-1]]
          conditions[0] += "#{(conditions[0].blank? ? '' : ' AND ') + options[:date_column_name].to_s} >= ?"
          conditions << begin_at
          @klass.send(options[:aggregation],
            options[:value_column_name].to_s,
            :conditions => conditions,
            :group => grouping.to_sql(options[:date_column_name]),
            :order => "#{options[:date_column_name].to_s} DESC"
          )
        end
      end

      private

        def ensure_valid_options(options)
          options.each_key do |k|
            raise ArgumentError.new("Invalid option #{k}") unless [:limit, :aggregation, :grouping, :date_column_name, :value_column_name, :conditions].include?(k)
          end
          allowed_aggregations = [:count, :sum]
          if options[:aggregation] && !allowed_aggregations.include?(options[:aggregation])
            raise ArgumentError.new("Invalid aggregation #{options[:aggregation]}; use either #{allowed_aggregations.map(&:to_s).join(' or ')}")
          end
          allowed_groupings = [:hour, :day, :month, :year]
          if options[:grouping] && !allowed_groupings.include?(options[:grouping])
            raise ArgumentError.new("Invalid grouping #{options[:grouping]}; use one of #{allowed_groupings.join(', ')}")
          end
          if options[:conditions] && !options[:conditions].is_a?(Array)
            raise ArgumentError.new("Invalid conditions: conditions must be specified as an array like ['user_name = ?', 'username']")
          end
        end

    end

  end

end
