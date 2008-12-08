module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    class InvalidGroupExpception < Exception
    end

    class InvalidOperationExpception < Exception
    end

    module ClassMethods

      #
      # Examples:
      #
      # class Game < ActiveRecord::Base
      #   report_as_sparkline :games_per_day
      #   report_as_sparkline :games_played_total, :cumulate => true
      # end
      # class User < ActiveRecord::Base
      #   report_as_sparkline :registrations, :operation => :count
      #   report_as_sparkline :activations, :date_column => :activated_at, :operation => :count
      #   report_as_sparkline :total_users_report, :cumulate => true
      # end
      # class Rake < ActiveRecord::Base
      #   report_as_sparkline :rake, :operation => :sum
      # end
      def report_as_sparkline(name, options = {})
        (class << self; self; end).instance_eval do
          define_method "#{name.to_s}_report".to_sym do |*args|
            if options.delete(:cumulate)
              report = Kvlr::ReportsAsSparkline::CumulatedReport.new(self, name, options)
            else
              report = Kvlr::ReportsAsSparkline::Report.new(self, name, options)
            end
            raise ArgumentError.new unless args.length == 0 || (args.length == 1 && args[0].is_a?(Hash))
            report.run(args.length == 0 ? {} : args[0])
          end
        end
      end

    end

  end

end
