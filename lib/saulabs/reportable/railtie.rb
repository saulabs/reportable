require 'saulabs/reportable'
require 'rails'

module Saulabs

  module Reportable

    class Railtie < Rails::Railtie

      GEM_ROOT = File.join(File.dirname(__FILE__), '..', '..', '..')

      initializer 'saulabs.reportable.initialization' do
        require File.join(GEM_ROOT, 'rails', 'init')
      end

      generators do
        require File.join(GEM_ROOT, 'generators', 'reportable_migration', 'reportable_migration_generator')
        require File.join(GEM_ROOT, 'generators', 'reportable_raphael_assets', 'reportable_raphael_assets_generator')
        require File.join(GEM_ROOT, 'generators', 'reportable_jquery_flot_assets', 'reportable_jquery_flot_assets_generator')
      end

    end

  end

end
