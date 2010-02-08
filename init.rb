require 'saulabs/reports_as_sparkline'

ActiveRecord::Base.class_eval do
  include Saulabs::ReportsAsSparkline
end

ActionView::Base.class_eval do
  include Saulabs::ReportsAsSparkline::SparklineTagHelper
end
