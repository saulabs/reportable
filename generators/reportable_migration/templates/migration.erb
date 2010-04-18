class CreateReportableCache < ActiveRecord::Migration

  def self.up
    create_table :reportable_cache, :force => true do |t|
      t.string   :model_name,       :null => false
      t.string   :report_name,      :null => false
      t.string   :grouping,         :null => false
      t.string   :aggregation,      :null => false
      t.string   :conditions,       :null => false
      t.float    :value,            :null => false, :default => 0
      t.datetime :reporting_period, :null => false

      t.timestamps
    end

    add_index :reportable_cache, [
      :model_name,
      :report_name,
      :grouping,
      :aggregation,
      :conditions
    ], :name => :name_model_grouping_agregation
    add_index :reportable_cache, [
      :model_name,
      :report_name,
      :grouping,
      :aggregation,
      :conditions,
      :reporting_period
    ], :unique => true, :name => :name_model_grouping_aggregation_period
  end

  def self.down
    remove_index :reportable_cache, :name => :name_model_grouping_agregation
    remove_index :reportable_cache, :name => :name_model_grouping_aggregation_period

    drop_table :reportable_cache
  end

end
