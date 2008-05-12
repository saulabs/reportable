module ReportsAsSparkline   #:nodoc:
  def self.included(base) 
    base.extend ClassMethods
  end
  
  class ReportCache < ActiveRecord::Base
  end

  class InvalidGroupExpception < Exception
  end

  class InvalidOperationExpception < Exception
  end

  class ReportingGroup
    @@ranges = [:month, :week, :day, :hour]

    attr_reader :group

    def initialize(range)
      raise ReportsAsSparkline::InvalidGroupExpception unless @@ranges.include?(range.to_sym)
      @group = range.to_sym
    end

    def group_sql(attribute)
      attribute = attribute.to_s
      raise "No date_column given" if attribute.blank?
      case @group
      when :day
        group_by = "DATE(#{attribute})"
      when :week
        group_by = "YEARWEEK(#{attribute})"
      when :month
        group_by = "YEAR(#{attribute}) * 100 +  MONTH(#{attribute})"
      when :hour
        group_by = "DATE(#{attribute}) + HOUR(#{attribute})"
      end
      group_by
    end

    def latest_datetime
      case @group
  
      when :day, :week, :month
        return 1.send(@group).ago.to_date.to_datetime
      when :hour
        return 1.day.ago.to_date.to_datetime
      end
    end

    def self.default
      :day
    end
  end

  class ReportingOperation
    @@operations = [:count, :sum]

    attr_reader :operation

    def initialize(op)
      raise ReportsAsSparkline::InvalidOperationExpception unless @@operations.include?(op.to_sym)
      @operation = op.to_sym
    end

    def self.default
      :count
    end
  end


  class Report

    @@default_statement_options = {:limit => 100, :operation => ReportingOperation.default, :group => ReportingGroup.default, :date_column => 'created_at'}
    attr_reader :name, :operation, :date_column, :value_column, :graph_options, :statement_options, :reporting_group

    def initialize(name, options)
      @name  = name.to_sym
      @value_column = (options[:value_column] || @name).to_sym
      @statement_options = @@default_statement_options.merge options
  
      @reporting_group = ReportingGroup.new(@statement_options[:group])
      @reporting_operation = ReportingOperation.new(@statement_options[:operation])
    end

    def report(klass, options)
      statement_options = options.merge(@statement_options)
      reporting_group = statement_options[:group] != @reporting_group.group ? ReportingGroup.new(statement_options[:group]) : @reporting_group
      reporting_operation = statement_options[:operation] != @reporting_operation.operation ? ReportingOperation.new(statement_options[:operation]) : @reporting_operation
  
      conditions = ["model_name = ? AND report_name = ? AND report_range = ?", klass.to_s, name.to_s, reporting_group.group.to_s]
      newest_report = ReportCache.find(:first, :select => "start, value", :conditions => conditions, :order => "start DESC")
      newest_value = reporting_group.latest_datetime
      if newest_report.nil? or newest_report.start < newest_value
        value_statement = nil
        case reporting_operation.operation
        when :sum
          value_statement = "SUM(#{@value_column})"
        when :count
          value_statement = "COUNT(1)"
        end
        raise if value_statement.nil?
    
        where = ["#{reporting_group.group_sql(statement_options[:date_column])} <= \"#{newest_value.to_formatted_s(:db)}\""]
        where << "#{reporting_group.group_sql(statement_options[:date_column])} > \"#{(newest_report.start).to_formatted_s(:db)}\"" unless newest_report.nil?
        where = where.join(" AND ")
    
        query = "INSERT INTO #{ReportCache.table_name}  (model_name, report_name, report_range, start, value) 
          (
            SELECT \"#{klass.to_s}\", \"#{name}\", \"#{reporting_group.group.to_s}\", 
              #{reporting_group.group_sql(statement_options[:date_column])} AS start, 
              #{value_statement} AS value 
            FROM #{klass.table_name}
            WHERE #{where}
            GROUP BY start
          );"
        ActiveRecord::Base.connection.execute query
      end
      data = ReportCache.find(:all, :select => "start, value", :conditions => conditions, :order => "start DESC", :limit => statement_options[:limit])
      data.collect! {|report| [report.start, report.value] }
      data.reverse
    end

    # def generate_report(klass, options)
    #   
    #   
    #   case reporting_operation.operation
    #   when :sum
    #     return klass.sum @value_column, :group => @reporting_group.group_sql(@statement_options[:date_column])
    #   when :count
    #     return klass.count :group => @reporting_group.group_sql(@statement_options[:date_column])
    #   end
    # end
  end


  class CumulateReport < ReportsAsSparkline::Report

    def report(klass, options)
      CumulateReport.cumulate!(super(klass, options))
    end

    protected
    def self.cumulate!(data)
      last_item = 0
      data.collect{ |element|
        last_item += element[1].to_i
        [element[0], last_item]
      }
    end

  end

  module ClassMethods
    #
    # Examples:
    #
    # class Game < ActiveRecord::Base
    #   report_as_sparkline :games_per_day
    #   report :games_played_total, :cumulate => :games_played
    # end
    # class User < ActiveRecord::Base
    #   report_as_sparkline :registrations, :operation => :count
    #   report_as_sparkline :activations, :date_column => :activated_at, :operation => :count
    #   report_as_sparkline :total_users_report, :cumulate => :registrations
    # end
    # class Rake < ActiveRecord::Base
    #   report_as_sparkline :rake, :operation => :sum
    # end
    def report_as_sparkline(name, options = {})
      report = options[:cumulate] ? ReportsAsSparkline::CumulateReport.new(options[:cumulate], options) : ReportsAsSparkline::Report.new(name, options)
      (class << self; self; end).instance_eval { 
        define_method "#{name.to_s}_report".to_sym do |*args|
          raise ArgumentError if args.size > 1
          options = args.first || {}
          raise ArgumentError unless options.is_a?(Hash)
          report.report(self, options) 
        end
      }
    end
  end
end
