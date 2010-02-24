class ReportableMigrationGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|
      m.migration_template 'migration.erb', 'db/migrate'
    end
  end

end
