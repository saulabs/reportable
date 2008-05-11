ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do |t|
    t.string :login, :string
    t.timestamps
  end
end
