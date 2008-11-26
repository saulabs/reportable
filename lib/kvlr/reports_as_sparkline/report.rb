module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class Report

      def initialize(klass, name, options = {})
        @klass = klass
        @name  = name
        @options = {
          :limit             => options[:limit] || 100,
          :aggregation       => options[:aggregation] || :count,
          :grouping          => options[:grouping] || :day,
          :date_column_name  => (options[:date_column_name] || 'created_at').to_s,
          :value_column_name => (options[:value_column_name] || 'id').to_s,
          :conditions        => options[:conditions] || ['']
        }.merge(options)
      end

      def run(options = {})
        options = @options.merge(options)
        conditions = [options[:conditions][0], *options[:conditions][1..-1]]
        @klass.send(options[:aggregation],
          options[:value_column_name],
          :conditions => conditions,
          :group => group_sql(options[:grouping], options[:date_column_name]),
          :order => "#{options[:date_column_name]} DESC"
        )
      end

      private

        def group_sql(grouping, date_column_name)
          return case grouping
            when :day
              "DATE(#{date_column_name})"
            when :week
              "YEAR(#{date_column_name}) + YEARWEEK(#{date_column_name})"
            when :month
              "YEAR(#{date_column_name}) + MONTH(#{date_column_name})"
            when :hour
              "DATE(#{date_column_name}) + HOUR(#{date_column_name})"
            end
        end

    end

  end

end
