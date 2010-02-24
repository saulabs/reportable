module Saulabs

  module Reportable

    module SparklineTagHelper

      # Renders a sparkline with the given data.
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
      # @returns [String]
      #   an image tag showing a sparkline for the passed +data+
      #
      # @example Rendering a sparkline tag for report data
      #
      #   <%= sparkline_tag(User.registrations_report, :width => 200, :height => 100, :color => '000') %>
      #
      def sparkline_tag(data, options = {})
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

    end

  end

end
