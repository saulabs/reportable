if Saulabs::Reportable::IS_RAILS3

  class ReportableGraficoAssetsGenerator < Rails::Generators::Base

    include Rails::Generators::Actions

    def create_grafico_file
      empty_directory('public/javascripts')
      copy_file(
        File.join(File.dirname(__FILE__), 'templates', 'raphael.min.js'),
        'public/javascripts/raphael.min.js'
      )
      readme(File.join(File.dirname(__FILE__), 'templates', 'NOTES'))
    end

  end

else

  class ReportableGraficoAssetsGenerator < Rails::Generator::Base

    def manifest
      record do |m|
        m.directory('public/javascripts')
        m.file('raphael.min.js', 'public/javascripts/raphael.min.js')
        m.readme('NOTES')
      end
    end

  end

end
