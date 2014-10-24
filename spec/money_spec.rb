require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Money" do

  before(:each) do
    @money = Money.new(0)
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
    (Money.new(0) + Money.new(0)).should == Money.new(0)
  end

  it "should be subtractable" do
    (Money.new(5.00) - Money.new(3.49)).should == Money.new(1.51)
  end

  it "should be subtractable to $0" do
    (Money.new(5.00) - Money.new(5.00)).should == Money.new(0)
  end

  it "should be substractable to a negative amount" do
    (Money.new(0.00) - Money.new(1.00)).should == Money.new("-1.00")
  end

  it "should inspect to a presentable string" do
    @money.inspect.should == "#<Money fractional:0 currency:USD>"
  end

  it "should be inspectable within an array" do
    [@money].inspect.should == "[#<Money fractional:0 currency:USD>]"
  end

  it "should correctly support eql? as a value object" do
    @money.should eql(Money.new(0))
  end

  it "should be addable with integer" do
    (Money.new(133) + 1.00).should == Money.new(233)
    (1.00 + Money.new(133)).should == Money.new(233)
  end

  it "should be addable with float" do
    (Money.new(133) + 1.50).should == Money.new(283)
    (1.50 + Money.new(133)).should == Money.new(283)
  end

  it "should be subtractable with integer" do
    (Money.new(166) - 1).should == Money.new(66)
    (2 - Money.new(166)).should == Money.new(34)
  end

  it "should be subtractable with float" do
    (Money.new(166) - 1.50).should == Money.new(16)
    (1.50 - Money.new(133)).should == Money.new(17)
  end

  it "should be multipliable with an integer" do
    (Money.new(100) * 55).should == Money.new(5500)
    (55 * Money.new(100)).should == Money.new(5500)
  end

  it "should be multiplable with a float" do
    (Money.new(100) * 1.50).should == Money.new(150)
    (1.50 * Money.new(100)).should == Money.new(150)
  end

  it "should be multipliable by a cents amount" do
    (Money.new(1.00) * 50).should == Money.new(50)
    (0.50 * Money.new(100)).should == Money.new(50)
  end

  it "should be multipliable by a repeatable floating point number" do
    (Money.new(2400) * (1 / 30.0)).should == Money.new(80)
    ((1 / 30.0) * Money.new(2400)).should == Money.new(80)
  end

  it "should round multiplication result with fractional penny of 5 or higher up" do
    (Money.new(3) * 0.5).should == Money.new(2)
    (0.5 * Money.new(3)).should == Money.new(2)
  end

  it "should round multiplication result with fractional penny of 4 or lower down" do
    (Money.new(10) * 0.33).should == Money.new(3)
    (0.33 * Money.new(10)).should == Money.new(3)
  end

  it "should raise if divided" do
    lambda { Money.new(5500) / 55 }.should raise_error
  end

  it "should return cents in to_liquid" do
    Money.new(100).to_liquid.should == 100
  end

  it "should return cents in to_json" do
    Money.new(100).to_json.should == "1.00"
  end

  it "should support absolute value" do
    Money.new(-100).abs.should == Money.new(100)
  end

  it "should support to_i" do
    Money.new(150).to_i.should == 1
  end

  it "should support to_f" do
    Money.new(150).to_f.to_s.should == "1.5"
  end

  it "should be creatable from an integer value in cents" do
    Money.from_cents(1950).should == Money.new(1950)
  end

  it "should be creatable from an integer value of 0 in cents" do
    Money.from_cents(0).should == Money.new(0)
  end

  it "should be creatable from a float cents amount" do
    Money.from_cents(1950.5).should == Money.new(1951)
  end

  it "should raise when constructed with a NaN value" do
    lambda{ Money.new( 0.0 / 0) }.should raise_error
  end

  it "should be comparable with non-money objects" do
    @money.should_not == nil
  end

  it "should support floor" do
    Money.new(1552).floor.should == Money.new(1500)
    Money.new(1899).floor.should == Money.new(1800)
    Money.new(2100).floor.should == Money.new(2100)
  end

  describe "frozen with amount of $1" do
    before(:each) do
      @money = Money.new(100).freeze
    end

    it "should == $1" do
      @money.should == Money.new(100)
    end

    it "should not == $2" do
      @money.should_not == Money.new(200)
    end

    it "<=> $1 should be 0" do
      (@money <=> Money.new(100)).should == 0
    end

    it "<=> $2 should be -1" do
      (@money <=> Money.new(200)).should == -1
    end

    it "<=> $0.50 should equal 1" do
      (@money <=> Money.new(50)).should == 1
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
      @money.hash.should == Money.new(100).hash
    end

    it "should not have the same hash value as $2" do
      @money.hash.should == Money.new(100).hash
    end

  end

  describe "with amount of $0" do
    before(:each) do
      @money = Money.new(0)
    end

    it "should be zero" do
      @money.should be_zero
    end

    it "should be greater than -$1" do
      @money.should be > Money.new("-1.00")
    end

    it "should be greater than or equal to $0" do
      @money.should be >= Money.new(0)
    end

    it "should be less than or equal to $0" do
      @money.should be <= Money.new(0)
    end

    it "should be less than $1" do
      @money.should be < Money.new(100)
    end
  end

  describe "with amount of $1" do
    before(:each) do
      @money = Money.new(100)
    end

    it "should not be zero" do
      @money.should_not be_zero
    end

    it "should have a decimal value = 1.00" do
      @money.to_d.should == BigDecimal.new("1.00")
    end

    it "should have 100 cents" do
      @money.cents.should == 100
    end

    it "should return cents as a Fixnum" do
      @money.cents.should be_an_instance_of(Fixnum)
    end

    it "should be greater than $0" do
      @money.should be > Money.new(0)
    end

    it "should be less than $2" do
      @money.should be < Money.new(200)
    end

    it "should be equal to $1" do
      @money.should == Money.new(100)
    end
  end

  describe "allocation"do
    specify "#allocate takes no action when one gets all" do
      Money.new(5).allocate([1]).should == [Money.new(5)]
    end

    specify "#allocate does not lose pennies" do
      moneys = Money.new(5).allocate([0.3,0.7])
      moneys[0].should == Money.new(2)
      moneys[1].should == Money.new(3)
    end

    specify "#allocate does not lose pennies even when given a lossy split" do
      moneys = Money.new(100).allocate([0.333,0.333, 0.333])
      moneys[0].cents.should == 34
      moneys[1].cents.should == 33
      moneys[2].cents.should == 33
    end

    specify "#allocate requires total to be less then 1" do
      lambda { Money.new(5).allocate([0.5,0.6]) }.should raise_error(ArgumentError)
    end
  end

  describe "split" do
    specify "#split needs at least one party" do
      lambda {Money.new(1).split(0)}.should raise_error(ArgumentError)
      lambda {Money.new(1).split(-1)}.should raise_error(ArgumentError)
    end

    specify "#gives 1 cent to both people if we start with 2" do
      Money.new(2).split(2).should == [Money.new(1), Money.new(1)]
    end

    specify "#split may distribute no money to some parties if there isnt enough to go around" do
      Money.new(2).split(3).should == [Money.new(1), Money.new(1), Money.new(0)]
    end

    specify "#split does not lose pennies" do
      Money.new(5).split(2).should == [Money.new(3), Money.new(2)]
    end

    specify "#split a dollar" do
      moneys = Money.new(100).split(3)
      moneys[0].cents.should == 34
      moneys[1].cents.should == 33
      moneys[2].cents.should == 33
    end
  end

  describe "fraction" do
    specify "#fraction needs a positive rate" do
      lambda {Money.new(100).fraction(-0.5)}.should raise_error(ArgumentError)
    end

    specify "#fraction returns the amount minus a fraction" do
      Money.new(115).fraction(0.15).should == Money.new(100)
      Money.new(250).fraction(0.15).should == Money.new(217)
      Money.new(3550).fraction(0).should == Money.new(3550)
    end
  end

  describe "parser dependency injection" do
    before(:each) do
      Money.parser = AccountingMoneyParser
    end

    it "should keep AccountingMoneyParser class on new money objects" do
      Money.new(0).class.parser.should == AccountingMoneyParser
    end

    it "should support parenthesis from AccountingMoneyParser" do
      Money.parse("($5.00)").should == Money.new(-500)
    end

    it "should support parenthesis from AccountingMoneyParser for .to_money" do
      "($5.00)".to_money.should == Money.new(-500)
    end

    after(:each) do
      Money.parser = nil # reset
    end
  end
end
