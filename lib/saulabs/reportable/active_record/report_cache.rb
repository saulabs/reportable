module Saulabs
  module Reportable
    module ActiveRecord
      # The +ReportCache+ class is a regular +ActiveRecord+ model and represents cached results for single {Saulabs::Reportable::ReportingPeriod}s.
      # +ReportCache+ instances are identified by the combination of +model_name+, +report_name+, +grouping+, +aggregation+ and +reporting_period+.
      #
      class ReportCache < ActiveRecord::Base

        self.table_name = :reportable_cache

        validates_presence_of :model_name
        validates_presence_of :report_name
        validates_presence_of :grouping
        validates_presence_of :aggregation
        validates_presence_of :value
        validates_presence_of :reporting_period

        attr_accessible :model_name, :report_name, :grouping, :aggregation, :value, :reporting_period, :conditions

        self.skip_time_zone_conversion_for_attributes = [:reporting_period]

        # Clears the cache for the specified +klass+ and +report+
        #
        # @param [Class] klass
        #   the model the report to clear the cache for works on
        # @param [Symbol] report
        #   the name of the report to clear the cache for
        #
        # @example Clearing the cache for a report
        #
        #   class User < ActiveRecord::Base
        #     reportable :registrations
        #   end
        #
        #   Saulabs::Reportable::ReportCache.clear_for(User, :registrations)
        #
        def self.clear_for(klass, report)
          self.delete_all(:conditions => {
            :model_name  => klass.name,
            :report_name => report.to_s
          })
        end

        # Processes the report using the respective cache.
        #
        # @param [Saulabe::Reportable::Report] report
        #   the report to process
        # @param [Hash] options
        #   options for the report
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
        # @return [ResultSet<Array<DateTime, Float>>]
        #   the result of the report as pairs of {DateTime}s and {Float}s
        #
        def self.process(report, options, &block)
          raise ArgumentError.new('A block must be given') unless block_given?
          self.transaction do
            cached_data = read_cached_data(report, options)
            new_data = read_new_data(cached_data, options, &block)
            prepare_result(new_data, cached_data, report, options)
          end
        end

        private

          def self.prepare_result(new_data, cached_data, report, options)
            new_data = new_data.map { |data| [ReportingPeriod.from_db_string(options[:grouping], data[0]), data[1]] }
            cached_data.map! { |cached| [ReportingPeriod.new(options[:grouping], cached.reporting_period), cached.value] }
            current_reporting_period = ReportingPeriod.new(options[:grouping])
            reporting_period = get_first_reporting_period(options)
            result = []
            while reporting_period < (options[:end_date] ? ReportingPeriod.new(options[:grouping], options[:end_date]).next : current_reporting_period)
              if cached = cached_data.find { |cached| reporting_period == cached[0] }
                result << [cached[0].date_time, cached[1]]
              else
                new_cached = build_cached_data(report, options[:grouping], options[:conditions], reporting_period, find_value(new_data, reporting_period))
                new_cached.save!
                result << [reporting_period.date_time, new_cached.value]
              end
              reporting_period = reporting_period.next
            end
            if options[:live_data]
              result << [current_reporting_period.date_time, find_value(new_data, current_reporting_period)]
            end
            Saulabs::Reportable::ResultSet.new(result, report.klass.name, report.name)
          end

          def self.find_value(data, reporting_period)
            data = data.detect { |d| d[0] == reporting_period }
            data ? data[1] : 0.0
          end

          def self.build_cached_data(report, grouping, conditions, reporting_period, value)
            self.new(
              :model_name       => report.klass.to_s,
              :report_name      => report.name.to_s,
              :grouping         => grouping.identifier.to_s,
              :aggregation      => report.aggregation.to_s,
              :conditions       => serialize_conditions(conditions),
              :reporting_period => reporting_period.date_time,
              :value            => value
            )
          end

          def self.serialize_conditions(conditions)
            if conditions.is_a?(Array) && conditions.any?
              conditions.join
            elsif conditions.is_a?(Hash) && conditions.any?
              conditions.map.sort{|x,y|x.to_s<=>y.to_s}.flatten.join
            else
              conditions.empty? ? '' : conditions.to_s
            end
          end

          def self.read_cached_data(report, options)
            options[:conditions] ||= []
            conditions = [
              %w(model_name report_name grouping aggregation conditions).map do |column_name|
                "#{self.connection.quote_column_name(column_name)} = ?"
              end.join(' AND '),
              report.klass.to_s,
              report.name.to_s,
              options[:grouping].identifier.to_s,
              report.aggregation.to_s,
              serialize_conditions(options[:conditions])
            ]
            first_reporting_period = get_first_reporting_period(options)
            last_reporting_period = get_last_reporting_period(options)
            if last_reporting_period
              conditions.first << ' AND reporting_period BETWEEN ? AND ?'
              conditions << first_reporting_period.date_time
              conditions << last_reporting_period.date_time
            else
              conditions.first << ' AND reporting_period >= ?'
              conditions << first_reporting_period.date_time
            end
            self.all(
              :conditions => conditions,
              :limit      => options[:limit],
              :order      => 'reporting_period ASC'
            )
          end

          def self.read_new_data(cached_data, options, &block)
            if !options[:live_data] && cached_data.length == options[:limit]
              []
            else
              first_reporting_period_to_read = if cached_data.length < options[:limit]
                get_first_reporting_period(options)
              else
                ReportingPeriod.new(options[:grouping], cached_data.last.reporting_period).next
              end
              last_reporting_period_to_read = options[:end_date] ? ReportingPeriod.new(options[:grouping], options[:end_date]).last_date_time : nil
              yield(first_reporting_period_to_read.date_time, last_reporting_period_to_read)
            end
          end

          def self.get_first_reporting_period(options)
            if options[:end_date]
              ReportingPeriod.first(options[:grouping], options[:limit] - 1, options[:end_date])
            else
              ReportingPeriod.first(options[:grouping], options[:limit])
            end
          end

          def self.get_last_reporting_period(options)
            return ReportingPeriod.new(options[:grouping], options[:end_date]) if options[:end_date]
          end

      end
    end
  end
end
