require 'simplabs/reports_as_sparkline'

ActiveRecord::Base.class_eval do
  include Simplabs::ReportsAsSparkline
end

ActionView::Base.class_eval do
  include Simplabs::ReportsAsSparkline::SparklineTagHelper
end
