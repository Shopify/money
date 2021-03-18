# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Money::Config" do
  describe 'legacy_support' do
    it "respects the default currency" do
      configure(default_currency: 'USD', legacy_support: true) do
        expect(Money.default_currency).to eq("USD")
      end
    end

    it 'defaults to not opt-in to v1' do
      expect(Money::Config.new.legacy_support?).to eq(false)
    end

    it 'legacy_support? returns true when opting in to v1' do
      configure(legacy_support: true) do
        expect(Money.config.legacy_support?).to eq(true)
      end
    end

    it 'sets the deprecations to raise' do
      configure(legacy_support: true) do
        expect { Money.deprecate("test") }.to raise_error(ActiveSupport::DeprecationException)
      end
    end

    it 'legacy_support defaults to NULL_CURRENCY' do
      configure(legacy_support: true) do
        expect(Money.config.default_currency).to eq(Money::NULL_CURRENCY)
      end
    end
  end

  describe 'parser' do
    it 'defaults to MoneyParser' do
      expect(Money::Config.new.parser).to eq(MoneyParser)
    end

    it 'can be set to a new parser' do
      configure(parser: AccountingMoneyParser) do
        expect(Money.config.parser).to eq(AccountingMoneyParser)
      end
    end
  end

  describe 'default_currency' do
    it 'defaults to nil' do
      configure do
        expect(Money.config.default_currency).to eq(nil)
      end
    end

    it 'can be set to a new currency' do
      configure(default_currency: 'USD') do
        expect(Money.config.default_currency).to eq('USD')
      end
    end
  end
end
