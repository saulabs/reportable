module Simplabs #:nodoc:

  module ReportsAsSparkline #:nodoc:

    module SparklineTagHelper

      # Renders a sparkline with the given data.
      #
      # ==== Parameters
      #
      # * <tt>data</tt> - The data to render the sparkline for, is retrieved from a report like <tt>User.registration_report</tt>
      #
      # ==== Options
      #
      # * <tt>width</tt> - The width of the generated image
      # * <tt>height</tt> - The height of the generated image
      # * <tt>line_color</tt> - The line color of the sparkline (hex code)
      # * <tt>fill_color</tt> - The color to fill the area below the sparkline with (hex code)
      # * <tt>labels</tt> - The axes to render lables for (Array of <tt>:x</tt>, <tt>:y+</tt>, <tt>:r</tt>, <tt>:t</tt>; this is x axis, y axis, right, top)
      # * <tt>alt</tt> - The HTML img alt tag
      # * <tt>title</tt> - The HTML img title tag
      #
      # ==== Example
      # <tt><%= sparkline_tag(User.registrations_report, :width => 200, :height => 100, :color => '000') %></tt>
      def sparkline_tag(data, options = {})
        options.reverse_merge!({ :width => 300, :height => 34, :line_color => '0077cc', :fill_color => 'e6f2fa', :labels => [], :alt => '', :title => '' })
        data = data.collect { |d| d[1] }
        labels = ""
        unless options[:labels].empty?
          chxr = {}
          options[:labels].each_with_index do |l, i|
            chxr[l] = "#{i}," + ([:x, :t].include?(l) ? "0,#{data.length}" : "#{[data.min, 0].min},#{data.max}")
          end
          labels = "&chxt=#{options[:labels].map(&:to_s).join(',')}&chxr=#{options[:labels].collect{|l| chxr[l]}.join('|')}"
        end
        image_tag(
          "http://chart.apis.google.com/chart?cht=ls&chs=#{options[:width]}x#{options[:height]}&chd=t:#{data.join(',')}&chco=#{options[:line_color]}&chm=B,#{options[:fill_color]},0,0,0&chls=1,0,0&chds=#{data.min},#{data.max}#{labels}",
          :alt => options[:alt],
          :title => options[:title]
        )
      end

    end

  end

end
