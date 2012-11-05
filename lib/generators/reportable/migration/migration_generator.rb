module Reportable
  module Generators
    class MigrationGenerator < Rails::Generators::Base

      include Rails::Generators::Migration

      def create_migration
        migration_template(
          File.join(src_path, 'migration.rb'),
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

      protected

      def src_path
        File.dirname(__FILE__), 'templates'
      end

    end
  end
end