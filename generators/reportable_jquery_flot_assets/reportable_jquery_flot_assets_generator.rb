class ReportableJqueryFlotAssetsGenerator < Rails::Generators::Base

  include Rails::Generators::Actions

  source_root File.expand_path('../templates/', __FILE__)

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
