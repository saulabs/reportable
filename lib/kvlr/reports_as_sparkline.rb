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
      #   report_as_sparkline :games_played_total, :cumulate => :games_played
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
        if options[:cumulate]
          report = Kvlr::ReportsAsSparkline::CumulatedReport.new(self, options.delete(:cumulate), options)
        else
          report = Kvlr::ReportsAsSparkline::Report.new(self, name, options)
        end
        (class << self; self; end).instance_eval do
          define_method "#{name.to_s}_report".to_sym do |*args|
            raise ArgumentError if args.size > 1
            if args.size == 1
              raise ArgumentError unless args.first.is_a?(Hash)
            end
            report.run(args.first || {})
          end
        end
      end

    end

  end

end
