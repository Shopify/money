require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe MoneyParser do
  describe "parsing of amounts with period decimal separator" do
    before(:each) do
      @parser = MoneyParser.new
    end
  
    it "parses an empty string to $0" do
      expect(@parser.parse("")).to eq(ShopifyMoney.new)
    end
  
    it "parses an invalid string to $0" do
      expect(@parser.parse("no money")).to eq(ShopifyMoney.new)
    end
  
    it "parses a single digit integer string" do
      expect(@parser.parse("1")).to eq(ShopifyMoney.new(1.00))
    end
  
    it "parses a double digit integer string" do
      expect(@parser.parse("10")).to eq(ShopifyMoney.new(10.00))
    end
  
    it "parses an integer string amount with a leading $" do
      expect(@parser.parse("$1")).to eq(ShopifyMoney.new(1.00))
    end
  
    it "parses a float string amount" do
      expect(@parser.parse("1.37")).to eq(ShopifyMoney.new(1.37))
    end
  
    it "parses a float string amount with a leading $" do
      expect(@parser.parse("$1.37")).to eq(ShopifyMoney.new(1.37))
    end
  
    it "parses a float string with a single digit after the decimal" do
      expect(@parser.parse("10.0")).to eq(ShopifyMoney.new(10.00))
    end
  
    it "parses a float string with two digits after the decimal" do
      expect(@parser.parse("10.00")).to eq(ShopifyMoney.new(10.00))
    end
  
    it "parses the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1.00 Rubbish")).to eq(ShopifyMoney.new(1.00))
    end

    it "parses the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1.00Rubbish")).to eq(ShopifyMoney.new(1.00))
    end

    it "parses a negative integer amount in the hundreds" do
      expect(@parser.parse("-100")).to eq(ShopifyMoney.new(-100.00))
    end

    it "parses an integer amount in the hundreds" do
      expect(@parser.parse("410")).to eq(ShopifyMoney.new(410.00))
    end

    it "parses a positive amount with a thousands separator" do
      expect(@parser.parse("100,000.00")).to eq(ShopifyMoney.new(100_000.00))
    end
  
    it "parses a negative amount with a thousands separator" do
      expect(@parser.parse("-100,000.00")).to eq(ShopifyMoney.new(-100_000.00))
    end

    it "parses negative $1.00" do
      expect(@parser.parse("-1.00")).to eq(ShopifyMoney.new(-1.00))
    end

    it "parses a negative cents amount" do
      expect(@parser.parse("-0.90")).to eq(ShopifyMoney.new(-0.90))
    end
    
    it "parses amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0.123")).to eq(ShopifyMoney.new(0.12))
    end
    
    it "parses negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0.123")).to eq(ShopifyMoney.new(-0.12))
    end
    
    it "parses negative amount with multiple leading - signs" do
      expect(@parser.parse("--0.123")).to eq(ShopifyMoney.new(-0.12))
    end
    
    it "parses negative amount with multiple - signs" do
      expect(@parser.parse("--0.123--")).to eq(ShopifyMoney.new(-0.12))
    end
  end

  describe "parsing of amounts with comma decimal separator" do
    before(:each) do
      @parser = MoneyParser.new
    end
    
    it "parses dollar amount $1,00 with leading $" do
      expect(@parser.parse("$1,00")).to eq(ShopifyMoney.new(1.00))
    end

    it "parses dollar amount $1,37 with leading $, and non-zero cents" do
      expect(@parser.parse("$1,37")).to eq(ShopifyMoney.new(1.37))
    end
    
    it "parses the amount from an amount surrounded by whitespace and garbage" do
      expect(@parser.parse("Rubbish $1,00 Rubbish")).to eq(ShopifyMoney.new(1.00))
    end

    it "parses the amount from an amount surrounded by garbage" do
      expect(@parser.parse("Rubbish$1,00Rubbish")).to eq(ShopifyMoney.new(1.00))
    end
    
    it "parses thousands amount" do
      expect(@parser.parse("1.000")).to eq(ShopifyMoney.new(1000.00))
    end
    
    it "parses negative hundreds amount" do
      expect(@parser.parse("-100,00")).to eq(ShopifyMoney.new(-100.00))
    end
    
    it "parses positive hundreds amount" do
      expect(@parser.parse("410,00")).to eq(ShopifyMoney.new(410.00))
    end
    
    it "parses a positive amount with a thousands separator" do
      expect(@parser.parse("100.000,00")).to eq(ShopifyMoney.new(100_000.00))
    end
  
    it "parses a negative amount with a thousands separator" do
      expect(@parser.parse("-100.000,00")).to eq(ShopifyMoney.new(-100_000.00))
    end
    
    it "parses amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("0,123")).to eq(ShopifyMoney.new(0.12))
    end
    
    it "parses negative amount with 3 decimals and 0 dollar amount" do
      expect(@parser.parse("-0,123")).to eq(ShopifyMoney.new(-0.12))
    end
  end
  
  describe "parsing of decimal cents amounts from 0 to 10" do
    before(:each) do
      @parser = MoneyParser.new
    end
    
    it "parses 50.0" do
      expect(@parser.parse("50.0")).to eq(ShopifyMoney.new(50.00))
    end
    
    it "parses 50.1" do
      expect(@parser.parse("50.1")).to eq(ShopifyMoney.new(50.10))
    end
    
    it "parses 50.2" do
      expect(@parser.parse("50.2")).to eq(ShopifyMoney.new(50.20))
    end
    
    it "parses 50.3" do
      expect(@parser.parse("50.3")).to eq(ShopifyMoney.new(50.30))
    end
    
    it "parses 50.4" do
      expect(@parser.parse("50.4")).to eq(ShopifyMoney.new(50.40))
    end
    
    it "parses 50.5" do
      expect(@parser.parse("50.5")).to eq(ShopifyMoney.new(50.50))
    end
    
    it "parses 50.6" do
      expect(@parser.parse("50.6")).to eq(ShopifyMoney.new(50.60))
    end
    
    it "parses 50.7" do
      expect(@parser.parse("50.7")).to eq(ShopifyMoney.new(50.70))
    end
    
    it "parses 50.8" do
      expect(@parser.parse("50.8")).to eq(ShopifyMoney.new(50.80))
    end
    
    it "parses 50.9" do
      expect(@parser.parse("50.9")).to eq(ShopifyMoney.new(50.90))
    end
    
    it "parses 50.10" do
      expect(@parser.parse("50.10")).to eq(ShopifyMoney.new(50.10))
    end
  end
end