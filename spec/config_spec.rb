# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Money::Config" do
  describe 'thread safety' do
    it 'does not share the same config across threads' do
      configure(legacy_deprecations: true, default_currency: 'USD') do
        expect(Money.config.legacy_deprecations).to eq(true)
        expect(Money.default_currency).to eq('USD')
        thread = Thread.new do
          expect(Money.config.legacy_deprecations).to eq(false)
          expect(Money.default_currency).to eq(nil)
        end
        thread.join
      end
    end
  end

  describe 'legacy_deprecations' do
    it "respects the default currency" do
      configure(default_currency: 'USD', legacy_deprecations: true) do
        expect(Money.default_currency).to eq("USD")
      end
    end

    it 'defaults to not opt-in to v1' do
      expect(Money::Config.new.legacy_deprecations).to eq(false)
    end

    it 'legacy_deprecations returns true when opting in to v1' do
      configure(legacy_deprecations: true) do
        expect(Money.config.legacy_deprecations).to eq(true)
      end
    end

    it 'sets the deprecations to raise' do
      configure(legacy_deprecations: true) do
        expect { Money.deprecate("test") }.to raise_error(ActiveSupport::DeprecationException)
      end
    end

    it 'legacy_deprecations defaults to NULL_CURRENCY' do
      configure(legacy_default_currency: true) do
        expect(Money.config.default_currency).to eq(Money::NULL_CURRENCY)
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
