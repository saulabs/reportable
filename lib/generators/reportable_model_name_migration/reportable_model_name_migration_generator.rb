class ReportableModelNameMigrationGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  include Rails::Generators::Migration

  def create_reportable_model_name_migration
    migration_template('migration.rb', 'db/migrate/reportable_rename_model_name.rb')
  end

  def self.next_migration_number(dirname)
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end


end
