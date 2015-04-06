require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Money" do

  before(:each) do
    @money = Money.new
  end

  it "should be contructable with empty class method" do
    Money.empty.should == @money
  end

  it "should return itself with to_money" do
    @money.to_money.should equal(@money)
  end

  it "should default to 0 when constructed with no arguments" do
    @money.should == Money.new(0.00)
  end

  it "should to_s as a float with 2 decimal places" do
    @money.to_s.should == "0.00"
  end

  it "should be constructable with a BigDecimal" do
    Money.new(BigDecimal.new("1.23")).should == Money.new(1.23)
  end

  it "should be constructable with a Fixnum" do
    Money.new(3).should == Money.new(3.00)
  end

  it "should be construcatable with a Float" do
    Money.new(3.00).should == Money.new(3.00)
  end

  it "should be addable" do
    (Money.new(1.51) + Money.new(3.49)).should == Money.new(5.00)
  end

  it "should be able to add $0 + $0" do
    (Money.new + Money.new).should == Money.new
  end

  it "should be subtractable" do
    (Money.new(5.00) - Money.new(3.49)).should == Money.new(1.51)
  end

  it "should be subtractable to $0" do
    (Money.new(5.00) - Money.new(5.00)).should == Money.new
  end

  it "should be substractable to a negative amount" do
    (Money.new(0.00) - Money.new(1.00)).should == Money.new("-1.00")
  end

  it "should inspect to a presentable string" do
    @money.inspect.should == "#<Money value:0.00>"
  end

  it "should be inspectable within an array" do
    [@money].inspect.should == "[#<Money value:0.00>]"
  end

  it "should correctly support eql? as a value object" do
    @money.should eql(Money.new)
  end

  it "should be addable with integer" do
    (Money.new(1.33) + 1).should == Money.new(2.33)
    (1 + Money.new(1.33)).should == Money.new(2.33)
  end

  it "should be addable with float" do
    (Money.new(1.33) + 1.50).should == Money.new(2.83)
    (1.50 + Money.new(1.33)).should == Money.new(2.83)
  end

  it "should be subtractable with integer" do
    (Money.new(1.66) - 1).should == Money.new(0.66)
    (2 - Money.new(1.66)).should == Money.new(0.34)
  end

  it "should be subtractable with float" do
    (Money.new(1.66) - 1.50).should == Money.new(0.16)
    (1.50 - Money.new(1.33)).should == Money.new(0.17)
  end

  it "should be multipliable with an integer" do
    (Money.new(1.00) * 55).should == Money.new(55.00)
    (55 * Money.new(1.00)).should == Money.new(55.00)
  end

  it "should be multiplable with a float" do
    (Money.new(1.00) * 1.50).should == Money.new(1.50)
    (1.50 * Money.new(1.00)).should == Money.new(1.50)
  end

  it "should be multipliable by a cents amount" do
    (Money.new(1.00) * 0.50).should == Money.new(0.50)
    (0.50 * Money.new(1.00)).should == Money.new(0.50)
  end

  it "should be multipliable by a repeatable floating point number" do
    (Money.new(24.00) * (1 / 30.0)).should == Money.new(0.80)
    ((1 / 30.0) * Money.new(24.00)).should == Money.new(0.80)
  end

  it "should round multiplication result with fractional penny of 5 or higher up" do
    (Money.new(0.03) * 0.5).should == Money.new(0.02)
    (0.5 * Money.new(0.03)).should == Money.new(0.02)
  end

  it "should round multiplication result with fractional penny of 4 or lower down" do
    (Money.new(0.10) * 0.33).should == Money.new(0.03)
    (0.33 * Money.new(0.10)).should == Money.new(0.03)
  end

  it "should raise if divided" do
    lambda { Money.new(55.00) / 55 }.should raise_error
  end

  it "should return cents in to_liquid" do
    Money.new(1.00).to_liquid.should == 100
  end

  it "should return cents in to_json" do
    Money.new(1.00).to_json.should == "1.00"
  end

  it "should support absolute value" do
    Money.new(-1.00).abs.should == Money.new(1.00)
  end

  it "should support to_i" do
    Money.new(1.50).to_i.should == 1
  end

  it "should support to_f" do
    Money.new(1.50).to_f.to_s.should == "1.5"
  end

  it "should be creatable from an integer value in cents" do
    Money.from_cents(1950).should == Money.new(19.50)
  end

  it "should be creatable from an integer value of 0 in cents" do
    Money.from_cents(0).should == Money.new
  end

  it "should be creatable from a float cents amount" do
    Money.from_cents(1950.5).should == Money.new(19.51)
  end

  it "should raise when constructed with a NaN value" do
    lambda{ Money.new( 0.0 / 0) }.should raise_error
  end

  it "should be comparable with non-money objects" do
    @money.should_not == nil
  end

  it "should support floor" do
    Money.new(15.52).floor.should == Money.new(15.00)
    Money.new(18.99).floor.should == Money.new(18.00)
    Money.new(21).floor.should == Money.new(21)
  end

  describe "frozen with amount of $1" do
    before(:each) do
      @money = Money.new(1.00).freeze
    end

    it "should == $1" do
      @money.should == Money.new(1.00)
    end

    it "should not == $2" do
      @money.should_not == Money.new(2.00)
    end

    it "<=> $1 should be 0" do
      (@money <=> Money.new(1.00)).should == 0
    end

    it "<=> $2 should be -1" do
      (@money <=> Money.new(2.00)).should == -1
    end

    it "<=> $0.50 should equal 1" do
      (@money <=> Money.new(0.50)).should == 1
    end

    it "<=> works with non-money objects" do
      (@money <=> 1).should == 0
      (@money <=> 2).should == -1
      (@money <=> 0.5).should == 1
      (1 <=> @money).should == 0
      (2 <=> @money).should == 1
      (0.5 <=> @money).should == -1
    end

    it "should have the same hash value as $1" do
      @money.hash.should == Money.new(1.00).hash
    end

    it "should not have the same hash value as $2" do
      @money.hash.should == Money.new(1.00).hash
    end

  end

  describe "with amount of $0" do
    before(:each) do
      @money = Money.new
    end

    it "should be zero" do
      @money.should be_zero
    end

    it "should be greater than -$1" do
      @money.should be > Money.new("-1.00")
    end

    it "should be greater than or equal to $0" do
      @money.should be >= Money.new
    end

    it "should be less than or equal to $0" do
      @money.should be <= Money.new
    end

    it "should be less than $1" do
      @money.should be < Money.new(1.00)
    end
  end

  describe "with amount of $1" do
    before(:each) do
      @money = Money.new(1.00)
    end

    it "should not be zero" do
      @money.should_not be_zero
    end

    it "should have a decimal value = 1.00" do
      @money.value.should == BigDecimal.new("1.00")
    end

    it "should have 100 cents" do
      @money.cents.should == 100
    end

    it "should return cents as a Fixnum" do
      @money.cents.should be_an_instance_of(Fixnum)
    end

    it "should be greater than $0" do
      @money.should be > Money.new(0.00)
    end

    it "should be less than $2" do
      @money.should be < Money.new(2.00)
    end

    it "should be equal to $1" do
      @money.should == Money.new(1.00)
    end
  end

  describe "allocation"do
    specify "#allocate takes no action when one gets all" do
      Money.new(5).allocate([1]).should == [Money.new(5)]
    end

    specify "#allocate does not lose pennies" do
      moneys = Money.new(0.05).allocate([0.3,0.7])
      moneys[0].should == Money.new(0.02)
      moneys[1].should == Money.new(0.03)
    end

    specify "#allocate does not lose pennies even when given a lossy split" do
      moneys = Money.new(1).allocate([0.333,0.333, 0.333])
      moneys[0].cents.should == 34
      moneys[1].cents.should == 33
      moneys[2].cents.should == 33
    end

    specify "#allocate requires total to be less then 1" do
      lambda { Money.new(0.05).allocate([0.5,0.6]) }.should raise_error(ArgumentError)
    end
  end

  describe "split" do
    specify "#split needs at least one party" do
      lambda {Money.new(1).split(0)}.should raise_error(ArgumentError)
      lambda {Money.new(1).split(-1)}.should raise_error(ArgumentError)
    end

    specify "#gives 1 cent to both people if we start with 2" do
      Money.new(0.02).split(2).should == [Money.new(0.01), Money.new(0.01)]
    end

    specify "#split may distribute no money to some parties if there isnt enough to go around" do
      Money.new(0.02).split(3).should == [Money.new(0.01), Money.new(0.01), Money.new(0)]
    end

    specify "#split does not lose pennies" do
      Money.new(0.05).split(2).should == [Money.new(0.03), Money.new(0.02)]
    end

    specify "#split a dollar" do
      moneys = Money.new(1).split(3)
      moneys[0].cents.should == 34
      moneys[1].cents.should == 33
      moneys[2].cents.should == 33
    end
  end

  describe "fraction" do
    specify "#fraction needs a positive rate" do
      lambda {Money.new(1).fraction(-0.5)}.should raise_error(ArgumentError)
    end

    specify "#fraction returns the amount minus a fraction" do
      Money.new(1.15).fraction(0.15).should == Money.new(1.00)
      Money.new(2.50).fraction(0.15).should == Money.new(2.17)
      Money.new(35.50).fraction(0).should == Money.new(35.50)
    end
  end

  describe "with amount of $1 with created with 3 decimal places" do
    before(:each) do
      @money = Money.new(1.125)
    end

    it "should round 3rd decimal place" do
      @money.value.should == BigDecimal.new("1.13")
    end
  end

  describe "parser dependency injection" do
    before(:each) do
      Money.parser = AccountingMoneyParser
    end

    it "should keep AccountingMoneyParser class on new money objects" do
      Money.new.class.parser.should == AccountingMoneyParser
    end

    it "should support parenthesis from AccountingMoneyParser" do
      Money.parse("($5.00)").should == Money.new(-5)
    end

    it "should support parenthesis from AccountingMoneyParser for .to_money" do
      "($5.00)".to_money.should == Money.new(-5)
    end

    after(:each) do
      Money.parser = nil # reset
    end
  end
  
  describe "round" do
    
    it "should round to 0 decimal places by default" do
      Money.new(54.1).round.should == Money.new(54)
      Money.new(54.5).round.should == Money.new(55)
    end
    
    # Overview of standard vs. banker's rounding for next 4 specs:
    # http://www.xbeat.net/vbspeed/i_BankersRounding.htm
    it "should implement standard rounding for 2 digits" do
      Money.new(54.1754).round(2).should == Money.new(54.18)
      Money.new(343.2050).round(2).should == Money.new(343.21)
      Money.new(106.2038).round(2).should == Money.new(106.20)
    end

    it "should implement standard rounding for 1 digit" do
      Money.new(27.25).round(1).should == Money.new(27.3)
      Money.new(27.45).round(1).should == Money.new(27.5)
      Money.new(27.55).round(1).should == Money.new(27.6)
    end

  end
end
