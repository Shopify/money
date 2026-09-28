# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Money::Converters do
  let(:usd) { Money::Currency.find!('USD') }
  let(:ugx) { Money::Currency.find!('UGX') }

  describe '.for' do
    it 'returns Iso4217Converter for :iso4217' do
      expect(Money::Converters.for(:iso4217)).to be_a(Money::Converters::Iso4217Converter)
    end

    it 'returns StripeConverter for :stripe' do
      expect(Money::Converters.for(:stripe)).to be_a(Money::Converters::StripeConverter)
    end

    it 'returns LegacyDollarsConverter for :legacy_dollar' do
      expect(Money::Converters.for(:legacy_dollar)).to be_a(Money::Converters::LegacyDollarsConverter)
    end

    it 'raises ArgumentError for unknown format' do
      expect { Money::Converters.for(:unknown) }.to raise_error(ArgumentError, /unknown format/)
    end
  end

  describe 'registering a custom converter' do
    class DummyConverter < Money::Converters::Converter
      def subunit_to_unit(currency); 42; end
    end

    class InvalidConverter < Money::Converters::Converter
      # Intentionally not implementing subunit_to_unit
    end

    after { Money::Converters.subunit_converters.delete(:dummy) }

    it 'registers and uses a custom converter' do
      Money::Converters.register(:dummy, DummyConverter)
      converter = Money::Converters.for(:dummy)
      expect(converter).to be_a(DummyConverter)
      expect(converter.to_subunits(Money.new(1, 'USD'))).to eq(42)
    end

    it 'raises NotImplementedError when subunit_to_unit is not implemented' do
      Money::Converters.register(:invalid, InvalidConverter)
      converter = Money::Converters.for(:invalid)
      expect { converter.to_subunits(Money.new(1, 'USD')) }.to raise_error(NotImplementedError, "subunit_to_unit method must be implemented in subclasses")
    end
  end

  describe Money::Converters::Iso4217Converter do
    let(:converter) { described_class.new }
    it 'uses currency.subunit_to_unit' do
      expect(converter.to_subunits(Money.new(1, usd))).to eq(100)
      expect(converter.from_subunits(100, usd)).to eq(Money.new(1, usd))
    end

    it 'rounds retained calculation precision when converting to subunits' do
      expect(converter.to_subunits(Money.new("0.0099", usd, decimal_precision: 2))).to eq(1)
      expect(converter.to_subunits(Money.new("0.0057", "JOD", decimal_precision: 3))).to eq(6)
    end

    it 'uses integer currency subunits independently of computation precision' do
      expect(converter.to_subunits(Money.new("0.0149", usd, decimal_precision: 3))).to eq(1)
      expect(converter.to_subunits(Money.new("-0.0149", usd, decimal_precision: 3))).to eq(-1)
      expect(converter.to_subunits(Money.new("1.6", "JPY", decimal_precision: 4))).to eq(2)
      expect(Money.new("0.057", "USD", decimal_precision: 4).subunits).to eq(6)
    end

    it 'returns integer ISO subunits across declared precisions without changing the raw value' do
      { "JPY" => 1, "USD" => 123, "BHD" => 1235 }.each do |currency, units|
        [0, 2, 5].each do |precision|
          [1, -1].each do |sign|
            raw_value = BigDecimal("1.2349") * sign
            money = Money.new(raw_value, currency, decimal_precision: precision)
            subunits = money.subunits(format: :iso4217)

            expect(subunits).to be_a(Integer)
            expect(subunits).to eq(units * sign)
            expect(money.value).to eq(raw_value)
          end
        end
      end
    end
  end

  describe Money::Converters::StripeConverter do
    let(:converter) { described_class.new }

    it 'uses Stripe special cases' do
      expect(converter.to_subunits(Money.new(1, ugx))).to eq(100)
      expect(converter.from_subunits(100, ugx)).to eq(Money.new(1, ugx))
      expect(converter.to_subunits(Money.new(1, usd))).to eq(100)
      expect(converter.from_subunits(100, usd)).to eq(Money.new(1, usd))
    end

    it 'handles USDC if present' do
      configure(experimental_crypto_currencies: true) do
        expect(converter.to_subunits(Money.new(1, "usdc"))).to eq(1_000_000)
        expect(converter.from_subunits(1_000_000, "usdc")).to eq(Money.new(1, "usdc"))
      end
    end

    it 'uses Stripe currency units independently of explicit computation precision' do
      money = Money.new("1.0149", ugx, decimal_precision: 3)

      expect(money.subunits(format: :stripe)).to eq(101)
      expect(money.subunits(format: :stripe)).to be_a(Integer)
      expect(money.subunits(format: :iso4217)).to eq(1)
      expect(money.value).to eq(BigDecimal("1.0149"))
    end
  end

  describe Money::Converters::LegacyDollarsConverter do
    let(:converter) { described_class.new }
    it 'always uses 100 as subunit_to_unit' do
      expect(converter.to_subunits(Money.new(1, usd))).to eq(100)
      expect(converter.from_subunits(100, usd)).to eq(Money.new(1, usd))
    end

    it 'keeps legacy dollar units for explicit precision without double rounding' do
      money = Money.new("-1.0149", "JPY", decimal_precision: 3)

      expect(money.subunits(format: :legacy_dollar)).to eq(-101)
      expect(money.subunits(format: :legacy_dollar)).to be_a(Integer)
      expect(money.subunits(format: :iso4217)).to eq(-1)
      expect(money.value).to eq(BigDecimal("-1.0149"))
    end
  end
end
