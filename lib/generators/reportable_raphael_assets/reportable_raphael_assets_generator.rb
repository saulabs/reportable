class ReportableRaphaelAssetsGenerator < Rails::Generators::Base

  include Rails::Generators::Actions

  source_root File.expand_path('../templates/', __FILE__)

  def create_raphael_file
    empty_directory('public/javascripts')
    copy_file(
      File.join(File.dirname(__FILE__), 'templates', 'raphael.min.js'),
      'public/javascripts/raphael.min.js'
    )
    copy_file(
      File.join(File.dirname(__FILE__), 'templates', 'g.raphael.min.js'),
      'public/javascripts/g.raphael.min.js'
    )
    copy_file(
      File.join(File.dirname(__FILE__), 'templates', 'g.line.min.js'),
      'public/javascripts/g.line.min.js'
    )
    readme(File.join(File.dirname(__FILE__), 'templates', 'NOTES'))
  end

end
