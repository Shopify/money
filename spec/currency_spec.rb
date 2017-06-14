require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Currency" do
  let(:currency) { Money::Currency.new('usd') }
  let(:currency_data) {{
    "iso_code": "USD",
    "name": "United States Dollar",
    "subunit_to_unit": 100,
    "iso_numeric": "840",
    "smallest_denomination": 1
  }}

  describe "#new" do
    it "is constructable with a uppercase string" do
      expect(Money::Currency.new('USD').iso_code).to eq('USD')
    end

    it "is constructable with a symbol" do
      expect(Money::Currency.new(:usd).iso_code).to eq('USD')
    end

    it "is constructable with a lowercase string" do
      expect(Money::Currency.new('usd').iso_code).to eq('USD')
    end

    it "has currency data accessible" do
      currency_data.keys.each do |attribute|
        expect(currency.public_send(attribute)).to eq(currency_data[attribute])
      end
    end

    it "raises if the currency is invalid" do
      expect { Money::Currency.new('yyy') }.to raise_error(Money::Currency::UnknownCurrency)
    end
  end

  describe "#eql?" do
    it "returns true when both objects have the same iso_code" do
      expect(currency == Money.new(1, 'USD').currency).to eq(true)
    end

    it "returns true when both objects represent the same currency" do
      expect(currency.eql?(Money.new(1, 'USD').currency)).to eq(true)
    end

    it "returns true when both objects represent the same currency" do
      expect(currency.eql?(Money.new(1, 'CAD').currency)).to eq(false)
    end
  end

  describe "#to_s" do
    it "to return the iso code string" do
      expect(currency.to_s).to eq('USD')
    end
  end
end
