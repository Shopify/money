ActiveRecord::Schema.define do
  create_table "money_records", :force => true do |t|
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "currency_money_records", :force => true do |t|
    t.decimal  "price"
    t.string   "currency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_currency_money_records", :force => true do |t|
    t.decimal  "price"
    t.string   "custom_currency"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
