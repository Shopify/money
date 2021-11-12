# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "NullCurrency" do
  let (:null_currency) { Money::NULL_CURRENCY }

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

  describe "#to_s" do
    it 'is shown as an empty string' do
      expect(null_currency.to_s).to eq('')
    end
  end

  describe "#compatible" do
    it "returns true for currency" do
      expect(null_currency.compatible?(Money::Currency.new('USD'))).to eq(true)
      expect(null_currency.compatible?(Money::Currency.new('JPY'))).to eq(true)
    end

    it "returns true for null_currency" do
      expect(null_currency.compatible?(Money::NULL_CURRENCY)).to eq(true)
    end

    it "returns false for nil" do
      expect(null_currency.compatible?(nil)).to eq(false)
    end
  end
end
