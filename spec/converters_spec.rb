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
  end

  describe Money::Converters::LegacyDollarsConverter do
    let(:converter) { described_class.new }
    it 'always uses 100 as subunit_to_unit' do
      expect(converter.to_subunits(Money.new(1, usd))).to eq(100)
      expect(converter.from_subunits(100, usd)).to eq(Money.new(1, usd))
    end
  end
end
