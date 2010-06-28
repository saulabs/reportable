if Saulabs::Reportable::RailsAdapter::IS_RAILS3

  class ReportableMigrationGenerator < Rails::Generators::Base

    include Rails::Generators::Migration

    def create_migration
      migration_template(
        File.join(File.dirname(__FILE__), 'templates', 'migration.rb'),
        'db/migrate/create_reportable_cache.rb'
      )
    end

    def self.next_migration_number(dirname)
      if ActiveRecord::Base.timestamped_migrations
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      else
        "%.3d" % (current_migration_number(dirname) + 1)
      end
    end

  end

else

  class ReportableMigrationGenerator < Rails::Generator::Base

    def manifest
      record do |m|
        m.migration_template('migration.rb', 'db/migrate')
      end
    end

    def file_name
      'create_reportable_cache'
    end

  end

end
