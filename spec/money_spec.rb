# frozen_string_literal: true
require 'spec_helper'
require 'yaml'

RSpec.describe "Money" do
  let (:money) { Money.new(1) }
  let (:amount_money) { Money.new(1.23, 'USD') }
  let (:non_fractional_money) { Money.new(1, 'JPY') }
  let (:zero_money) { Money.new(0) }

  it "has a version" do
    expect(Money::VERSION).not_to(eq(nil))
  end

  context "default currency not set" do
    it "raises an error" do
      configure(default_currency: nil) do
        expect { money }.to raise_error(ArgumentError)
      end
    end
  end

  it ".configure the config" do
    config = Money::Config.new
    allow(Money::Config).to receive(:global).and_return(config)

    expect {
      Money.configure { |c| c.default_currency = "USD" }
    }.to change { config.default_currency }.from(nil).to(Money::Currency.find!("USD"))
  end

  it ".zero has no currency" do
    expect(Money.new(0, Money::NULL_CURRENCY).currency).to be_a(Money::NullCurrency)
  end

  it ".zero is a 0$ value" do
    expect(Money.new(0, Money::NULL_CURRENCY)).to eq(Money.new(0))
  end

  it "converts to a new currency" do
    expect(Money.new(10, "USD").convert_currency(150, "JPY")).to eq(Money.new(1500, "JPY"))
  end

  it "returns itself with to_money" do
    expect(money.to_money).to eq(money)
    expect(amount_money.to_money).to eq(amount_money)
  end

  it "#to_money uses the provided currency when it doesn't already have one" do
    expect(Money.new(1).to_money('CAD')).to eq(Money.new(1, 'CAD'))
  end

  it "#to_money works with money objects of the same currency" do
    expect(Money.new(1, 'CAD').to_money('CAD')).to eq(Money.new(1, 'CAD'))
  end

  it "#to_money works with money objects that doesn't have a currency" do
    money = Money.new(1, Money::NULL_CURRENCY).to_money('USD')
    expect(money.value).to eq(1)
    expect(money.currency.to_s).to eq('USD')

    money = Money.new(1, 'USD').to_money(Money::NULL_CURRENCY)
    expect(money.value).to eq(1)
    expect(money.currency.to_s).to eq('USD')
  end

  it "#to_money raises when changing currency" do
    expect{ Money.new(1, 'USD').to_money('CAD') }.to raise_error(Money::IncompatibleCurrencyError)
  end

  it "defaults to 0 when constructed with no arguments" do
    expect(Money.new).to eq(Money.new(0))
  end

  it "defaults to 0 when constructed with an empty string" do
    expect(Money.new('')).to eq(Money.new(0))
  end

  it "can be constructed with a string" do
    expect(Money.new('1')).to eq(Money.new(1))
  end

  it "can be constructed with a numeric" do
    expect(Money.new(1.00)).to eq(Money.new(1))
  end

  it "can be constructed with a money object" do
    expect(Money.new(Money.new(1))).to eq(Money.new(1))
    expect(Money.new(Money.new(1, "USD"), "USD")).to eq(Money.new(1, "USD"))
  end

  it "can be constructed with a money object with a null currency" do
    money = Money.new(Money.new(1, Money::NULL_CURRENCY), 'USD')
    expect(money.value).to eq(1)
    expect(money.currency.to_s).to eq('USD')

    money = Money.new(Money.new(1, 'USD'), Money::NULL_CURRENCY)
    expect(money.value).to eq(1)
    expect(money.currency.to_s).to eq('USD')
  end

  it "constructor raises when changing currency" do
    expect { Money.new(Money.new(1, 'USD'), 'CAD') }.to raise_error(Money::IncompatibleCurrencyError)
  end

  it "raises when constructed with an invalid string" do
    expect{ Money.new('invalid') }.to raise_error(ArgumentError)
  end

  it "to_s correctly displays the right number of decimal places" do
    expect(money.to_s).to eq("1.00")
    expect(non_fractional_money.to_s).to eq("1")
  end

  it "to_fs with a legacy_dollars style" do
    expect(amount_money.to_fs(:legacy_dollars)).to eq("1.23")
    expect(non_fractional_money.to_fs(:legacy_dollars)).to eq("1.00")
  end

  it "to_fs with a amount style" do
    expect(amount_money.to_fs(:amount)).to eq("1.23")
    expect(non_fractional_money.to_fs(:amount)).to eq("1")
  end

  it "to_s correctly displays negative numbers" do
    expect((-money).to_s).to eq("-1.00")
    expect((-amount_money).to_s).to eq("-1.23")
    expect((-non_fractional_money).to_s).to eq("-1")
    expect((-Money.new("0.05")).to_s).to eq("-0.05")
  end

  it "to_s rounds when  more fractions than currency allows" do
    expect(Money.new("9.999", "USD").to_s).to eq("10.00")
    expect(Money.new("9.889", "USD").to_s).to eq("9.89")
  end

  it "to_s does not round when fractions same as currency allows" do
    expect(Money.new("1.25", "USD").to_s).to eq("1.25")
    expect(Money.new("9.99", "USD").to_s).to eq("9.99")
    expect(Money.new("9.999", "BHD").to_s).to eq("9.999")
  end

  it "to_s does not round if amount is larger than float allows" do
    expect(Money.new("99999999999999.99", "USD").to_s).to eq("99999999999999.99")
    expect(Money.new("999999999999999999.99", "USD").to_s).to eq("999999999999999999.99")
  end

  it "to_fs formats with correct decimal places" do
    expect(amount_money.to_fs).to eq("1.23")
    expect(non_fractional_money.to_fs).to eq("1")
    expect(Money.new(1.2345, 'USD').to_fs).to eq("1.23")
    expect(Money.new(1.2345, 'BHD').to_fs).to eq("1.235")
  end

  it "to_fs raises ArgumentError on unsupported style" do
    expect{ money.to_fs(:some_weird_style) }.to raise_error(ArgumentError)
  end

  it "to_fs is aliased as to_s for backward compatibility" do
    expect(money.method(:to_s)).to eq(money.method(:to_fs))
  end

  it "to_fs is aliased as to_formatted_s for backward compatibility" do
    expect(money.method(:to_formatted_s)).to eq(money.method(:to_fs))
  end

  it "legacy_json_format makes as_json return the legacy format" do
    configure(legacy_json_format: true) do
      expect(Money.new(1, 'CAD').as_json).to eq("1.00")
    end
  end

  it "legacy_format correctly sets the json format" do
    expect(Money.new(1, 'CAD').as_json(legacy_format: true)).to eq("1.00")
    expect(Money.new(1, 'CAD').to_json(legacy_format: true)).to eq("1.00")
  end

  it "as_json as a json containing the value and currency" do
    expect(money.as_json).to eq(value: "1.00", currency: "CAD")
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

  it "raises when adding inconsistent currencies" do
    expect{ Money.new(5, 'USD') + Money.new(1, 'CAD') }.to raise_error(Money::IncompatibleCurrencyError)
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

  it "raises when multiplied by a money object" do
    expect{ (Money.new(3.3) * Money.new(1)) }.to raise_error(ArgumentError)
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

  it "returns cents in to_json" do
    configure(legacy_json_format: true) do
      expect(Money.new('1.23', 'USD').to_json).to eq('1.23')
    end
  end

  it "returns value and currency in to_json" do
    expect(Money.new(1.00).to_json).to eq('{"value":"1.00","currency":"CAD"}')
    expect(JSON.dump(Money.new(1.00, "CAD"))).to eq('{"value":"1.00","currency":"CAD"}')
  end

  describe ".from_hash" do
    it "is the inverse operation of #to_h" do
      one_cad = Money.new(1, "CAD")
      expect(Money.from_hash(one_cad.to_h)).to eq(one_cad)
    end

    it "creates Money object from hash with expected keys" do
      expect(Money.from_hash({ value: 1.01, currency: "CAD" })).to eq(Money.new(1.01, "CAD"))
    end

    it "raises if Hash does not have the expected keys" do
      expect { Money.from_hash({ "val": 1.0 }) }.to raise_error(KeyError)
    end
  end

  describe ".from_json" do
    it "is the inverse operation of #to_json" do
      one_cad = Money.new(1, "CAD")
      expect(Money.from_json(one_cad.to_json)).to eq(one_cad)
    end

    it "creates Money object from JSON-encoded string" do
      expect(Money.from_json('{ "value": 1.01, "currency": "CAD" }')).to eq(Money.new(1.01, "CAD"))
    end

    it "raises if JSON string is malformed" do
      expect { Money.from_json('{ "val": 1.0 }') }.to raise_error(KeyError)
    end
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

  describe '#from_subunits' do
    it "creates Money object from an integer value in cents and currency" do
      expect(Money.from_subunits(1950, 'CAD')).to eq(Money.new(19.50))
    end

    it "creates Money object from an integer value in dollars and currency with no cents" do
      expect(Money.from_subunits(1950, 'JPY')).to eq(Money.new(1950, 'JPY'))
    end

    describe 'with format specified' do
      it 'overrides the subunit_to_unit amount' do
        expect(Money.from_subunits(100, 'ISK', format: :stripe)).to eq(Money.new(1, 'ISK'))
      end

      it 'overrides the subunit_to_unit amount for UGX' do
        expect(Money.from_subunits(100, 'UGX', format: :stripe)).to eq(Money.new(1, 'UGX'))
      end

      it 'overrides the subunit_to_unit amount for USDC' do
        configure(experimental_crypto_currencies: true) do
          expect(Money.from_subunits(500000, "USDC", format: :stripe)).to eq(Money.new(0.50, 'USDC'))
        end
      end

      it 'fallbacks to the default subunit_to_unit amount if no override is specified' do
        expect(Money.from_subunits(100, 'USD', format: :stripe)).to eq(Money.new(1, 'USD'))
      end

      it 'raises if the format is not found' do
        expect { Money.from_subunits(100, 'ISK', format: :unknown) }.to(raise_error(ArgumentError))
      end
    end
  end

  it "raises when constructed with a NaN value" do
    expect { Money.new( 0.0 / 0) }.to raise_error(ArgumentError)
  end

  it "raises when constructed with positive infinity" do
    expect(Money).to receive(:deprecate).once
    Money.new(Float::INFINITY)
  end

  it "raises when constructed with negative infinity" do
    expect(Money).to receive(:deprecate).once
    Money.new(-Float::INFINITY)
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
    expect(Money.rational(Money.new(10.0, 'USD'), Money.new(15.0, 'USD'))).to eq(Rational(2,3))
  end

  it "raises when attempting to make a rational from different currencies" do
    expect { Money.rational(Money.new(10.0, 'USD'), Money.new(15.0, 'JPY')) }.to raise_error(Money::IncompatibleCurrencyError)
  end

  it "does not allocate a new money object when multiplying by 1" do
    expect((money * 1).object_id).to eq(money.object_id)
  end

  it "does not allocate a new money object when adding 0" do
    expect((money + 0).object_id).to eq(money.object_id)
  end

  it "does not allocate a new money object when subtracting 0" do
    expect((money - 0).object_id).to eq(money.object_id)
  end

  it "does not allocate when computing absolute value when already positive" do
    expect((money.abs).object_id).to eq(money.object_id)
  end

  it "does not allocate when computing floor value when already floored" do
    expect((money.floor).object_id).to eq(money.object_id)
  end

  it "does not allocate when computing floor value when already rounded" do
    expect((money.round).object_id).to eq(money.object_id)
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

    it "have the same hash value as $1" do
      expect(money.hash).to eq(Money.new(1.00).hash)
    end

    it "does not have the same hash value as $2" do
      expect(money.hash).to_not eq(Money.new(2.00).hash)
    end
  end

  describe('Comparable') do
    let (:cad_05) { Money.new(5.00, 'CAD') }
    let (:cad_10) { Money.new(10.00, 'CAD') }
    let (:cad_20) { Money.new(20.00, 'CAD') }
    let (:nil_05) { Money.new(5.00, Money::NULL_CURRENCY) }
    let (:nil_10) { Money.new(10.00, Money::NULL_CURRENCY) }
    let (:nil_20) { Money.new(20.00, Money::NULL_CURRENCY) }
    let (:usd_10) { Money.new(10.00, 'USD') }
    let (:jpy_10) { Money.new(10, 'JPY') }

    it "<=> can compare with and without currency" do
      expect(Money.new(1000, Money::NULL_CURRENCY) <=> Money.new(2000, 'JPY')).to eq(-1)
      expect(Money.new(2000, 'JPY') <=> Money.new(1000, Money::NULL_CURRENCY)).to eq(1)
    end

    it "<=> issues deprecation warning when comparing incompatible currency" do
      expect{Money.new(1000, 'USD') <=> Money.new(2000, 'JPY')}.to raise_error(Money::IncompatibleCurrencyError)
      expect{Money.new(2000, 'JPY') <=> Money.new(1000, 'USD')}.to raise_error(Money::IncompatibleCurrencyError)
    end

    describe('same values') do
      describe('same currencies') do
        it { expect(cad_10 <=> cad_10).to(eq(0)) }
        it { expect(cad_10 >  cad_10).to(eq(false)) }
        it { expect(cad_10 >= cad_10).to(eq(true)) }
        it { expect(cad_10 == cad_10).to(eq(true)) }
        it { expect(cad_10 <= cad_10).to(eq(true)) }
        it { expect(cad_10 <  cad_10).to(eq(false)) }
      end

      describe('null currency') do
        it { expect(cad_10 <=> nil_10).to(eq(0)) }
        it { expect(cad_10 >  nil_10).to(eq(false)) }
        it { expect(cad_10 >= nil_10).to(eq(true)) }
        it { expect(cad_10 == nil_10).to(eq(true)) }
        it { expect(cad_10 <= nil_10).to(eq(true)) }
        it { expect(cad_10 <  nil_10).to(eq(false)) }
      end

      describe('different currencies') do
        it { expect(cad_10 == usd_10).to(eq(false)) }
      end

      describe('coerced types') do
        it { expect(cad_10 <=> 10.00).to(eq(0)) }
        it { expect(cad_10 >   10.00).to(eq(false)) }
        it { expect(cad_10 >=  10.00).to(eq(true)) }
        it { expect(cad_10 ==  10.00).to(eq(false)) }
        it { expect(cad_10 <=  10.00).to(eq(true)) }
        it { expect(cad_10 <   10.00).to(eq(false)) }
        it { expect(cad_10 <=>'10.00').to(eq(0)) }
        it { expect(cad_10 >  '10.00').to(eq(false)) }
        it { expect(cad_10 >= '10.00').to(eq(true)) }
        it { expect(cad_10 == '10.00').to(eq(false)) }
        it { expect(cad_10 <= '10.00').to(eq(true)) }
        it { expect(cad_10 <  '10.00').to(eq(false)) }
      end

      describe('to_money coerced types') do
        let(:coercible_object) do
          double("coercible_object").tap do |mock|
            allow(mock).to receive(:to_money).with(any_args) { |currency| Money.new(10, currency) }
          end
        end

        it { expect { cad_10 <=> coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 >   coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 >=  coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 <=  coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 <   coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 +   coercible_object }.to(raise_error(TypeError)) }
        it { expect { cad_10 -   coercible_object }.to(raise_error(TypeError)) }
      end
    end

    describe('left lower than right') do
      describe('same currencies') do
        it { expect(cad_10 <=> cad_20).to(eq(-1)) }
        it { expect(cad_10 >   cad_20).to(eq(false)) }
        it { expect(cad_10 >=  cad_20).to(eq(false)) }
        it { expect(cad_10 ==  cad_20).to(eq(false)) }
        it { expect(cad_10 <=  cad_20).to(eq(true)) }
        it { expect(cad_10 <   cad_20).to(eq(true)) }
      end

      describe('null currency') do
        it { expect(cad_10 <=> nil_20).to(eq(-1)) }
        it { expect(cad_10 >   nil_20).to(eq(false)) }
        it { expect(cad_10 >=  nil_20).to(eq(false)) }
        it { expect(cad_10 ==  nil_20).to(eq(false)) }
        it { expect(cad_10 <=  nil_20).to(eq(true)) }
        it { expect(cad_10 <   nil_20).to(eq(true)) }
      end

      describe('to_money types') do
        it { expect(cad_10 <=> 20.00).to(eq(-1)) }
        it { expect(cad_10 >   20.00).to(eq(false)) }
        it { expect(cad_10 >=  20.00).to(eq(false)) }
        it { expect(cad_10 ==  20.00).to(eq(false)) }
        it { expect(cad_10 <=  20.00).to(eq(true)) }
        it { expect(cad_10 <   20.00).to(eq(true)) }
      end
    end

    describe('left greater than right') do
      describe('same currencies') do
        it { expect(cad_10 <=> cad_05).to(eq(1)) }
        it { expect(cad_10 >   cad_05).to(eq(true)) }
        it { expect(cad_10 >=  cad_05).to(eq(true)) }
        it { expect(cad_10 ==  cad_05).to(eq(false)) }
        it { expect(cad_10 <=  cad_05).to(eq(false)) }
        it { expect(cad_10 <   cad_05).to(eq(false)) }
      end

      describe('null currency') do
        it { expect(cad_10 <=> nil_05).to(eq(1)) }
        it { expect(cad_10 >   nil_05).to(eq(true)) }
        it { expect(cad_10 >=  nil_05).to(eq(true)) }
        it { expect(cad_10 ==  nil_05).to(eq(false)) }
        it { expect(cad_10 <=  nil_05).to(eq(false)) }
        it { expect(cad_10 <   nil_05).to(eq(false)) }
      end

      describe('to_money types') do
        it { expect(cad_10 <=> 5.00).to(eq(1)) }
        it { expect(cad_10 >   5.00).to(eq(true)) }
        it { expect(cad_10 >=  5.00).to(eq(true)) }
        it { expect(cad_10 ==  5.00).to(eq(false)) }
        it { expect(cad_10 <=  5.00).to(eq(false)) }
        it { expect(cad_10 <   5.00).to(eq(false)) }
      end
    end

    describe('any values, non-to_money types') do
      it { expect(cad_10 <=> nil).to(eq(nil)) }
      it { expect { cad_10 >  nil }.to(raise_error(ArgumentError)) }
      it { expect { cad_10 >= nil }.to(raise_error(ArgumentError)) }
      it { expect(cad_10 == nil).to(eq(false)) }
      it { expect { cad_10 <= nil }.to(raise_error(ArgumentError)) }
      it { expect { cad_10 <  nil }.to(raise_error(ArgumentError)) }
    end

    describe('infinity comparisons') do
      it { expect(cad_10 <=> Float::INFINITY).to(eq(-1)) }
      it { expect(cad_10 <  Float::INFINITY).to(eq(true)) }
      it { expect(cad_10 <= Float::INFINITY).to(eq(true)) }
      it { expect(cad_10 >  Float::INFINITY).to(eq(false)) }
      it { expect(cad_10 >= Float::INFINITY).to(eq(false)) }

      it { expect(cad_10 <=> -Float::INFINITY).to(eq(1)) }
      it { expect(cad_10 >  -Float::INFINITY).to(eq(true)) }
      it { expect(cad_10 >= -Float::INFINITY).to(eq(true)) }
      it { expect(cad_10 <  -Float::INFINITY).to(eq(false)) }
      it { expect(cad_10 <= -Float::INFINITY).to(eq(false)) }

      it { expect(jpy_10 <=> Float::INFINITY).to(eq(-1)) }
      it { expect(jpy_10 <  Float::INFINITY).to(eq(true)) }
      it { expect(jpy_10 <= Float::INFINITY).to(eq(true)) }
      it { expect(jpy_10 >  Float::INFINITY).to(eq(false)) }
      it { expect(jpy_10 >= Float::INFINITY).to(eq(false)) }

      it { expect(jpy_10 <=> -Float::INFINITY).to(eq(1)) }
      it { expect(jpy_10 >  -Float::INFINITY).to(eq(true)) }
      it { expect(jpy_10 >= -Float::INFINITY).to(eq(true)) }
      it { expect(jpy_10 <  -Float::INFINITY).to(eq(false)) }
      it { expect(jpy_10 <= -Float::INFINITY).to(eq(false)) }
    end
  end

  describe "#subunits" do
    it 'multiplies by the number of decimal places for the currency' do
      expect(Money.new(1, 'USD').subunits).to eq(100)
      expect(Money.new(1, 'JPY').subunits).to eq(1)
      expect(Money.new(1, 'IQD').subunits).to eq(1000)
      expect(Money.new(1).subunits).to eq(100)
    end

    describe 'with format specified' do
      it 'overrides the subunit_to_unit amount' do
        expect(Money.new(1, 'ISK').subunits(format: :stripe)).to eq(100)
      end

      it 'overrides the subunit_to_unit amount for UGX' do
        expect(Money.new(1, 'UGX').subunits(format: :stripe)).to eq(100)
      end

      it 'overrides the subunit_to_unit amount for USDC' do
        configure(experimental_crypto_currencies: true) do
          expect(Money.from_subunits(500000, "USDC", format: :stripe)).to eq(Money.new(0.50, 'USDC'))
        end
      end

      it 'fallbacks to the default subunit_to_unit amount if no override is specified' do
        expect(Money.new(1, 'USD').subunits(format: :stripe)).to eq(100)
      end

      it 'raises if the format is not found' do
        expect { Money.new(1, 'ISK').subunits(format: :unknown) }.to(raise_error(ArgumentError))
      end
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
    specify "#allocate is calculated by Money::Allocator#allocate" do
      expected = [Money.new(1), [Money.new(1)]]
      expect_any_instance_of(Money::Allocator).to receive(:allocate).with([0.5, 0.5], :roundrobin).and_return(expected)
      expect(Money.new(2).allocate([0.5, 0.5])).to eq(expected)
    end

    specify "#allocate does not lose pennies (integration test)" do
      moneys = Money.new(0.05).allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(0.02))
      expect(moneys[1]).to eq(Money.new(0.03))
    end

    specify "#allocate_max_amounts is calculated by Money::Allocator#allocate_max_amounts" do
      expected = [Money.new(1), [Money.new(1)]]
      expect_any_instance_of(Money::Allocator).to receive(:allocate_max_amounts).and_return(expected)
      expect(Money.new(2).allocate_max_amounts([0.5, 0.5])).to eq(expected)
    end

    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room for the remainder (integration test)" do
      expect(
        Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)]),
      ).to eq([Money.new(26), Money.new(4.75)])
    end
  end

  describe "split" do
    specify "#split needs at least one party" do
      expect {Money.new(1).split(0)}.to raise_error(ArgumentError)
      expect {Money.new(1).split(-1)}.to raise_error(ArgumentError)
      expect {Money.new(1).split(0.1)}.to raise_error(ArgumentError)
      expect(Money.new(1).split(BigDecimal("0.1e1")).to_a).to eq([Money.new(1)])
    end

    specify "#split can be zipped" do
      expect(Money.new(100).split(3).zip(Money.new(50).split(3)).to_a).to eq([
        [Money.new(33.34), Money.new(16.67)],
        [Money.new(33.33), Money.new(16.67)],
        [Money.new(33.33), Money.new(16.66)],
      ])
    end

    specify "#gives 1 cent to both people if we start with 2" do
      expect(Money.new(0.02).split(2).to_a).to eq([Money.new(0.01), Money.new(0.01)])
    end

    specify "#split may distribute no money to some parties if there isnt enough to go around" do
      expect(Money.new(0.02).split(3).to_a).to eq([Money.new(0.01), Money.new(0.01), Money.new(0)])
    end

    specify "#split does not lose pennies" do
      expect(Money.new(0.05).split(2).to_a).to eq([Money.new(0.03), Money.new(0.02)])
    end

    specify "#split does not lose dollars with non-decimal currencies" do
      expect(Money.new(5, 'JPY').split(2).to_a).to eq([Money.new(3, 'JPY'), Money.new(2, 'JPY')])
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

    specify "#split return respond to #first" do
      expect(Money.new(100).split(3).first).to eq(Money.new(33.34))
      expect(Money.new(100).split(3).first(2)).to eq([Money.new(33.34), Money.new(33.33)])

      expect(Money.new(100).split(10).first).to eq(Money.new(10))
      expect(Money.new(100).split(10).first(2)).to eq([Money.new(10), Money.new(10)])
      expect(Money.new(20).split(2).first(4)).to eq([Money.new(10), Money.new(10)])
    end

    specify "#split return respond to #last" do
      expect(Money.new(100).split(3).last).to eq(Money.new(33.33))
      expect(Money.new(100).split(3).last(2)).to eq([Money.new(33.33), Money.new(33.33)])
      expect(Money.new(20).split(2).last(4)).to eq([Money.new(10), Money.new(10)])
    end

    specify "#split return supports destructuring" do
      first, second = Money.new(100).split(3)
      expect(first).to eq(Money.new(33.34))
      expect(second).to eq(Money.new(33.33))

      first, *rest = Money.new(100).split(3)
      expect(first).to eq(Money.new(33.34))
      expect(rest).to eq([Money.new(33.33), Money.new(33.33)])
    end

    specify "#split return can be reversed" do
      list = Money.new(100).split(3)
      expect(list.first).to eq(Money.new(33.34))
      expect(list.last).to eq(Money.new(33.33))

      list = list.reverse
      expect(list.first).to eq(Money.new(33.33))
      expect(list.last).to eq(Money.new(33.34))
    end
  end

  describe "calculate_splits" do
    specify "#calculate_splits gives 1 cent to both people if we start with 2" do
      actual = Money.new(0.02, 'CAD').calculate_splits(2)

      expect(actual).to eq({
        Money.new(0.01, 'CAD') => 2,
      })
    end

    specify "#calculate_splits gives an extra penny to one" do
      actual = Money.new(0.04, 'CAD').calculate_splits(3)

      expect(actual).to eq({
        Money.new(0.02, 'CAD') => 1,
        Money.new(0.01, 'CAD') => 2,
      })
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
    it "accepts an optional currency parameter" do
      expect { Money.from_amount(1, "CAD") }.to_not raise_error
    end

    it "accepts Rational number" do
      expect(Money.from_amount(Rational("999999999999999999.999")).value).to eql(BigDecimal("1000000000000000000", Money::Helpers::MAX_DECIMAL))
      expect(Money.from_amount(Rational("999999999999999999.99")).value).to eql(BigDecimal("999999999999999999.99", Money::Helpers::MAX_DECIMAL))
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

    it "does not change BigDecimal value to Integer while rounding for currencies without subunits" do
      money = Money.new(100, 'JPY').to_yaml
      expect(money).to eq("--- !ruby/object:Money\nvalue: '100.0'\ncurrency: JPY\n")
    end
  end

  describe "YAML deserialization" do
    it "accepts values with currencies" do
      money = yaml_load("--- !ruby/object:Money\nvalue: '750.0'\ncurrency: USD\n")
      expect(money).to eq(Money.new(750, 'usd'))
    end

    it "accepts values with null currencies" do
      money = yaml_load("--- !ruby/object:Money\nvalue: '750.0'\ncurrency: XXX\n")
      expect(money).to eq(Money.new(750))
    end

    it "accepts serialized NullCurrency objects" do
      money = yaml_load(<<~EOS)
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
      money = yaml_load(<<~EOS)
        ---
        !ruby/object:Money
          value: !ruby/object:BigDecimal 18:0.75E3
          cents: 75000
      EOS
      expect(money).to be == Money.new(750)
      expect(money.value).to be_a BigDecimal
    end

    it "accepts old float values..." do
      money = yaml_load(<<~EOS)
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

  describe '.with_currency' do
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

    it "accepts nil as currency" do
      money = nil
      Money.with_currency(nil) do
        money = Money.new(1.00)
      end
      # uses the default currency
      expect(money.currency.iso_code).to eq('CAD')
    end

    context "with .default_currency set" do
      around(:each) { |test| configure(default_currency: Money::Currency.new('EUR')) { test.run }}

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

  describe ".current_currency" do
    it "gets and sets the current currency via Config.current" do
      Money.current_currency = "USD"
      expect(Money.default_currency.iso_code).to eq("CAD")
      expect(Money.current_currency.iso_code).to eq("USD")
    end
  end

  describe 'from_subunits' do
    it 'creates money from subunits using ISO4217 format' do
      expect(Money.from_subunits(100, 'USD')).to eq(Money.new(1.00, 'USD'))
      expect(Money.from_subunits(10, 'JPY')).to eq(Money.new(10, 'JPY'))
    end

    it 'creates money from subunits using custom format' do
      expect(Money.from_subunits(100, 'USD', format: :iso4217)).to eq(Money.new(1.00, 'USD'))
      expect(Money.from_subunits(100, 'USD', format: :stripe)).to eq(Money.new(1.00, 'USD'))
    end

    it 'raises error for unknown format' do
      expect {
        Money.from_subunits(100, 'USD', format: :unknown)
      }.to raise_error(ArgumentError, /unknown format/)
    end
  end

  describe 'subunits' do
    it 'converts money to subunits using ISO4217 format' do
      expect(Money.new(1.00, 'USD').subunits).to eq(100)
      expect(Money.new(10, 'JPY').subunits).to eq(10)
    end

    it 'converts money to subunits using custom format' do
      expect(Money.new(1.00, 'USD').subunits(format: :iso4217)).to eq(100)
      expect(Money.new(1.00, 'USD').subunits(format: :stripe)).to eq(100)
    end

    it 'raises error for unknown format' do
      expect {
        Money.new(1.00, 'USD').subunits(format: :unknown)
      }.to raise_error(ArgumentError, /unknown format/)
    end
  end
end
