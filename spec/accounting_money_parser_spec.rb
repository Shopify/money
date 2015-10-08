require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AccountingMoneyParser do
  describe "parsing of amounts with period decimal separator" do
    before(:each) do
      @parser = AccountingMoneyParser.new
    end
    
    it "should parse parenthesis as a negative amount eg (99.00)" do
      expect(@parser.parse("(99.00)")).to eq(Money.new(-99.00))
    end
  
    it "should parse parenthesis as a negative amount regardless of currency sign" do
      expect(@parser.parse("($99.00)")).to eq(Money.new(-99.00))
    end
  
    it "should parse an empty string to $0" do
      expect(@parser.parse("")).to eq(Money.new)
    end
  
    it "should parse an invalid string to $0" do
      expect(@parser.parse("no money")).to eq(Money.new)
    end
  
    it "should parse a single digit integer string" do
      expect(@parser.parse("1")).to eq(Money.new(1.00))
    end
  
    it "should parse a double digit integer string" do
      expect(@parser.parse("10")).to eq(Money.new(10.00))
    end
  
    it "should parse an integer string amount with a leading $" do
      expect(@parser.parse("$1")).to eq(Money.new(1.00))
    end
  
    it "should parse a float string amount" do
      expect(@parser.parse("1.37")).to eq(Money.new(1.37))
    end
  
    it "should parse a float string amount with a leading $" do
      expect(@parser.parse("$1.37")).to eq(Money.new(1.37))
    end
  
    it "should parse a float string with a single digit after the decimal" do
      expect(@parser.parse("10.0")).to eq(Money.new(10.00))
    end
  
    it "should parse a float string with two digits after the decimal" do
      expect(@parser.parse("10.00")).to eq(Money.new(10.00))
    end
  
    it "should parse the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1.00 Rubbish")).to eq(Money.new(1.00))
    end

    it "should parse the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1.00Rubbish")).to eq(Money.new(1.00))
    end

    it "should parse a negative integer amount in the hundreds" do
      expect(@parser.parse("-100")).to eq(Money.new(-100.00))
    end

    it "should parse an integer amount in the hundreds" do
      expect(@parser.parse("410")).to eq(Money.new(410.00))
    end

    it "should parse a positive amount with a thousands separator" do
      expect(@parser.parse("100,000.00")).to eq(Money.new(100_000.00))
    end
  
    it "should parse a negative amount with a thousands separator" do
      expect(@parser.parse("-100,000.00")).to eq(Money.new(-100_000.00))
    end

    it "should parse negative $1.00" do
      expect(@parser.parse("-1.00")).to eq(Money.new(-1.00))
    end

    it "should parse a negative cents amount" do
      expect(@parser.parse("-0.90")).to eq(Money.new(-0.90))
    end
    
    it "should parse amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0.123")).to eq(Money.new(0.12))
    end
    
    it "should parse negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0.123")).to eq(Money.new(-0.12))
    end
    
    it "should parse negative amount with multiple leading - signs" do
      expect(@parser.parse("--0.123")).to eq(Money.new(-0.12))
    end
    
    it "should parse negative amount with multiple - signs" do
      expect(@parser.parse("--0.123--")).to eq(Money.new(-0.12))
    end
  end

  describe "parsing of amounts with comma decimal separator" do
    before(:each) do
      @parser = AccountingMoneyParser.new
    end
    
    it "should parse dollar amount $1,00 with leading $" do
      expect(@parser.parse("$1,00")).to eq(Money.new(1.00))
    end

    it "should parse dollar amount $1,37 with leading $, and non-zero cents" do
      expect(@parser.parse("$1,37")).to eq(Money.new(1.37))
    end
    
    it "should parse the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1,00 Rubbish")).to eq(Money.new(1.00))
    end

    it "should parse the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1,00Rubbish")).to eq(Money.new(1.00))
    end
    
    it "should parse thousands amount" do
      expect(@parser.parse("1.000")).to eq(Money.new(1000.00))
    end
    
    it "should parse negative hundreds amount" do
      expect(@parser.parse("-100,00")).to eq(Money.new(-100.00))
    end
    
    it "should parse positive hundreds amount" do
      expect(@parser.parse("410,00")).to eq(Money.new(410.00))
    end
    
    it "should parse a positive amount with a thousands separator" do
      expect(@parser.parse("100.000,00")).to eq(Money.new(100_000.00))
    end
  
    it "should parse a negative amount with a thousands separator" do
      expect(@parser.parse("-100.000,00")).to eq(Money.new(-100_000.00))
    end
    
    it "should parse amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0,123")).to eq(Money.new(0.12))
    end
    
    it "should parse negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0,123")).to eq(Money.new(-0.12))
    end
  end
  
  describe "parsing of decimal cents amounts from 0 to 10" do
    before(:each) do
      @parser = AccountingMoneyParser.new
    end
    
    it "should parse 50.0" do
      expect(@parser.parse("50.0")).to eq(Money.new(50.00))
    end
    
    it "should parse 50.1" do
      expect(@parser.parse("50.1")).to eq(Money.new(50.10))
    end
    
    it "should parse 50.2" do
      expect(@parser.parse("50.2")).to eq(Money.new(50.20))
    end
    
    it "should parse 50.3" do
      expect(@parser.parse("50.3")).to eq(Money.new(50.30))
    end
    
    it "should parse 50.4" do
      expect(@parser.parse("50.4")).to eq(Money.new(50.40))
    end
    
    it "should parse 50.5" do
      expect(@parser.parse("50.5")).to eq(Money.new(50.50))
    end
    
    it "should parse 50.6" do
      expect(@parser.parse("50.6")).to eq(Money.new(50.60))
    end
    
    it "should parse 50.7" do
      expect(@parser.parse("50.7")).to eq(Money.new(50.70))
    end
    
    it "should parse 50.8" do
      expect(@parser.parse("50.8")).to eq(Money.new(50.80))
    end
    
    it "should parse 50.9" do
      expect(@parser.parse("50.9")).to eq(Money.new(50.90))
    end
    
    it "should parse 50.10" do
      expect(@parser.parse("50.10")).to eq(Money.new(50.10))
    end
  end
end