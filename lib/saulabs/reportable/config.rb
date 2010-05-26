module Saulabs

  module Reportable

    # The Reportable configuration module defines colors, sizes etc. for the different report tag renderers.
    #
    module Config

      mattr_accessor :google_options

      @@google_options = {
        :width      => 300,
        :height     => 34,
        :line_color => '0077cc',
        :fill_color => 'e6f2fa',
        :labels     => []
      }

      mattr_accessor :raphael_options

      @@raphael_options = {
        :width            => 300,
        :height           => 100,
        :dom_id           => nil,
        :format           => 'to_i',
        :shade            => true,
        :hover_line_color => '2f69bf',
        :hover_fill_color => '2f69bf'
      }

      mattr_accessor :flot_options

      @@flot_options = {
        :width  => 300,
        :height => 100,
        :dom_id => nil,
        :colors => ['rgba(6,122,205,1)'],
        :grid   => { 
          :show => false
        },
        :series => {
          :lines      => {
            :fill      => true,
            :fillColor => 'rgba(6,122,205,.5)',
            :lineWidth => 2
          },
          :shadowSize => 0
        }
      }

    end

  end

end
