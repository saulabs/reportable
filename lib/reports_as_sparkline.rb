require 'active_support'
require 'active_record'
#require 'action_view'
#require 'action_controller'

module ReportsAsSparkline
  class << self
    # shortcut for <tt>enable_actionpack; enable_activerecord</tt>
    def enable
      enable_actionpack
      enable_activerecord
    end
    
    # mixes in ReportsAsSparkline::ViewHelpers in ActionView::Base
    def enable_actionpack
      #return if ActionView::Base.instance_methods.include? 'sparkline_tag'
      #require 'reports_as_sparkline/view_helpers'
      #ActionView::Base.class_eval { include ViewHelpers }
    end
    
    def enable_activerecord
      return if false
      require 'reports_as_sparkline/report'
      ActiveRecord::Base.send(:include, ReportsAsSparkline)
    end
  end
end

if defined?(ActiveRecord)
  ReportsAsSparkline.enable
else
  raise "Could not find ActiveRecord"
end
