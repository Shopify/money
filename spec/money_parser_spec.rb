require 'spec_helper'

RSpec.describe MoneyParser do
  before(:each) do
    @parser = MoneyParser
  end

  describe "parsing of amounts with period decimal separator" do
    it "parses an empty string to $0" do
      expect(@parser.parse("")).to eq(Money.zero)
    end

    it "parses an invalid string to $0" do
      expect(Money).to receive(:deprecate).twice
      expect(@parser.parse("no money")).to eq(Money.zero)
      expect(@parser.parse("1..")).to eq(Money.zero)
    end

    it "parses raise with an invalid string and strict option" do
      expect { @parser.parse("no money", strict: true) }.to raise_error(MoneyParser::MoneyFormatError)
    end

    it "parses a single digit integer string" do
      expect(@parser.parse("1")).to eq(Money.new(1.00))
    end

    it "parses a double digit integer string" do
      expect(@parser.parse("10")).to eq(Money.new(10.00))
    end

    it "parses an integer string amount with a leading $" do
      expect(@parser.parse("$1")).to eq(Money.new(1.00))
    end

    it "parses a float string amount" do
      expect(@parser.parse("1.37")).to eq(Money.new(1.37))
    end

    it "parses a float string amount with a leading $" do
      expect(@parser.parse("$1.37")).to eq(Money.new(1.37))
    end

    it "parses a float string with a single digit after the decimal" do
      expect(@parser.parse("10.0")).to eq(Money.new(10.00))
    end

    it "parses a float string with two digits after the decimal" do
      expect(@parser.parse("10.00")).to eq(Money.new(10.00))
    end

    it "parses the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1.00 Rubbish")).to eq(Money.new(1.00))
    end

    it "parses the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1.00Rubbish")).to eq(Money.new(1.00))
    end

    it "parses a negative integer amount in the hundreds" do
      expect(@parser.parse("-100")).to eq(Money.new(-100.00))
    end

    it "parses an integer amount in the hundreds" do
      expect(@parser.parse("410")).to eq(Money.new(410.00))
    end

    it "parses an amount ending with a ." do
      expect(@parser.parse("1.")).to eq(Money.new(1))
      expect(@parser.parse("100,000.")).to eq(Money.new(100_000))
    end

    it "parses an amount starting with a ." do
      expect(@parser.parse(".12")).to eq(Money.new(0.12))
    end

    it "parses a positive amount with a thousands separator" do
      expect(@parser.parse("100,000.00")).to eq(Money.new(100_000.00))
    end

    it "parses a negative amount with a thousands separator" do
      expect(@parser.parse("-100,000.00")).to eq(Money.new(-100_000.00))
    end

    it "parses a positive amount with a thousands separator with no decimal" do
      expect(@parser.parse("1,000")).to eq(Money.new(1_000))
    end

    it "parses a positive amount with a thousands separator with no decimal with a currency" do
      expect(@parser.parse("1,000", 'JOD')).to eq(Money.new(1_000, 'JOD'))
    end

    it "parses a positive amount with a thousands separator with no decimal" do
      expect(@parser.parse("12,34,567.89", 'INR')).to eq(Money.new(1_234_567.89, 'INR'))
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

    it "parses negative amount with multiple leading - signs" do
      expect(@parser.parse("--0.123")).to eq(Money.new(-0.12))
    end

    it "parses negative amount with multiple - signs" do
      expect(@parser.parse("--0.123--")).to eq(Money.new(-0.12))
    end

    it "parses a positive amount with a thousands separator with no decimal" do
      expect(@parser.parse("1.000")).to eq(Money.new(1_000))
    end

    it "parses a positive amount with a thousands dot separator currency and no decimal" do
      expect(@parser.parse("1.000", 'EUR')).to eq(Money.new(1_000, 'EUR'))
    end

    it "parses a three digit currency" do
      expect(@parser.parse("1.000", 'JOD')).to eq(Money.new(1, 'JOD'))
    end

    it "parses uses currency when passed as block to with_currency" do
      expect(Money.with_currency('JOD') { @parser.parse("1.000") }).to eq(Money.new(1, 'JOD'))
    end

    it "parses no currency amount" do
      expect(@parser.parse("1.000", Money::NULL_CURRENCY)).to eq(Money.new(1.00))
    end

    it "parses amount with more than 3 decimals correctly" do
      expect(@parser.parse("1.11111111")).to eq(Money.new(1.11))
    end

    it "parses amount with multiple consistent thousands delimiters" do
      expect(@parser.parse("1.111.111")).to eq(Money.new(1_111_111))
    end

    it "parses amount with multiple inconsistent thousands delimiters" do
      expect(Money).to receive(:deprecate).once
      expect(@parser.parse("1.1.11.111")).to eq(Money.new(1_111_111))
    end

    it "parses raises with multiple inconsistent thousands delimiters and strict option" do
      expect { @parser.parse("1.1.11.111", strict: true) }.to raise_error(MoneyParser::MoneyFormatError)
    end
  end

  describe "parsing of amounts with comma decimal separator" do
    it "parses dollar amount $1,00 with leading $" do
      expect(@parser.parse("$1,00")).to eq(Money.new(1.00))
    end

    it "parses dollar amount $1,37 with leading $, and non-zero cents" do
      expect(@parser.parse("$1,37")).to eq(Money.new(1.37))
    end

    it "parses the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1,00 Rubbish")).to eq(Money.new(1.00))
    end

    it "parses the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1,00Rubbish")).to eq(Money.new(1.00))
    end

    it "parses negative hundreds amount" do
      expect(@parser.parse("-100,00")).to eq(Money.new(-100.00))
    end

    it "parses positive hundreds amount" do
      expect(@parser.parse("410,00")).to eq(Money.new(410.00))
    end

    it "parses a positive amount with a thousands separator" do
      expect(@parser.parse("100.000,00")).to eq(Money.new(100_000.00))
    end

    it "parses a negative amount with a thousands separator" do
      expect(@parser.parse("-100.000,00")).to eq(Money.new(-100_000.00))
    end

    it "parses amount ending with a comma" do
      expect(@parser.parse("1,")).to eq(Money.new(1))
      expect(@parser.parse("100.000,")).to eq(Money.new(100_000))
    end

    it "parses amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0,123")).to eq(Money.new(0.12))
    end

    it "parses negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0,123")).to eq(Money.new(-0.12))
    end

    it "parses amount with more than 3 decimals correctly" do
      expect(@parser.parse("1,11111111")).to eq(Money.new(1.11))
    end

    it "parses amount with more than 3 decimals correctly and a currency" do
      expect(@parser.parse("1,11111111", 'CAD')).to eq(Money.new(111_111_111))
    end

    it "parses amount with multiple consistent thousands delimiters" do
      expect(@parser.parse("1,111,111")).to eq(Money.new(1_111_111))
    end

    it "parses amount with multiple inconsistent thousands delimiters" do
      expect(Money).to receive(:deprecate).once
      expect(@parser.parse("1,1,11,111")).to eq(Money.new(1_111_111))
    end

    it "parses raises with multiple inconsistent thousands delimiters and strict option" do
      expect { @parser.parse("1,1,11,111", strict: true) }.to raise_error(MoneyParser::MoneyFormatError)
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

  describe "parsing of fixnum" do
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
  end

  describe "parsing with thousands separators" do
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
          expect(@parser.parse(number)).to eq(Money.new(1_234_567.89))
        end
      end
  end
end
