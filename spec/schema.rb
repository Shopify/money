ActiveRecord::Schema.define do
  create_table "money_records", :force => true do |t|
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
