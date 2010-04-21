if Saulabs::Reportable::IS_RAILS3

  class ReportableAssetsGenerator < Rails::Generators::Base

    include Rails::Generators::Actions

    def create_grafico_file
      empty_directory('public/javascripts')
      copy_file(
        File.join(File.dirname(__FILE__), 'templates', 'raphael.js'),
        'public/javascripts/raphael.js'
      )
      copy_file(
        File.join(File.dirname(__FILE__), 'templates', 'grafico.min.js'),
        'public/javascripts/grafico.min.js'
      )
      readme(File.join(File.dirname(__FILE__), 'templates', 'NOTES'))
    end

  end

else

  class ReportableAssetsGenerator < Rails::Generator::Base

    def manifest
      record do |m|
        m.directory('public/javascripts')
        m.file('raphael.js', 'public/javascripts/raphael.js')
        m.file('grafico.min.js', 'public/javascripts/grafico.min.js')
        m.readme('NOTES')
      end
    end

  end

end
