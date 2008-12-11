class ReportsAsSparklineMigrationGenerator < Rails::Generator::NamedBase #:nodoc:

  def manifest
    record do |m|
      m.migration_template 'migration.erb', 'db/migrate'
    end
  end

end
