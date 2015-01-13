class ReportableRenameModelName < ActiveRecord::Migration

  def self.up
    rename_column :reportable_cache, :model_name, :model_class_name
  end

  def self.down
    rename_column :reportable_cache, :model_class_name, :model_class_name
  end

end
