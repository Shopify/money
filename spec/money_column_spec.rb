require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  money_column :price
  validates :price, numericality: true
end

class CurrencyMoneyRecord < ActiveRecord::Base
  money_column :price
end

class CustomCurrencyMoneyRecord < ActiveRecord::Base
  money_column :price, currency_column: 'custom_currency'
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

  it "typecasts money with missing currency column" do
    m = MoneyRecord.new(price: Money.new(1.01, 'cad'))
    expect(m.price).to eq(Money.new(1.01, 'XXX'))
  end

  it "typecasts money with currency" do
    m = CurrencyMoneyRecord.new(price: 1.01, currency: 'cad')
    expect(m.price).to eq(Money.new(1.01, 'CAD'))
  end

  it "typecasts money with a custom currency column" do
    m = CustomCurrencyMoneyRecord.new(price: 1.01, custom_currency: 'cad')
    expect(m.price).to eq(Money.new(1.01, 'CAD'))
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

  it "does not save the currency but shows a deprecation warning" do
    m = CustomCurrencyMoneyRecord.new(price: 1.01, custom_currency: 'cad')
    expect(Money).to receive(:deprecate).once
    m.price = Money.new(10, 'USD')
    expect(m.price).to eq(Money.new(10, 'CAD'))
  end
end
