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
        require File.join(GEM_ROOT, 'generators', 'reportable_assets', 'reportable_assets_generator')
      end

      rake_tasks do
        load File.join(GEM_ROOT, 'tasks', 'reportable_tasks.rake')
      end

    end

  end

end
