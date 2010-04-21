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

      mattr_accessor :grafico_options

      @@grafico_options = {
        :width                  => 300,
        :height                 => 100,
        :dom_id                 => nil,
        :format                 => 'to_i',
        :area_opacity           => 0.3,
        :markers                => 'value',
        :grid                   => false,
        :draw_axis              => false,
        :plot_padding           => 0,
        :padding_left           => 0,
        :padding_bottom         => 0,
        :padding_right          => 0,
        :padding_top            => 0,
        :stroke_width           => 2,
        :show_vertical_labels   => false,
        :show_horizontal_labels => false,
        :hover_color            => '#000',
        :hover_text_color       => '#fff',
        :vertical_label_unit    => '',
        :colors                 => { :data => '#2f69bf' },
        :curve_amount           => 1,
        :focus_hint             => false
      }

    end

  end

end
