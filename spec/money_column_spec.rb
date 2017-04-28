require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MoneyRecord < ActiveRecord::Base
  money_column :price
end

describe "MoneyColumn" do

  it "accepts money" do
    m = MoneyRecord.new(price: Money.new(100))

    expect(m.price).to eq(Money.new(100))
    m.save!
    m.reload
    expect(m.price).to eq(Money.new(100))
  end

  it "accepts nil" do
    m = MoneyRecord.new(price: nil)

    expect(m.price).to eq(nil)
    m.save!
    m.reload
    expect(m.price).to eq(nil)
  end

  it "typecasts string to money" do
    m = MoneyRecord.new(price: "100")

    expect(m.price).to eq(Money.new(100))
    m.save!
    m.reload
    expect(m.price).to eq(Money.new(100))
  end

  it "typecasts numeric to money" do
    m = MoneyRecord.new(price: 100)

    expect(m.price).to eq(Money.new(100))
    m.save!
    m.reload
    expect(m.price).to eq(Money.new(100))
  end

  it "typecasts blank to nil" do
    m = MoneyRecord.new(price: "")

    expect(m.price).to eq(nil)
    m.save!
    m.reload
    expect(m.price).to eq(nil)
  end

  it "typecasts invalid string to empty money" do
    m = MoneyRecord.new(price: "magic")

    expect(m.price).to eq(Money.new(0))
    m.save!
    m.reload
    expect(m.price).to eq(Money.new(0))
  end

  it "typecasts value that does not respond to to_money as nil" do
    m = MoneyRecord.new(price: true)

    expect(m.price).to eq(nil)
    m.save!
    m.reload
    expect(m.price).to eq(nil)
  end
end
