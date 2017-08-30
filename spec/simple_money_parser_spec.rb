require 'spec_helper'

RSpec.describe SimpleMoneyParser do
  describe "amounts without currency" do
    it "raises an error for an empty string" do
      expect { described_class.parse("") }.to raise_error(SimpleMoneyParser::ParseError)
    end

    it "raises an error for an invalid string" do
      expect { described_class.parse("no money") }.to raise_error(SimpleMoneyParser::ParseError)
    end

    it "parses a float string amount" do
      expect(described_class.parse("1.37")).to eq(Money.new(1.37, 'CAD'))
    end

    it "parses negative float string " do
      expect(described_class.parse("-1.00")).to eq(Money.new(-1.00, 'CAD'))
    end

    it "parses a negative integer without decimals" do
      expect(described_class.parse("-100")).to eq(Money.new(-100.00, 'CAD'))
    end

    it "parses a negative cents amount" do
      expect(described_class.parse("-0.90")).to eq(Money.new(-0.90, 'CAD'))
    end

    it "falls back to the current currency when no currency is parsed" do
      result = Money.with_currency('EUR') { described_class.parse("1.23") }
      expect(result).to eq(Money.new(1.23, 'EUR'))
    end
  end

  describe "amounts with currency" do
    it "parses a float string with a single digit after the decimal" do
      expect(described_class.parse("10.0 USD")).to eq(Money.new(10.00, 'USD'))
    end

    it "parses a float string with two digits after the decimal" do
      expect(described_class.parse("10.00 USD")).to eq(Money.new(10.00, 'USD'))
    end

    it "parses amount with 3 decimals and 0 dinar amount" do
      expect(described_class.parse("0.123 JOD")).to eq(Money.new(0.123, 'JOD'))
    end

    it "parses negative amount with 3 decimals and 0 dinar amount" do
      expect(described_class.parse("-0.123 JOD")).to eq(Money.new(-0.123, 'JOD'))
    end

    it "rounds too many decimals" do
      expect(described_class.parse("1.235 EUR")).to eq(Money.new(1.24, 'EUR'))
    end
  end
end
