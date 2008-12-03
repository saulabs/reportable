ActiveRecord::Schema.define(:version => 1) do

  create_table :users, :force => true do |t|
    t.string  :login,          :null => false
    t.integer :profile_visits, :null => false, :default => 0

    t.timestamps
  end

  create_table :report_caches, :force => true do |t|
    t.string   :model_name,       :null => false
    t.string   :report_name,      :null => false
    t.string   :report_grouping,  :null => false
    t.float    :value,            :null => false, :default => 0
    t.datetime :reporting_period, :null => false

    t.timestamps
  end
  add_index :report_caches, [
    :model_name,
    :report_name,
    :report_grouping
  ], :name => 'report_caches_name_klass_grouping'
  add_index :report_caches, [
    :model_name, :report_name,
    :report_grouping,
    :reporting_period
  ], :unique => true, :name => 'report_caches_name_klass_grouping_period'

end
