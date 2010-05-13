if Saulabs::Reportable::IS_RAILS3

  class ReportableJqueryFlotAssetsGenerator < Rails::Generators::Base

    include Rails::Generators::Actions

    def create_jquery_flot_file
      empty_directory('public/javascripts')
      copy_file(
        File.join(File.dirname(__FILE__), 'templates', 'jquery.flot.min.js'),
        'public/javascripts/jquery.flot.min.js'
      )
      copy_file(
        File.join(File.dirname(__FILE__), 'templates', 'excanvas.min.js'),
        'public/javascripts/excanvas.min.js'
      )
      readme(File.join(File.dirname(__FILE__), 'templates', 'NOTES'))
    end

  end

else

  class ReportableJqueryFlotAssetsGenerator < Rails::Generator::Base

    def manifest
      record do |m|
        m.directory('public/javascripts')
        m.file('jquery.flot.min.js', 'public/javascripts/jquery.flot.min.js')
        m.file('excanvas.min.js', 'public/javascripts/excanvas.min.js')
        m.readme('NOTES')
      end
    end

  end

end
