ActiveRecord::Schema.define(:version => 1) do

  create_table :users, :force => true do |t|
    t.string  :login,          :null => false
    t.integer :profile_visits, :null => false, :default => 0
    t.string  :type,           :null => false, :default => 'User'

    t.timestamps
  end

  create_table :reportable_cache, :force => true do |t|
    t.string   :model_name,       :null => false, :limit => 100
    t.string   :report_name,      :null => false, :limit => 100
    t.string   :grouping,         :null => false, :limit => 10
    t.string   :aggregation,      :null => false, :limit => 10
    t.string   :conditions,       :null => false, :limit => 100
    t.float    :value,            :null => false,                :default => 0
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
