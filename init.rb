require 'kvlr/reports_as_sparkline'
require 'kvlr/core_extensions/date_time'

ActiveRecord::Base.class_eval do
  include Kvlr::ReportsAsSparkline
end

ActionView::Base.class_eval do
  include Kvlr::ReportsAsSparkline::AssetTagHelper
end
