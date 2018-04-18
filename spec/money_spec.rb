require 'spec_helper'
require 'yaml'

RSpec.describe "Money" do

  let (:money) {Money.new(1)}
  let (:amount_money) { Money.new(1.23, 'USD') }
  let (:non_fractional_money) { Money.new(1, 'JPY') }
  let (:zero_money) { Money.new(0) }

  it "is contructable with empty class method" do
    expect(Money.empty).to eq(Money.new)
  end

  context "default currency not set" do
    before(:each) do
      @default_currency = Money.default_currency
      Money.default_currency = nil
    end
    after(:each) do
      Money.default_currency = @default_currency
    end

    it "raises an error" do
      expect { money }.to raise_error(ArgumentError)
    end
  end

  it ".zero has no currency" do
    expect(Money.zero.currency).to be_a(Money::NullCurrency)
  end

  it ".zero is a 0$ value" do
    expect(Money.zero).to eq(Money.new(0))
  end

  it "returns itself with to_money" do
    expect(money.to_money).to eq(money)
  end

  it "defaults to 0 when constructed with no arguments" do
    expect(Money.new).to eq(Money.new(0))
  end

  it "defaults to 0 when constructed with an empty string" do
    expect(Money.new('')).to eq(Money.new(0))
  end

  it "defaults to 0 when constructed with an invalid string" do
    expect(Money).to receive(:deprecate).once
    expect(Money.new('invalid')).to eq(Money.new(0.00))
  end

  it "to_s correctly displays the right number of decimal places" do
    expect(money.to_s).to eq("1.00")
    expect(non_fractional_money.to_s).to eq("1")
  end

  it "to_s with a legacy_dollars style" do
    expect(amount_money.to_s(:legacy_dollars)).to eq("1.23")
    expect(non_fractional_money.to_s(:legacy_dollars)).to eq("1.00")
  end

  it "to_s with a amount style" do
    expect(amount_money.to_s(:amount)).to eq("1.23")
    expect(non_fractional_money.to_s(:amount)).to eq("1")
  end

  it "as_json as a float with 2 decimal places" do
    expect(money.as_json).to eq("1.00")
  end

  it "is constructable with a BigDecimal" do
    expect(Money.new(BigDecimal("1.23"))).to eq(Money.new(1.23))
  end

  it "is constructable with an Integer" do
    expect(Money.new(3)).to eq(Money.new(3.00))
  end

  it "is construcatable with a Float" do
    expect(Money.new(3.00)).to eq(Money.new(BigDecimal('3.00')))
  end

  it "is construcatable with a String" do
    expect(Money.new('3.00')).to eq(Money.new(3.00))
  end

  it "is aware of the currency" do
    expect(Money.new(1.00, 'CAD').currency.iso_code).to eq('CAD')
  end

  it "is addable" do
    expect((Money.new(1.51) + Money.new(3.49))).to eq(Money.new(5.00))
  end

  it "keeps currency across calculations" do
    expect(Money.new(1, 'USD') - Money.new(1, 'USD') + Money.new(1.23, Money::NULL_CURRENCY)).to eq(Money.new(1.23, 'USD'))
  end

  it "raises error if added other is not compatible" do
    expect{ Money.new(5.00) + nil }.to raise_error(TypeError)
  end

  it "is able to add $0 + $0" do
    expect((Money.new + Money.new)).to eq(Money.new)
  end

  it "adds inconsistent currencies" do
    expect(Money).to receive(:deprecate).once
    expect(Money.new(5, 'USD') + Money.new(1, 'CAD')).to eq(Money.new(6, 'USD'))
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

  it "logs a deprecation warning when adding across currencies" do
    expect(Money).to receive(:deprecate)
    expect(Money.new(10, 'USD') - Money.new(1, 'JPY')).to eq(Money.new(9, 'USD'))
  end

  it "keeps currency when doing a computation with a null currency" do
    currency = Money.new(10, 'JPY')
    no_currency = Money.new(1, Money::NULL_CURRENCY)
    expect((no_currency + currency).currency).to eq(Money::Currency.find!('JPY'))
    expect((currency - no_currency).currency).to eq(Money::Currency.find!('JPY'))
  end

  it "does not log a deprecation warning when adding with a null currency value" do
    currency = Money.new(10, 'USD')
    no_currency = Money.new(1, Money::NULL_CURRENCY)
    expect(Money).not_to receive(:deprecate)
    expect(no_currency + currency).to eq(Money.new(11, 'USD'))
    expect(currency - no_currency).to eq(Money.new(9, 'USD'))
  end

  it "is substractable to a negative amount" do
    expect((Money.new(0.00) - Money.new(1.00))).to eq(Money.new("-1.00"))
  end

  it "is never negative zero" do
    expect(Money.new(-0.00).to_s).to eq("0.00")
    expect((Money.new(0) * -1).to_s).to eq("0.00")
  end

  it "#inspects to a presentable string" do
    expect(money.inspect).to eq("#<Money value:1.00 currency:CAD>")
    expect(Money.new(1, 'JPY').inspect).to eq("#<Money value:1 currency:JPY>")
    expect(Money.new(1, 'JOD').inspect).to eq("#<Money value:1.000 currency:JOD>")
  end

  it "is inspectable within an array" do
    expect([money].inspect).to eq("[#<Money value:1.00 currency:CAD>]")
  end

  it "correctly support eql? as a value object" do
    expect(money).to eq(Money.new(1))
    expect(money).to eq(Money.new(1, 'CAD'))
  end

  it "does not eql? with a non money object" do
    expect(money).to_not eq(1)
    expect(money).to_not eq(OpenStruct.new(value: 1))
  end

  it "does not eql? when currency missmatch" do
    expect(money).to_not eq(Money.new(1, 'JPY'))
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

  it "is multipliable by a money object" do
    expect(Money).to receive(:deprecate).once
    expect((Money.new(3.3) * Money.new(1))).to eq(Money.new(3.3))
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
    expect(Money.new(1.29).to_d).to eq(BigDecimal('1.29'))
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

  it "is creatable from an integer value in cents and currency" do
    expect(Money.from_subunits(1950, 'CAD')).to eq(Money.new(19.50))
  end

  it "is creatable from an integer value in dollars and currency with no cents" do
    expect(Money.from_subunits(1950, 'JPY')).to eq(Money.new(1950, 'JPY'))
  end

  it "raises when constructed with a NaN value" do
    expect { Money.new( 0.0 / 0) }.to raise_error(ArgumentError)
  end

  it "is comparable with non-money objects" do
    expect(money).not_to eq(nil)
  end

  it "supports floor" do
    expect(Money.new(15.52).floor).to eq(Money.new(15.00))
    expect(Money.new(18.99).floor).to eq(Money.new(18.00))
    expect(Money.new(21).floor).to eq(Money.new(21))
  end

  it "generates a true rational" do
    expect(Money.rational(Money.new(10.0), Money.new(15.0))).to eq(Rational(2,3))
    expect(Money).to receive(:deprecate).once
    expect(Money.rational(Money.new(10.0, 'USD'), Money.new(15.0, 'JPY'))).to eq(Rational(2,3))
  end

  describe "frozen with amount of $1" do
    let (:money) { Money.new(1.00) }

    it "is equals to $1" do
      expect(money).to eq(Money.new(1.00))
    end

    it "is not equals to $2" do
      expect(money).not_to eq(Money.new(2.00))
    end

    it "<=> $1 is 0" do
      expect((money <=> Money.new(1.00))).to eq(0)
    end

    it "<=> $2 is -1" do
      expect((money <=> Money.new(2.00))).to eq(-1)
    end

    it "<=> $0.50 equals 1" do
      expect((money <=> Money.new(0.50))).to eq(1)
    end

    it "<=> works with non-money objects" do
      expect((money <=> 1)).to eq(0)
      expect((money <=> 2)).to eq(-1)
      expect((money <=> 0.5)).to eq(1)
      expect((1 <=> money)).to eq(0)
      expect((2 <=> money)).to eq(1)
      expect((0.5 <=> money)).to eq(-1)
    end

    it "raises error if compared other is not compatible" do
      expect{ Money.new(5.00) <=> nil }.to raise_error(TypeError)
    end

    it "have the same hash value as $1" do
      expect(money.hash).to eq(Money.new(1.00).hash)
    end

    it "does not have the same hash value as $2" do
      expect(money.hash).to eq(Money.new(1.00).hash)
    end

    it "<=> can compare with and without currency" do
      expect(Money.new(1000, Money::NULL_CURRENCY) <=> Money.new(2000, 'JPY')).to eq(-1)
      expect(Money.new(2000, 'JPY') <=> Money.new(1000, Money::NULL_CURRENCY)).to eq(1)
    end

    it "<=> issues deprecation warning when comparing incompatible currency" do
      expect(Money).to receive(:deprecate).twice
      expect(Money.new(1000, 'USD') <=> Money.new(2000, 'JPY')).to eq(-1)
      expect(Money.new(2000, 'JPY') <=> Money.new(1000, 'USD')).to eq(1)
    end
  end

  describe "#subunits" do
    it 'multiplies by the number of decimal places for the currency' do
      expect(Money.new(1, 'USD').subunits).to eq(100)
      expect(Money.new(1, 'JPY').subunits).to eq(1)
      expect(Money.new(1, 'IQD').subunits).to eq(1000)
      expect(Money.new(1).subunits).to eq(100)
    end
  end

  describe "value" do
    it "rounds to the number of minor units provided by the currency" do
      expect(Money.new(1.1111, 'USD').value).to eq(1.11)
      expect(Money.new(1.1111, 'JPY').value).to eq(1)
      expect(Money.new(1.1111, 'IQD').value).to eq(1.111)
    end
  end

  describe "with amount of $0" do
    let (:money) { Money.new(0) }

    it "is zero" do
      expect(money).to be_zero
    end

    it "is greater than -$1" do
      expect(money).to be > Money.new("-1.00")
    end

    it "is greater than or equal to $0" do
      expect(money).to be >= Money.new
    end

    it "is less than or equal to $0" do
      expect(money).to be <= Money.new
    end

    it "is less than $1" do
      expect(money).to be < Money.new(1.00)
    end
  end

  describe "with amount of $1" do
    let (:money) { Money.new(1.00) }

    it "is not zero" do
      expect(money).not_to be_zero
    end

    it "returns cents as a decimal value = 1.00" do
      expect(money.value).to eq(BigDecimal("1.00"))
    end

    it "returns cents as 100 cents" do
      expect(money.cents).to eq(100)
    end

    it "returns cents as 100 cents" do
      expect(money.subunits).to eq(100)
    end

    it "is greater than $0" do
      expect(money).to be > Money.new(0.00)
    end

    it "is less than $2" do
      expect(money).to be < Money.new(2.00)
    end

    it "is equal to $1" do
      expect(money).to eq(Money.new(1.00))
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

    specify "#allocate does not lose dollars with non-decimal currency" do
      moneys = Money.new(5, 'JPY').allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(2, 'JPY'))
      expect(moneys[1]).to eq(Money.new(3, 'JPY'))
    end

    specify "#allocate does not lose dollars with three decimal currency" do
      moneys = Money.new(0.005, 'JOD').allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(0.002, 'JOD'))
      expect(moneys[1]).to eq(Money.new(0.003, 'JOD'))
    end

    specify "#allocate does not lose pennies even when given a lossy split" do
      moneys = Money.new(1).allocate([0.333,0.333, 0.333])
      expect(moneys[0].subunits).to eq(34)
      expect(moneys[1].subunits).to eq(33)
      expect(moneys[2].subunits).to eq(33)
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

    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room for the remainder with currency" do
      expect(
        Money.new(3075, 'JPY').allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
    end

    specify "#allocate_max_amounts legal computation with no currency objects" do
      expect(
        Money.new(3075, 'JPY').allocate_max_amounts([2600, 475]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])

      expect(
        Money.new(3075, Money::NULL_CURRENCY).allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
    end

    specify "#allocate_max_amounts illegal computation across currencies" do
      expect {
        Money.new(3075, 'USD').allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
      }.to raise_error(ArgumentError)
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

    specify "#split does not lose dollars with non-decimal currencies" do
      expect(Money.new(5, 'JPY').split(2)).to eq([Money.new(3, 'JPY'), Money.new(2, 'JPY')])
    end

    specify "#split a dollar" do
      moneys = Money.new(1).split(3)
      expect(moneys[0].subunits).to eq(34)
      expect(moneys[1].subunits).to eq(33)
      expect(moneys[2].subunits).to eq(33)
    end

    specify "#split a 100 yen" do
      moneys = Money.new(100, 'JPY').split(3)
      expect(moneys[0].value).to eq(34)
      expect(moneys[1].value).to eq(33)
      expect(moneys[2].value).to eq(33)
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
    let (:money) { Money.new(1.125) }

    it "rounds 3rd decimal place" do
      expect(money.value).to eq(BigDecimal("1.13"))
    end
  end

  describe "parser dependency injection" do
    before(:each) { Money.parser = AccountingMoneyParser }
    after(:each) { Money.parser = MoneyParser }

    it "keeps AccountingMoneyParser class on new money objects" do
      expect(Money.new.class.parser).to eq(AccountingMoneyParser)
    end

    it "supports parenthesis from AccountingMoneyParser" do
      expect(Money.parse("($5.00)")).to eq(Money.new(-5))
    end

    it "supports parenthesis from AccountingMoneyParser for .to_money" do
      expect("($5.00)".to_money).to eq(Money.new(-5))
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
      expect(Money.from_amount(BigDecimal("1"))).to eq Money.from_cents(1_00)
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

    it "accepts Rational number" do
      expect(Money.from_amount(Rational("999999999999999999.999")).value).to eql(BigDecimal.new("1000000000000000000", Money::Helpers::MAX_DECIMAL))
      expect(Money.from_amount(Rational("999999999999999999.99")).value).to eql(BigDecimal.new("999999999999999999.99", Money::Helpers::MAX_DECIMAL))
    end

    it "raises ArgumentError with unsupported argument" do
      expect { Money.from_amount(Object.new) }.to raise_error(ArgumentError)
    end
  end

  describe "YAML serialization" do
    it "accepts values with currencies" do
      money = YAML.dump(Money.new(750, 'usd'))
      expect(money).to eq("--- !ruby/object:Money\nvalue: '750.0'\ncurrency: USD\n")
    end
  end

  describe "YAML deserialization" do

    it "accepts values with currencies" do
      money = YAML.load("--- !ruby/object:Money\nvalue: '750.0'\ncurrency: USD\n")
      expect(money).to eq(Money.new(750, 'usd'))
    end

    it "accepts values with null currencies" do
      money = YAML.load("--- !ruby/object:Money\nvalue: '750.0'\ncurrency: XXX\n")
      expect(money).to eq(Money.new(750))
    end

    it "accepts serialized NullCurrency objects" do
      money = YAML.load(<<~EOS)
        ---
        !ruby/object:Money
          currency: !ruby/object:Money::NullCurrency
            symbol: >-
              $
            disambiguate_symbol:
            iso_code: >-
              XXX
            iso_numeric: >-
              999
            name: >-
              No Currency
            smallest_denomination: 1
            subunit_to_unit: 100
            minor_units: 2
          value: !ruby/object:BigDecimal 27:0.6935E2
          cents: 6935
      EOS
      expect(money).to eq(Money.new(69.35, Money::NULL_CURRENCY))
    end

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

  describe('.deprecate') do
    it "uses ruby warn if active support is not defined" do
      stub_const("ACTIVE_SUPPORT_DEFINED", false)
      expect(Kernel).to receive(:warn).once
      Money.deprecate('ok')
    end

    it "uses active support warn if active support is defined" do
      expect(Kernel).to receive(:warn).never
      expect_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).once
      Money.deprecate('ok')
    end

    it "only sends a callstack of events outside of the money gem" do
      expect_any_instance_of(ActiveSupport::Deprecation).to receive(:warn).with(
        -> (message) { message == "[Shopify/Money] message\n" },
        -> (callstack) { !callstack.first.to_s.include?('gems/money') && callstack.size > 0 }
      )
      Money.deprecate('message')
    end
  end

  describe '#use_currency' do
    it "allows setting the implicit default currency for a block scope" do
      money = nil
      Money.with_currency('CAD') do
        money = Money.new(1.00)
      end

      expect(money.currency.iso_code).to eq('CAD')
    end

    it "does not use the currency for a block scope when explicitly set" do
      money = nil
      Money.with_currency('CAD') do
        money = Money.new(1.00, 'USD')
      end

      expect(money.currency.iso_code).to eq('USD')
    end

    context "with .default_currency set" do
      before(:each) { Money.default_currency = Money::Currency.new('EUR') }
      after(:each) { Money.default_currency = Money::NULL_CURRENCY }

      it "can be nested and falls back to default_currency outside of the blocks" do
        money2, money3 = nil

        money1 = Money.new(1.00)
        Money.with_currency('CAD') do
          Money.with_currency('USD') do
            money2 = Money.new(1.00)
          end
          money3 = Money.new(1.00)
        end
        money4 = Money.new(1.00)

        expect(money1.currency.iso_code).to eq('EUR')
        expect(money2.currency.iso_code).to eq('USD')
        expect(money3.currency.iso_code).to eq('CAD')
        expect(money4.currency.iso_code).to eq('EUR')
      end
    end
  end

  describe '.clamp' do
    let(:max) { 9000 }
    let(:min) { -max }

    it 'returns the same value if the value is within the min..max range' do
      money = Money.new(5000, 'EUR').clamp(min, max)
      expect(money.value).to eq(5000)
      expect(money.currency.iso_code).to eq('EUR')
    end

    it 'returns the max value if the original value is larger' do
      money = Money.new(9001, 'EUR').clamp(min, max)
      expect(money.clamp(min, max).value).to eq(9000)
      expect(money.clamp(min, max).currency.iso_code).to eq('EUR')
    end

    it 'returns the min value if the original value is smaller' do
      money = Money.new(-9001, 'EUR').clamp(min, max)
      expect(money.value).to eq(-9000)
      expect(money.currency.iso_code).to eq('EUR')
    end
  end
end
