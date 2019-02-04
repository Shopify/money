require 'spec_helper'

RSpec.describe Money::Helpers do

  describe 'value_to_decimal' do
    let (:amount) { BigDecimal('1.23') }
    let (:money) { Money.new(amount) }

    it 'returns the value of a money object' do
      expect(subject.value_to_decimal(money)).to eq(amount)
    end

    it 'returns itself if it is already a big decimal' do
      expect(subject.value_to_decimal(BigDecimal('1.23'))).to eq(amount)
    end

    it 'returns zero when nil' do
      expect(subject.value_to_decimal(nil)).to eq(0)
    end

    it 'returns zero when empty' do
      expect(subject.value_to_decimal('')).to eq(0)
    end

    it 'returns the bigdecimal version of a integer' do
      expect(subject.value_to_decimal(1)).to eq(BigDecimal('1'))
    end

    it 'returns the bigdecimal version of a float' do
      expect(subject.value_to_decimal(1.23)).to eq(amount)
    end

    it 'returns the bigdecimal version of a rational' do
      expect(subject.value_to_decimal(amount.to_r)).to eq(amount)
    end

    it 'returns the bigdecimal version of a ruby number string' do
      expect(subject.value_to_decimal('1.23')).to eq(amount)
    end

    it 'returns the bigdecimal version of a ruby number string with whitespace padding' do
      expect(subject.value_to_decimal(' 1.23 ')).to eq(amount)
      expect(subject.value_to_decimal("1.23\n")).to eq(amount)
      expect(subject.value_to_decimal(' -1.23 ')).to eq(-amount)
    end

    it 'raises on invalid number strings' do
      expect { subject.value_to_decimal('1.23abc') }.to raise_error(ArgumentError)
      expect { subject.value_to_decimal("1.23\n23") }.to raise_error(ArgumentError)
    end

    it 'raises on invalid object' do
      expect { subject.value_to_decimal(OpenStruct.new(amount: 1)) }.to raise_error(ArgumentError)
    end

    it 'returns regular zero for a negative zero value' do
      expect(subject.value_to_decimal(-BigDecimal(0))).to eq(BigDecimal(0))
    end
  end

  describe 'subject.value_to_currency' do
    it 'returns itself if it is already a currency' do
      expect(subject.value_to_currency(Money::Currency.new('usd'))).to eq(Money::Currency.find!('usd'))
      expect(subject.value_to_currency(Money::NULL_CURRENCY)).to be_a(Money::NullCurrency)
    end

    it 'returns the default currency when value is nil' do
      expect(subject.value_to_currency(nil)).to eq(Money.default_currency)
    end

    it 'returns the default currency when value is empty' do
      expect(subject.value_to_currency('')).to eq(Money.default_currency)
    end

    it 'returns the default currency when value is xxx' do
      expect(subject.value_to_currency('xxx')).to eq(Money::NULL_CURRENCY)
    end

    it 'returns the current currency when value is set' do
      expect(Money.with_currency('USD') { subject.value_to_currency(nil) }).to eq(Money::Currency.find!('usd'))
    end

    it 'returns the matching currency' do
      expect(subject.value_to_currency('usd')).to eq(Money::Currency.new('USD'))
    end

    it 'returns the null currency when invalid iso is passed' do
      expect(Money).to receive(:deprecate).once
      expect(subject.value_to_currency('invalid')).to eq(Money::NULL_CURRENCY)
    end

    it 'raises on invalid object' do
      expect { subject.value_to_currency(OpenStruct.new(amount: 1)) }.to raise_error(ArgumentError)
      expect { subject.value_to_currency(1) }.to raise_error(ArgumentError)
    end
  end
end
