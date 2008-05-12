ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do |t|
    t.string :login, :string
    t.timestamps
  end
  
  create_table :report_caches, :force => true do |t|
    t.string :model_name
    t.string :report_name
    t.string :report_range
    t.float :value
    t.datetime :start
      
    t.timestamps
  end
  add_index :report_caches, [:model_name, :report_name, :report_range, :start], :unique => true, :name => "report_caches_uk"
end
