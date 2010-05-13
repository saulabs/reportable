module Saulabs

  module Reportable

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
        :width      => 300,
        :height     => 100,
        :dom_id     => nil,
        :format     => 'to_i',
        :shade      => true,
        :hover_line_color => '2f69bf',
        :hover_fill_color => '2f69bf'
      }

    end

  end

end
