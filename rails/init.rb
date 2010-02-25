require 'saulabs/reportable'

ActiveRecord::Base.class_eval do
  include Saulabs::Reportable
end

ActionView::Base.class_eval do
  include Saulabs::Reportable::SparklineTagHelper
end
