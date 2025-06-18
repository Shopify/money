# frozen_string_literal: true
ActiveRecord::Schema.define do
  create_table "money_records", :force => true do |t|
    t.decimal  "price", precision: 20, scale: 3, default: '0.000'
    t.string   "price_currency", limit: 3
    t.decimal  "prix", precision: 20, scale: 3, default: '0.000'
    t.string   "prix_currency", limit: 3
    t.decimal  "price_usd"
  end
end
