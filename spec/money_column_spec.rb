require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  money_column :price
  validates :price, numericality: true
end

describe "MoneyColumn" do

  it "typecasts string to money" do
    m = MoneyRecord.new(:price => '1.01')
    expect(m.price).to eq(Money.new(1.01))
  end

  it "typecasts numeric to money" do
    m = MoneyRecord.new(:price => 100)
    expect(m.price).to eq(Money.new(100))
  end

  it "typecasts blank to nil" do
    m = MoneyRecord.new(:price => "")
    expect(m.price).to eq(nil)
  end

  it "typecasts invalid string to empty money" do
    m = MoneyRecord.new(:price => "magic")
    expect(m.price).to eq(Money.new(0))
  end

  it "typecasts value that does not respond to to_money as nil" do
    m = MoneyRecord.new(:price => true)
    expect(m.price).to eq(nil)
  end

  it "validates properly" do
    m = MoneyRecord.new(:price => '1.00')
    expect(m.valid?).to eq(true)
  end
end
