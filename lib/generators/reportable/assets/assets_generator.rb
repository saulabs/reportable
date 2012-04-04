module Reportable
  module Generators
    class AssetsGenerator < Rails::Generators::Name
      include Rails::Generators::Actions

      def main
        case name 
        when 'flot'
          create_jquery_flot_file
        when 'raphael'
          create_raphael_file
        else
          raise "Assets supported are: 'raphael' and 'flot'"
        end
      end

      protected

      def source_path
        File.join(File.dirname(__FILE__), 'templates')
      end

      def src_path name = :raphael
        File.join(source_path, name.to_s)
      end

      def target_path name = :raphael
        "app/assets/javascripts/#{name}"
      end

      def copy_js name, file
        copy_file(
          File.join(src_path(name), file),
          File.join(target_path(name, file)
        )
      end        

      def create_raphael_file
        empty_directory target_path :raphael
        copy_js :raphael, 'raphael.min.js'
        copy_js :raphael, 'g.raphael.min.js'
        copy_js :raphael, 'g.line.min.js'
        readme  File.join(src_path(:raphael), 'NOTES'))
      end

      def create_jquery_flot_file
        empty_directory target_path :raphael
        copy_js :flot, 'jquery.flot.min.js'
        copy_js :flot, 'excanvas.min.js'
        readme  File.join(src_path(:flot), 'NOTES'))
      end
    end
  end
end