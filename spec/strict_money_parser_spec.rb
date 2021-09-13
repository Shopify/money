# frozen_string_literal: true
require 'spec_helper'

RSpec.describe StrictMoneyParser do
  before(:each) do
    @parser = StrictMoneyParser
  end

  describe "parsing of amounts with period decimal separator" do
    it "parses an empty string to $0" do
      expect(@parser.parse("")).to eq(Money.new(0))
      expect { @parser.parse(nil) }.to raise_error(ArgumentError)
    end

    it "parses raises with an invalid string" do
      expect { @parser.parse("no money") }.to raise_error(Money::ParserError)
      expect { @parser.parse("1..1") }.to raise_error(Money::ParserError)
      expect { @parser.parse("$1") }.to raise_error(Money::ParserError)
      expect { @parser.parse("Rubbish $1.00 Rubbish") }.to raise_error(Money::ParserError)
      expect { @parser.parse("Rubbish$1.00Rubbish") }.to raise_error(Money::ParserError)
      expect { @parser.parse("--0.123") }.to raise_error(Money::ParserError)
      expect { @parser.parse("--0.123--") }.to raise_error(Money::ParserError)
      expect { @parser.parse("100,000.") }.to raise_error(Money::ParserError)
    end

    it "parses raise with an invalid when a currency is missing" do
      configure do
        expect { @parser.parse("1") }.to raise_error(Money::Currency::UnknownCurrency)
      end
    end

    it "parses a single digit integer string" do
      expect(@parser.parse("1")).to eq(Money.new(1.00))
    end

    it "parses a double digit integer string" do
      expect(@parser.parse("10")).to eq(Money.new(10.00))
    end

    it "parses a float string amount" do
      expect(@parser.parse("1.37")).to eq(Money.new(1.37))
    end

    it "parses a float string with a single digit after the decimal" do
      expect(@parser.parse("10.0")).to eq(Money.new(10.00))
    end

    it "parses a float string with two digits after the decimal" do
      expect(@parser.parse("10.00")).to eq(Money.new(10.00))
    end

    it "parses a negative integer amount in the hundreds" do
      expect(@parser.parse("-100")).to eq(Money.new(-100.00))
    end

    it "parses an integer amount in the hundreds" do
      expect(@parser.parse("410")).to eq(Money.new(410.00))
    end

    it "parses an amount ending with a . raises an error" do
      expect(@parser.parse("1.")).to eq(Money.new(1))
    end

    it "parses an amount starting with a ." do
      expect(@parser.parse(".12")).to eq(Money.new(0.12))
    end

    it "parses negative $1.00" do
      expect(@parser.parse("-1.00")).to eq(Money.new(-1.00))
    end

    it "parses a negative cents amount" do
      expect(@parser.parse("-0.90")).to eq(Money.new(-0.90))
    end

    it "parses amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0.123")).to eq(Money.new(0.12))
    end

    it "parses negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0.123")).to eq(Money.new(-0.12))
    end

    it "parses amount even if currency is usually associated with . thousands separator" do
      expect(@parser.parse("1.000", 'EUR')).to eq(Money.new(1, 'EUR'))
      expect(@parser.parse("1.000", 'JOD')).to eq(Money.new(1, 'JOD'))
      expect(@parser.parse("1.000", Money::NULL_CURRENCY)).to eq(Money.new(1, Money::NULL_CURRENCY))
    end

    it "parses amount with more than 3 decimals correctly" do
      expect(@parser.parse("1.11111111")).to eq(Money.new(1.11))
    end
  end

  describe "parsing of decimal cents amounts from 0 to 10" do
    it "parses 50.0" do
      expect(@parser.parse("50.0")).to eq(Money.new(50.00))
    end

    it "parses 50.1" do
      expect(@parser.parse("50.1")).to eq(Money.new(50.10))
    end

    it "parses 50.2" do
      expect(@parser.parse("50.2")).to eq(Money.new(50.20))
    end

    it "parses 50.3" do
      expect(@parser.parse("50.3")).to eq(Money.new(50.30))
    end

    it "parses 50.4" do
      expect(@parser.parse("50.4")).to eq(Money.new(50.40))
    end

    it "parses 50.5" do
      expect(@parser.parse("50.5")).to eq(Money.new(50.50))
    end

    it "parses 50.6" do
      expect(@parser.parse("50.6")).to eq(Money.new(50.60))
    end

    it "parses 50.7" do
      expect(@parser.parse("50.7")).to eq(Money.new(50.70))
    end

    it "parses 50.8" do
      expect(@parser.parse("50.8")).to eq(Money.new(50.80))
    end

    it "parses 50.9" do
      expect(@parser.parse("50.9")).to eq(Money.new(50.90))
    end

    it "parses 50.10" do
      expect(@parser.parse("50.10")).to eq(Money.new(50.10))
    end
  end

  describe "parsing of integer" do
    it "parses 1" do
      expect(@parser.parse(1)).to eq(Money.new(1))
    end

    it "parses 50" do
      expect(@parser.parse(50)).to eq(Money.new(50))
    end
  end

  describe "parsing of float" do
    it "parses 1.00" do
      expect(@parser.parse(1.00)).to eq(Money.new(1.00))
    end

    it "parses 1.32" do
      expect(@parser.parse(1.32)).to eq(Money.new(1.32))
    end

    it "parses 1.234" do
      expect(@parser.parse(1.234)).to eq(Money.new(1.234))
    end
  end

  describe "parsing money strings with thousands separator raises" do
    [
      '1,234,567.89',
      '1 234 567.89',
      '1 234 567,89',
      '1.234.567,89',
      '1˙234˙567,89',
      '12,34,567.89',
      "1'234'567.89",
      "1'234'567,89",
      '123,4567.89',
      ].each do |number|
        it "parses #{number}" do
          expect { @parser.parse(number) }.to raise_error(Money::ParserError)
        end
      end
  end
end
