require 'action_view'
require 'saulabs/reportable'
require 'saulabs/reportable/report_tag_helper'

ActiveRecord::Base.class_eval do
  include Saulabs::Reportable
end

ActionView::Base.class_eval do
  include Saulabs::Reportable::ReportTagHelper
end
