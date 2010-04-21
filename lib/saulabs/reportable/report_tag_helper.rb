require 'saulabs/reportable/config'

module Saulabs

  module Reportable

    module ReportTagHelper

      # Renders a sparkline with the given data using the google drawing api.
      #
      # @param [Array<Array<DateTime, Float>>] data
      #   an array of report data as returned by {Saulabs::Reportable::Report#run}
      # @param [Hash] options
      #   options for the sparkline
      #
      # @option options [Fixnum] :width (300)
      #   the width of the generated image
      # @option options [Fixnum] :height (34)
      #   the height of the generated image
      # @option options [String] :line_color ('0077cc')
      #   the line color of the generated image
      # @option options [String] :fill_color ('e6f2fa')
      #   the fill color of the generated image
      # @option options [Array<Symbol>] :labels ([])
      #   the axes to render lables for (Array of +:x+, +:y+, +:r+, +:t+; this is x axis, y axis, right, top)
      # @option options [String] :alt ('')
      #   the alt attribute for the generated image
      # @option options [String] :title ('')
      #   the title attribute for the generated image
      #
      # @return [String]
      #   an image tag showing a sparkline for the passed +data+
      #
      # @example Rendering a sparkline tag for report data
      #
      #   <%= report_tag(User.registrations_report, :width => 200, :height => 100, :color => '000') %>
      #
      def google_report_tag(data, options = {})
        options.reverse_merge!({ :width => 300, :height => 34, :line_color => '0077cc', :fill_color => 'e6f2fa', :labels => [], :alt => '', :title => '' })
        data = data.collect { |d| d[1] }
        labels = ''
        unless options[:labels].empty?
          chxr = {}
          options[:labels].each_with_index do |l, i|
            chxr[l] = "#{i}," + ([:x, :t].include?(l) ? "0,#{data.length}" : "#{[data.min, 0].min},#{data.max}")
          end
          labels = "&chxt=#{options[:labels].map(&:to_s).join(',')}&chxr=#{options[:labels].collect{|l| chxr[l]}.join('|')}"
        end
        title = ''
        unless options[:title].empty?
          title = "&chtt=#{options[:title]}"
        end
        image_tag(
          "http://chart.apis.google.com/chart?cht=ls&chs=#{options[:width]}x#{options[:height]}&chd=t:#{data.join(',')}&chco=#{options[:line_color]}&chm=B,#{options[:fill_color]},0,0,0&chls=1,0,0&chds=#{data.min},#{data.max}#{labels}#{title}",
          :alt   => options[:alt],
          :title => options[:title]
        )
      end

    
      # Renders a sparkline with the given data using grafico.
      #
      # @param [Array<Array<DateTime, Float>>] data
      #   an array of report data as returned by {Saulabs::Reportable::Report#run}
      # @param [Hash] options
      #   options for width, height, the dom id and the format
      # @param [Hash] grafico_options
      #   options for grafico which to_json get called on, 
      #   see the grafico documentation for more information.
      #
      # @option options [Fixnum] :width (300)
      #   the width of the generated graph
      # @option options [Fixnum] :height (34)
      #   the height of the generated graph
      # @option options [Array<Symbol>] :dom_id ("reportable_#{Time.now.to_i}")
      #   the dom id of the generated div
      #
      # @return [String]
      #   an div tag and the javascript code showing a sparkline for the passed +data+
      #
      # @example Rendering a sparkline tag for report data
      #
      #   <%= report_tag(User.registrations_report, {:width => 200, :height => 100, :format => "div(100).to_i"}, {:vertical_label_unit => "registrations"}) %>
      #
      def grafico_report_tag(data, options = {}, grafico_options = {})
        options.reverse_merge!(
        { 
          :width => 300, 
          :height => 100, 
          :dom_id => "reportable_#{Time.now.to_i}", 
          :format => 'to_i'
        })
        grafico_options.reverse_merge!(
        {
          :area_opacity => 0.3,
          :markers => 'value',
          :grid => false,
          :draw_axis => false,
          :plot_padding => 0,
          :padding_left =>0,
          :padding_bottom => 0,
          :padding_right => 0,
          :padding_top => 0,
          :stroke_width => 2,
          :show_vertical_labels => false,
          :show_horizontal_labels => false,
          :hover_color => '#000',
          :hover_text_color => '#fff',
          :vertical_label_unit => '',
          :colors => { :data => '#2F69BF' },
          :curve_amount => 1,
          :focus_hint => false
        })
        %Q{<div id="#{options[:dom_id]}" style="width:#{options[:width]}px;height:#{options[:height]}px;"></div>
        <script type="text/javascript" charset="utf-8">
          new Grafico.AreaGraph(
            $('#{options[:dom_id]}'), 
            { data: #{data.map{|d| eval options[:format], d[1].send(:binding) }.to_json} },
            #{grafico_options.to_json});
        </script>}
      end
    
    end
  end

end
