# Generates the migration that adds the caching table
class ReportsAsSparklineMigrationGenerator < Rails::Generator::NamedBase

  # Creates the generator's manifest
  def manifest
    record do |m|
      m.migration_template 'migration.erb', 'db/migrate'
    end
  end

end
