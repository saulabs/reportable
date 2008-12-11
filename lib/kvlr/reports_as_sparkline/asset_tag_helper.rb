module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    module AssetTagHelper

      # Renders a sparkline with the given data.
      #
      # ==== Parameters
      #
      # *<tt>data</tt> - The data to render the sparkline for
      #
      # ==== Options
      #
      # *<tt>width</tt> - The width of the generated image
      # *<tt>height</tt> - The height of the generated image
      # *<tt>color</tt> - The base color of the generated image (hex code)
      #
      # ==== Example
      # <%= sparkline_tag(User.registrations_report, :width => 200, :height => 100, :color => '000') %>
      def sparkline_tag(data, options = {})
        options.reverse_merge!({:width => 300, :height => 34, :color => '0077cc'})
        data.collect! { |element| element[1].to_s }
        image_tag(
          "http://chart.apis.google.com/chart?cht=ls&chs=#{options[:width]}x#{options[:height]}&chd=t:#{data.join(',')}&chco=#{options[:color]}&chm=B,E6F2FA,0,0,0&chls=1,0,0&chds=#{data.min},#{data.max}"
        )
      end

    end

  end

end
