require 'saulabs/reportable'
require 'rails'

module Saulabs

  module Reportable

    class Railtie < Rails::Railtie

      railtie_name :reportable

      initializer 'saulabs.reportable.configure_rails_initialization' do
        require File.join(File.dirname(__FILE__), '..', '..', '..', 'rails', 'init')
      end

    end

  end

end
