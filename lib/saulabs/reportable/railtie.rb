require 'saulabs/reportable'
require 'saulabs/reportable/report_tag_helper'
require 'rails'

module Saulabs

  module Reportable

    class Railtie < Rails::Railtie

      GEM_ROOT = File.join(File.dirname(__FILE__), '..', '..', '..')

      initializer 'saulabs.reportable.initialization' do
        ActiveSupport.on_load :active_record do
          ActiveRecord::Base.class_eval do
            include Saulabs::Reportable::RailsAdapter
          end
        end
        ActiveSupport.on_load :action_view do
          ActionView::Base.class_eval do
            include Saulabs::Reportable::ReportTagHelper
          end
        end

      end

      generators do
        require File.join(GEM_ROOT, 'lib', 'generators', 'reportable_migration', 'reportable_migration_generator')
        require File.join(GEM_ROOT, 'lib', 'generators', 'reportable_raphael_assets', 'reportable_raphael_assets_generator')
        require File.join(GEM_ROOT, 'lib', 'generators', 'reportable_jquery_flot_assets', 'reportable_jquery_flot_assets_generator')
      end

    end

  end

end
