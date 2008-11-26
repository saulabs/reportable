module Kvlr #:nodoc:

  module ReportsAsSparkline #:nodoc:

    # View helper that provides sparkline methods
    module AssetTagHelper

      # Renders a sparkline with the given data.
      def sparkline_tag(data, options = {})
        options.reverse_merge!({:width => 300, :height => 34, :color => '0077CC'})
        data.collect! { |element| element[1].to_i }
        image_tag(
          "http://chart.apis.google.com/chart?cht=ls&chs=#{options[:width]}x#{options[:height]}&chd=t:#{data.join(',')}&chco=#{options[:color]}&chm=B,E6F2FA,0,0,0&chls=1,0,0&chds=#{data.min},#{data.max}"
        )
      end

    end

  end

end
