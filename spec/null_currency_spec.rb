require 'spec_helper'

describe "NullCurrency" do
  let (:null_currency) {Money::NullCurrency.new}

  it 'exposes the same public interface as Currency' do
    expect(Money::NullCurrency).to quack_like Money::Currency
  end

  describe "#initialize" do
    it "has a valid XXX iso4217 currency code" do
      expect(null_currency.iso_code).to eq('XXX')
    end

    it "quacks like USD" do
      expect(null_currency.symbol).to eq('$')
      expect(null_currency.subunit_to_unit).to eq(100)
      expect(null_currency.smallest_denomination).to eq(1)
    end

    it "has the name No Currency" do
      expect(null_currency.name).to eq('No Currency')
    end
  end

  describe "#compatible" do
    it "returns true for currency" do
      expect(null_currency.compatible?(Money::Currency.new('USD'))).to eq(true)
      expect(null_currency.compatible?(Money::Currency.new('JPY'))).to eq(true)
    end

    it "returns true for null_currency" do
      expect(null_currency.compatible?(Money::NullCurrency.new)).to eq(true)
    end

    it "returns false for nil" do
      expect(null_currency.compatible?(nil)).to eq(false)
    end
  end
end
