# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Money::Config" do
  describe 'thread safety' do
    it 'does not share the same config across fibers' do
      configure(default_currency: 'USD') do
        expect(Money::Config.current.default_currency.to_s).to eq('USD')

        fiber = Fiber.new do
          Money::Config.current.default_currency = "EUR"

          expect(Money::Config.current.default_currency.to_s).to eq("EUR")

          :fiber_completed
        end
        # run the fiber
        expect(fiber.resume).to eq(:fiber_completed)

        # Verify main fiber's config was not affected
        expect(Money::Config.current.default_currency.to_s).to eq('USD')
      end
    end

    it 'isolates configuration between threads' do
      expect(Money::Config.current.default_currency).to eq(Money::Currency.find!('CAD'))

      thread = Thread.new do
        Money::Config.current.default_currency = "EUR"

        expect(Money::Config.current.default_currency).to eq(Money::Currency.find!("EUR"))
      end

      thread.join

      expect(Money::Config.current.default_currency).to eq(Money::Currency.find!('CAD'))
    end
  end

  describe 'default_currency' do
    it 'defaults to nil' do
      expect(Money::Config.new.default_currency).to eq(nil)
    end

    it 'can be set to a new currency' do
      configure(default_currency: 'USD') do
        expect(Money::Config.current.default_currency.to_s).to eq('USD')
      end
    end

    it 'raises ArgumentError for invalid currency' do
      config = Money::Config.new
      expect { config.default_currency = 123 }.to raise_error(ArgumentError, "Invalid currency")
    end
  end

  describe 'experimental_crypto_currencies' do
    it 'defaults to false' do
      expect(Money::Config.new.experimental_crypto_currencies).to eq(false)
    end

    it 'can be set to true' do
      config = Money::Config.new
      config.experimental_crypto_currencies = true
      expect(config.experimental_crypto_currencies).to be(true)
    end

    it 'can be set to true using the bang method' do
      config = Money::Config.new
      config.experimental_crypto_currencies!
      expect(config.experimental_crypto_currencies).to eq(true)
    end
  end

  describe 'custom_currency_path' do
    it 'defaults to nil' do
      expect(Money::Config.new.custom_currency_path).to eq(nil)
    end

    it 'can be set to a path' do
      config = Money::Config.new
      config.custom_currency_path = '/tmp/custom.yml'
      expect(config.custom_currency_path).to eq('/tmp/custom.yml')
    end
  end

  describe 'legacy_json_format' do
    it 'defaults to false' do
      expect(Money::Config.new.legacy_json_format).to eq(false)
    end

    it 'can be set to true using the bang method' do
      config = Money::Config.new
      config.legacy_json_format!
      expect(config.legacy_json_format).to eq(true)
    end
  end
end
