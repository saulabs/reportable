require 'saulabs/reportable'
require 'rails'

module Saulabs

  module Reportable

    class Railtie < Rails::Railtie

      initializer 'saulabs.reportable.initialization' do
        require File.join(File.dirname(__FILE__), '..', '..', '..', 'rails', 'init')
      end

      generators do
        require File.join(File.dirname(__FILE__), '..', '..', '..', 'generators', 'reportable_migration', 'reportable_migration_generator')
      end

    end

  end

end
