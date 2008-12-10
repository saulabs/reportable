ActiveRecord::Schema.define(:version => 1) do

  create_table :users, :force => true do |t|
    t.string  :login,          :null => false
    t.integer :profile_visits, :null => false, :default => 0
    t.string  :type,           :null => false, :default => 'User'

    t.timestamps
  end

  create_table :report_caches, :force => true do |t|
    t.string   :model_name,       :null => false
    t.string   :report_name,      :null => false
    t.string   :grouping,         :null => false
    t.string   :aggregation,      :null => false
    t.float    :value,            :null => false, :default => 0
    t.string   :reporting_period, :null => false

    t.timestamps
  end
  add_index :report_caches, [
    :model_name,
    :report_name,
    :grouping,
    :aggregation
  ], :name => 'name_model_grouping_agregation'
  add_index :report_caches, [
    :model_name,
    :report_name,
    :grouping,
    :aggregation,
    :reporting_period
  ], :unique => true, :name => 'name_model_grouping_aggregation_period'

end
