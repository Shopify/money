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

  let(:mock_crypto_currency) do
    { 
      "usdc" => { 
        "iso_code" => "USDC", 
        "name" => "USD Coin",
        "symbol" => "USDC",
        "disambiguate_symbol" => "USDC",
        "subunit_to_unit" => 100,
        "smallest_denomination" => 1,
        "decimal_mark" => "."
      } 
    }
  end

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
    
    it "looks up crypto currencies when enabled" do
      
      allow(Money::Currency).to receive(:currencies).and_return({})
      allow(Money::Currency).to receive(:crypto_currencies).and_return(mock_crypto_currency)
      
      configure(experimental_crypto_currencies: true) do
        currency = Money::Currency.new('USDC')
        expect(currency.iso_code).to eq('USDC')
        expect(currency.symbol).to eq('USDC')
      end
    end

    it "doesn't look up crypto currencies when disabled" do
      configure(experimental_crypto_currencies: false) do
        expect(Money::Currency.find("USDC")).to be_nil
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
    
    it "returns a crypto currency when enabled" do
      allow(Money::Currency).to receive(:currencies).and_return({})
      allow(Money::Currency).to receive(:crypto_currencies).and_return(mock_crypto_currency)
      
      configure(experimental_crypto_currencies: true) do
        expect(Money::Currency.find('USDC')).not_to eq(nil)
        expect(Money::Currency.find('USDC').symbol).to eq("USDC")
      end
    end
    
    it "returns nil for crypto currency when disabled" do
      configure(experimental_crypto_currencies: false) do
        expect(Money.config.experimental_crypto_currencies).to eq(false)
        expect(Money::Currency.find('USDC')).to eq(nil)
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

  describe ".crypto_currencies" do
    it "loads crypto currencies from the loader" do
      old_currencies = Money::Currency.class_variable_get(:@@crypto_currencies) rescue nil
      Money::Currency.class_variable_set(:@@crypto_currencies, nil)
      
      allow(Money::Currency::Loader).to receive(:load_crypto_currencies).and_return(mock_crypto_currency)
      
      expect(Money::Currency.crypto_currencies).to eq(mock_crypto_currency)
      expect(Money::Currency.crypto_currencies).to eq(mock_crypto_currency) # Second call to verify caching
      expect(Money::Currency::Loader).to have_received(:load_crypto_currencies).once
      
      Money::Currency.class_variable_set(:@@crypto_currencies, old_currencies) if old_currencies
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
