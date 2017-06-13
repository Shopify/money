require 'spec_helper'

describe "Money" do

  before(:each) do
    @money = Money.new
  end

  it "is contructable with empty class method" do
    expect(Money.empty).to eq(@money)
  end

  it "returns itself with to_money" do
    expect(@money.to_money).to eq(@money)
  end

  it "defaults to 0 when constructed with no arguments" do
    expect(@money).to eq(Money.new(0.00))
  end

  it "defaults to 0 when constructed with an invalid string" do
    expect(Money.new('invalid')).to eq(Money.new(0.00))
  end

  it "to_s as a float with 2 decimal places" do
    expect(@money.to_s).to eq("0.00")
  end

  it "as_json as a float with 2 decimal places" do
    expect(@money.as_json).to eq("0.00")
  end

  it "is constructable with a BigDecimal" do
    expect(Money.new(BigDecimal.new("1.23"))).to eq(Money.new(1.23))
  end

  it "is constructable with a Fixnum" do
    expect(Money.new(3)).to eq(Money.new(3.00))
  end

  it "is construcatable with a Float" do
    expect(Money.new(3.00)).to eq(Money.new(BigDecimal.new('3.00')))
  end

  it "is construcatable with a String" do
    expect(Money.new('3.00')).to eq(Money.new(3.00))
  end

  it "is addable" do
    expect((Money.new(1.51) + Money.new(3.49))).to eq(Money.new(5.00))
  end

  it "raises error if added other is not compatible" do
    expect{ Money.new(5.00) + nil }.to raise_error(TypeError)
  end

  it "is able to add $0 + $0" do
    expect((Money.new + Money.new)).to eq(Money.new)
  end

  it "is subtractable" do
    expect((Money.new(5.00) - Money.new(3.49))).to eq(Money.new(1.51))
  end

  it "raises error if subtracted other is not compatible" do
    expect{ Money.new(5.00) - nil }.to raise_error(TypeError)
  end

  it "is subtractable to $0" do
    expect((Money.new(5.00) - Money.new(5.00))).to eq(Money.new)
  end

  it "is substractable to a negative amount" do
    expect((Money.new(0.00) - Money.new(1.00))).to eq(Money.new("-1.00"))
  end

  it "is never negative zero" do
    expect(Money.new(-0.00).to_s).to eq("0.00")
    expect((Money.new(0) * -1).to_s).to eq("0.00")
  end

  it "inspects to a presentable string" do
    expect(@money.inspect).to eq("#<Money value:0.00>")
  end

  it "is inspectable within an array" do
    expect([@money].inspect).to eq("[#<Money value:0.00>]")
  end

  it "correctly support eql? as a value object" do
    expect(@money).to eq(Money.new)
  end

  it "is addable with integer" do
    expect((Money.new(1.33) + 1)).to eq(Money.new(2.33))
    expect((1 + Money.new(1.33))).to eq(Money.new(2.33))
  end

  it "is addable with float" do
    expect((Money.new(1.33) + 1.50)).to eq(Money.new(2.83))
    expect((1.50 + Money.new(1.33))).to eq(Money.new(2.83))
  end

  it "is subtractable with integer" do
    expect((Money.new(1.66) - 1)).to eq(Money.new(0.66))
    expect((2 - Money.new(1.66))).to eq(Money.new(0.34))
  end

  it "is subtractable with float" do
    expect((Money.new(1.66) - 1.50)).to eq(Money.new(0.16))
    expect((1.50 - Money.new(1.33))).to eq(Money.new(0.17))
  end

  it "is multipliable with an integer" do
    expect((Money.new(1.00) * 55)).to eq(Money.new(55.00))
    expect((55 * Money.new(1.00))).to eq(Money.new(55.00))
  end

  it "is multiplable with a float" do
    expect((Money.new(1.00) * 1.50)).to eq(Money.new(1.50))
    expect((1.50 * Money.new(1.00))).to eq(Money.new(1.50))
  end

  it "is multipliable by a cents amount" do
    expect((Money.new(1.00) * 0.50)).to eq(Money.new(0.50))
    expect((0.50 * Money.new(1.00))).to eq(Money.new(0.50))
  end

  it "is multipliable by a rational" do
    expect((Money.new(3.3) * Rational(1, 12))).to eq(Money.new(0.28))
    expect((Rational(1, 12) * Money.new(3.3))).to eq(Money.new(0.28))
  end

  it "is multipliable by a repeatable floating point number" do
    expect((Money.new(24.00) * (1 / 30.0))).to eq(Money.new(0.80))
    expect(((1 / 30.0) * Money.new(24.00))).to eq(Money.new(0.80))
  end

  it "is multipliable by a repeatable floating point number where the floating point error rounds down" do
    expect((Money.new(3.3) * (1.0 / 12))).to eq(Money.new(0.28))
    expect(((1.0 / 12) * Money.new(3.3))).to eq(Money.new(0.28))
  end

  it "rounds multiplication result with fractional penny of 5 or higher up" do
    expect((Money.new(0.03) * 0.5)).to eq(Money.new(0.02))
    expect((0.5 * Money.new(0.03))).to eq(Money.new(0.02))
  end

  it "rounds multiplication result with fractional penny of 4 or lower down" do
    expect((Money.new(0.10) * 0.33)).to eq(Money.new(0.03))
    expect((0.33 * Money.new(0.10))).to eq(Money.new(0.03))
  end

  it "is less than a bigger integer" do
    expect(Money.new(1)).to be < 2
    expect(2).to be > Money.new(1)
  end

  it "is less than or equal to a bigger integer" do
    expect(Money.new(1)).to be <= 2
    expect(2).to be >= Money.new(1)
  end

  it "is greater than a lesser integer" do
    expect(Money.new(2)).to be > 1
    expect(1).to be < Money.new(2)
  end

  it "is greater than or equal to a lesser integer" do
    expect(Money.new(2)).to be >= 1
    expect(1).to be <= Money.new(2)
  end

  it "raises if divided" do
    expect { Money.new(55.00) / 55 }.to raise_error(RuntimeError)
  end

  it "returns cents in to_liquid" do
    expect(Money.new(1.00).to_liquid).to eq(100)
  end

  it "returns cents in to_json" do
    expect(Money.new(1.00).to_json).to eq("1.00")
  end

  it "supports absolute value" do
    expect(Money.new(-1.00).abs).to eq(Money.new(1.00))
  end

  it "supports to_i" do
    expect(Money.new(1.50).to_i).to eq(1)
  end

  it "supports to_d" do
    expect(Money.new(1.29).to_d).to eq(BigDecimal.new('1.29'))
  end

  it "supports to_f" do
    expect(Money.new(1.50).to_f.to_s).to eq("1.5")
  end

  it "is creatable from an integer value in cents" do
    expect(Money.from_cents(1950)).to eq(Money.new(19.50))
  end

  it "is creatable from an integer value of 0 in cents" do
    expect(Money.from_cents(0)).to eq(Money.new)
  end

  it "is creatable from a float cents amount" do
    expect(Money.from_cents(1950.5)).to eq(Money.new(19.51))
  end

  it "raises when constructed with a NaN value" do
    expect { Money.new( 0.0 / 0) }.to raise_error(ArgumentError)
  end

  it "is comparable with non-money objects" do
    expect(@money).not_to eq(nil)
  end

  it "supports floor" do
    expect(Money.new(15.52).floor).to eq(Money.new(15.00))
    expect(Money.new(18.99).floor).to eq(Money.new(18.00))
    expect(Money.new(21).floor).to eq(Money.new(21))
  end

  describe "frozen with amount of $1" do
    before(:each) do
      @money = Money.new(1.00).freeze
    end

    it "is equals to $1" do
      expect(@money).to eq(Money.new(1.00))
    end

    it "is not equals to $2" do
      expect(@money).not_to eq(Money.new(2.00))
    end

    it "<=> $1 is 0" do
      expect((@money <=> Money.new(1.00))).to eq(0)
    end

    it "<=> $2 is -1" do
      expect((@money <=> Money.new(2.00))).to eq(-1)
    end

    it "<=> $0.50 equals 1" do
      expect((@money <=> Money.new(0.50))).to eq(1)
    end

    it "<=> works with non-money objects" do
      expect((@money <=> 1)).to eq(0)
      expect((@money <=> 2)).to eq(-1)
      expect((@money <=> 0.5)).to eq(1)
      expect((1 <=> @money)).to eq(0)
      expect((2 <=> @money)).to eq(1)
      expect((0.5 <=> @money)).to eq(-1)
    end

    it "raises error if compared other is not compatible" do
      expect{ Money.new(5.00) <=> nil }.to raise_error(TypeError)
    end

    it "have the same hash value as $1" do
      expect(@money.hash).to eq(Money.new(1.00).hash)
    end

    it "does not have the same hash value as $2" do
      expect(@money.hash).to eq(Money.new(1.00).hash)
    end

  end

  describe "with amount of $0" do
    before(:each) do
      @money = Money.new
    end

    it "is zero" do
      expect(@money).to be_zero
    end

    it "is greater than -$1" do
      expect(@money).to be > Money.new("-1.00")
    end

    it "is greater than or equal to $0" do
      expect(@money).to be >= Money.new
    end

    it "is less than or equal to $0" do
      expect(@money).to be <= Money.new
    end

    it "is less than $1" do
      expect(@money).to be < Money.new(1.00)
    end
  end

  describe "with amount of $1" do
    before(:each) do
      @money = Money.new(1.00)
    end

    it "is not zero" do
      expect(@money).not_to be_zero
    end

    it "returns cents as a decimal value = 1.00" do
      expect(@money.value).to eq(BigDecimal.new("1.00"))
    end

    it "returns cents as 100 cents" do
      expect(@money.cents).to eq(100)
    end

    it "returns cents as a Fixnum" do
      expect(@money.cents).to be_an_instance_of(Fixnum)
    end

    it "is greater than $0" do
      expect(@money).to be > Money.new(0.00)
    end

    it "is less than $2" do
      expect(@money).to be < Money.new(2.00)
    end

    it "is equal to $1" do
      expect(@money).to eq(Money.new(1.00))
    end
  end

  describe "allocation"do
    specify "#allocate takes no action when one gets all" do
      expect(Money.new(5).allocate([1])).to eq([Money.new(5)])
    end

    specify "#allocate does not lose pennies" do
      moneys = Money.new(0.05).allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(0.02))
      expect(moneys[1]).to eq(Money.new(0.03))
    end

    specify "#allocate does not lose pennies even when given a lossy split" do
      moneys = Money.new(1).allocate([0.333,0.333, 0.333])
      expect(moneys[0].cents).to eq(34)
      expect(moneys[1].cents).to eq(33)
      expect(moneys[2].cents).to eq(33)
    end

    specify "#allocate requires total to be less than 1" do
      expect { Money.new(0.05).allocate([0.5,0.6]) }.to raise_error(ArgumentError)
    end

    specify "#allocate will use rationals if provided" do
      splits = [128400,20439,14589,14589,25936].map{ |num| Rational(num, 203953) } # sums to > 1 if converted to float
      expect(Money.new(2.25).allocate(splits)).to eq([Money.new(1.42), Money.new(0.23), Money.new(0.16), Money.new(0.16), Money.new(0.28)])
    end

    specify "#allocate will convert rationals with high precision" do
      ratios = [Rational(1, 1), Rational(0)]
      expect(Money.new("858993456.12").allocate(ratios)).to eq([Money.new("858993456.12"), Money.empty])
      ratios = [Rational(1, 6), Rational(5, 6)]
      expect(Money.new("3.00").allocate(ratios)).to eq([Money.new("0.50"), Money.new("2.50")])
    end

    specify "#allocate doesn't raise with weird negative rational ratios" do
      rate = Rational(-5, 1201)
      expect { Money.new(1).allocate([rate, 1 - rate]) }.not_to raise_error
    end

    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room for the remainder" do
      expect(
        Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)]),
      ).to eq([Money.new(26), Money.new(4.75)])
    end

    specify "#allocate_max_amounts drops the remainder when returning the weighted allocation without exceeding the maxima when there is no room for the remainder" do
      expect(
        Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.74)]),
      ).to eq([Money.new(26), Money.new(4.74)])
    end

    specify "#allocate_max_amounts returns the weighted allocation when there is no remainder" do
      expect(
        Money.new(30).allocate_max_amounts([Money.new(15), Money.new(15)]),
      ).to eq([Money.new(15), Money.new(15)])
    end

    specify "#allocate_max_amounts allocates the remainder round-robin when the maxima are not reached" do
      expect(
        Money.new(1).allocate_max_amounts([Money.new(33), Money.new(33), Money.new(33)]),
      ).to eq([Money.new(0.34), Money.new(0.33), Money.new(0.33)])
    end

    specify "#allocate_max_amounts allocates up to the maxima specified" do
      expect(
        Money.new(100).allocate_max_amounts([Money.new(5), Money.new(2)]),
      ).to eq([Money.new(5), Money.new(2)])
    end

    specify "#allocate_max_amounts supports all-zero maxima" do
      expect(
        Money.new(3).allocate_max_amounts([Money.empty, Money.empty, Money.empty]),
      ).to eq([Money.empty, Money.empty, Money.empty])
    end
  end

  describe "split" do
    specify "#split needs at least one party" do
      expect {Money.new(1).split(0)}.to raise_error(ArgumentError)
      expect {Money.new(1).split(-1)}.to raise_error(ArgumentError)
    end

    specify "#gives 1 cent to both people if we start with 2" do
      expect(Money.new(0.02).split(2)).to eq([Money.new(0.01), Money.new(0.01)])
    end

    specify "#split may distribute no money to some parties if there isnt enough to go around" do
      expect(Money.new(0.02).split(3)).to eq([Money.new(0.01), Money.new(0.01), Money.new(0)])
    end

    specify "#split does not lose pennies" do
      expect(Money.new(0.05).split(2)).to eq([Money.new(0.03), Money.new(0.02)])
    end

    specify "#split a dollar" do
      moneys = Money.new(1).split(3)
      expect(moneys[0].cents).to eq(34)
      expect(moneys[1].cents).to eq(33)
      expect(moneys[2].cents).to eq(33)
    end
  end

  describe "fraction" do
    specify "#fraction needs a positive rate" do
      expect {Money.new(1).fraction(-0.5)}.to raise_error(ArgumentError)
    end

    specify "#fraction returns the amount minus a fraction" do
      expect(Money.new(1.15).fraction(0.15)).to eq(Money.new(1.00))
      expect(Money.new(2.50).fraction(0.15)).to eq(Money.new(2.17))
      expect(Money.new(35.50).fraction(0)).to eq(Money.new(35.50))
    end
  end

  describe "with amount of $1 with created with 3 decimal places" do
    before(:each) do
      @money = Money.new(1.125)
    end

    it "rounds 3rd decimal place" do
      expect(@money.value).to eq(BigDecimal.new("1.13"))
    end
  end

  describe "parser dependency injection" do
    before(:each) do
      Money.parser = AccountingMoneyParser
    end

    it "keeps AccountingMoneyParser class on new money objects" do
      expect(Money.new.class.parser).to eq(AccountingMoneyParser)
    end

    it "supports parenthesis from AccountingMoneyParser" do
      expect(Money.parse("($5.00)")).to eq(Money.new(-5))
    end

    it "supports parenthesis from AccountingMoneyParser for .to_money" do
      expect("($5.00)".to_money).to eq(Money.new(-5))
    end

    after(:each) do
      Money.parser = nil # reset
    end
  end

  describe "round" do

    it "rounds to 0 decimal places by default" do
      expect(Money.new(54.1).round).to eq(Money.new(54))
      expect(Money.new(54.5).round).to eq(Money.new(55))
    end

    # Overview of standard vs. banker's rounding for next 4 specs:
    # http://www.xbeat.net/vbspeed/i_BankersRounding.htm
    it "implements standard rounding for 2 digits" do
      expect(Money.new(54.1754).round(2)).to eq(Money.new(54.18))
      expect(Money.new(343.2050).round(2)).to eq(Money.new(343.21))
      expect(Money.new(106.2038).round(2)).to eq(Money.new(106.20))
    end

    it "implements standard rounding for 1 digit" do
      expect(Money.new(27.25).round(1)).to eq(Money.new(27.3))
      expect(Money.new(27.45).round(1)).to eq(Money.new(27.5))
      expect(Money.new(27.55).round(1)).to eq(Money.new(27.6))
    end

  end

  describe "from_amount quacks like RubyMoney" do
    it "accepts numeric values" do
      expect(Money.from_amount(1)).to eq Money.from_cents(1_00)
      expect(Money.from_amount(1.0)).to eq Money.from_cents(1_00)
      expect(Money.from_amount("1".to_d)).to eq Money.from_cents(1_00)
    end

    it "accepts string values" do
      expect(Money.from_amount("1")).to eq Money.from_cents(1_00)
    end

    it "accepts nil values" do
      expect(Money.from_amount(nil)).to eq Money.from_cents(0)
    end

    it "accepts an optional currency parameter" do
      expect { Money.from_amount(1, "CAD") }.to_not raise_error
    end

    it "raises ArgumentError with unsupported argument" do
      expect { Money.from_amount(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe "YAML loading of old versions" do
    it "accepts BigDecimal values" do
      money = YAML.load(<<~EOS)
        ---
        !ruby/object:Money
          value: !ruby/object:BigDecimal 18:0.75E3
          cents: 75000
      EOS
      expect(money).to be == Money.new(750)
      expect(money.value).to be_a BigDecimal
    end

    it "accepts old float values..." do
      money = YAML.load(<<~EOS)
        ---
        !ruby/object:Money
          value: 750.00
          cents: 75000
      EOS
      expect(money).to be == Money.new(750)
      expect(money.value).to be_a BigDecimal
    end
  end
end
