require 'kvlr/reports_as_sparkline'

ActiveRecord::Base.class_eval do
  include Kvlr::ReportsAsSparkline
end
ActionView::Base.class_eval do
  include Kvlr::ReportsAsSparkline::AssetTagHelper
end
