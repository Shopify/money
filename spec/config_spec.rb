# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Money::Config" do
  def configure
    old_config = Money.config
    Money.config = Money::Config.new.tap { |config| yield(config) }
    Money.config = old_config
  end

  describe 'opt_in_v1' do
    it 'defaults to not opt-in to v1' do
      expect(Money::Config.new.opt_in_v1?).to eq(false)
    end

    it 'opt_in_v1? returns true when opting in to v1' do
      configure do |config|
        config.opt_in_v1!
        expect(config.opt_in_v1?).to eq(true)
      end
    end

    it 'sets the deprecations to raise' do
      configure do |config|
        config.opt_in_v1!
        expect { Money.deprecate("test") }.to raise_error(ActiveSupport::DeprecationException)
      end
    end

    it 'removes the default currency if it was set to the NULL_CURRENCY' do
      configure do |config|
        config.default_currency = Money::NULL_CURRENCY
        config.opt_in_v1!
        expect(config.default_currency).to eq(nil)
      end
    end
  end

  describe 'parser' do
    it 'defaults to MoneyParser' do
      expect(Money::Config.new.parser).to eq(MoneyParser)
    end

    it 'can be set to a new parser' do
      configure do |config|
        config.parser = AccountingMoneyParser
        expect(config.parser).to eq(AccountingMoneyParser)
      end
    end
  end

  describe 'default_currency' do
    it 'defaults to NULL_CURRENCY' do
      expect(Money::Config.new.default_currency).to eq(Money::NULL_CURRENCY)
    end

    it 'can be set to a new currency' do
      configure do |config|
        config.default_currency = 'USD'
        expect(config.default_currency).to eq('USD')
      end
    end
  end
end
