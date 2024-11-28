# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Currency" do
  CURRENCY_DATA = {
    "iso_code": "USD",
    "name": "United States Dollar",
    "subunit_to_unit": 100,
    "iso_numeric": "840",
    "smallest_denomination": 1,
    "minor_units": 2,
    "symbol": '$',
    "disambiguate_symbol": "US$",
    "subunit_symbol": "¢",
    "decimal_mark": ".",
  }

  let(:currency) { Money::Currency.new('usd') }

  describe ".new" do
    it "is constructable with a uppercase string" do
      expect(Money::Currency.new('USD').iso_code).to eq('USD')
    end

    it "is constructable with a symbol" do
      expect(Money::Currency.new(:usd).iso_code).to eq('USD')
    end

    it "is constructable with a lowercase string" do
      expect(Money::Currency.new('usd').iso_code).to eq('USD')
    end

    it "raises when the currency is invalid" do
      expect { Money::Currency.new('yyy') }.to raise_error(Money::Currency::UnknownCurrency)
    end

    it "raises when the currency is nil" do
      expect { Money::Currency.new(nil) }.to raise_error(Money::Currency::UnknownCurrency)
    end

    it "returns currency object" do
      expect(Money::Currency.new("usd")).to be_instance_of(Money::Currency)
    end

    it "raises on unknown currency" do
      expect { Money::Currency.new("XXX") }.to raise_error(Money::Currency::UnknownCurrency)
    end

    context "with experimental: true" do
      it "allows creation of crypto currencies" do
        currency = Money::Currency.new("USDC", experimental: true)
        expect(currency.iso_code).to eq("USDC")
        expect(currency.name).to eq("USD Coin")
      end

      it "maintains separate cache for experimental currencies" do
        regular_usd = Money::Currency.new("USD")
        experimental_usdc = Money::Currency.new("USDC", experimental: true)
        
        expect(regular_usd.object_id).not_to eq(experimental_usdc.object_id)
        expect(Money::Currency.new("USDC", experimental: true).object_id).to eq(experimental_usdc.object_id)
      end

      it "raises on unknown crypto currency" do
        expect { Money::Currency.new("UNKNOWN", experimental: true) }.to raise_error(Money::Currency::UnknownCurrency)
      end
    end

    context "with experimental: false" do
      it "raises on crypto currencies" do
        expect { Money::Currency.new("USDC") }.to raise_error(Money::Currency::UnknownCurrency)
      end
    end
  end

  describe ".find" do
    it "returns nil when the currency is invalid" do
      expect(Money::Currency.find('yyy')).to eq(nil)
    end

    it "returns a valid currency" do
      expect(Money::Currency.find('usd')).to eq(Money::Currency.new('usd'))
    end

    context "with experimental: true" do
      it "finds crypto currencies" do
        expect(Money::Currency.find("USDC", experimental: true)).to be_a(Money::Currency)
      end

      it "returns nil for unknown crypto currencies" do
        expect(Money::Currency.find("UNKNOWN", experimental: true)).to be_nil
      end
    end

    context "with experimental: false" do
      it "returns nil for crypto currencies" do
        expect(Money::Currency.find("USDC")).to be_nil
      end
    end
  end

  describe ".find!" do
    it "raises when the currency is invalid" do
      expect { Money::Currency.find!('yyy') }.to raise_error(Money::Currency::UnknownCurrency)
    end

    it "returns a valid currency" do
      expect(Money::Currency.find!('CAD')).to eq(Money::Currency.new('CAD'))
    end
  end

  CURRENCY_DATA.each do |attribute, value|
    describe "##{attribute}" do
      it 'returns the correct value' do
        expect(currency.public_send(attribute)).to eq(value)
      end
    end
  end

  describe "#eql?" do
    it "returns true when both objects represent the same currency" do
      expect(currency.eql?(Money.new(1, 'USD').currency)).to eq(true)
    end

    it "returns false when the currency iso is different" do
      expect(currency.eql?(Money.new(1, 'CAD').currency)).to eq(false)
    end
  end

  describe "#hash" do
    specify "equal currencies from different loaders have the same hash" do
      currency_1 = Money::Currency.find('USD')
      currency_2 = yaml_load(Money::Currency.find('USD').to_yaml)

      expect(currency_1.eql?(currency_2)).to eq(true)
      expect(currency_1.hash).to eq(currency_2.hash)
    end
  end

  describe "==" do
    it "returns true when both objects have the same currency" do
      expect(currency == Money.new(1, 'USD').currency).to eq(true)
    end

    it "returns false when the currency iso is different" do
      expect(currency == Money.new(1, 'CAD').currency).to eq(false)
    end
  end

  describe "#to_s" do
    it "to return the iso code string" do
      expect(currency.to_s).to eq('USD')
    end
  end

  describe "#compatible" do

    it "returns true for the same currency" do
      expect(currency.compatible?(Money::Currency.new('USD'))).to eq(true)
    end

    it "returns true for null_currency" do
      expect(currency.compatible?(Money::NULL_CURRENCY)).to eq(true)
    end

    it "returns false for nil" do
      expect(currency.compatible?(nil)).to eq(false)
    end

    it "returns false for a different currency" do
      expect(currency.compatible?(Money::Currency.new('JPY'))).to eq(false)
    end
  end
end
