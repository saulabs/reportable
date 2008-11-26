module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    class ReportCache < ActiveRecord::Base

      def self.cached(klass, name, range, &block)
        raise ArgumentError.new('A block must be given') unless block_given?
        unless result = self.find(
          :all,
          :conditions => { :model_name => klass.to_s, :report_name => name.to_s, :report_range => range.to_s }
        )
          result = yield
        end
        result
      end

    end

  end

end
