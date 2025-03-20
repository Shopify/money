# frozen_string_literal: true

class Money
  class Config
    class << self
      def current
        Thread.current[:shopify_money__config] ||= Money.config.dup
      end

      def current=(config)
        Thread.current[:shopify_money__config] = config
      end
    end

    attr_accessor :default_currency, :legacy_json_format, :legacy_deprecations, :experimental_crypto_currencies
    alias_method :current_currency, :default_currency
    alias_method :current_currency=, :default_currency=

    def legacy_default_currency!
      @default_currency ||= Money::NULL_CURRENCY
    end

    def legacy_deprecations!
      @legacy_deprecations = true
    end

    def legacy_json_format!
      @legacy_json_format = true
    end

    def experimental_crypto_currencies!
      @experimental_crypto_currencies = true
    end

    def initialize
      @default_currency = nil
      @legacy_json_format = false
      @legacy_deprecations = false
      @experimental_crypto_currencies = false
    end

    def without_legacy_deprecations(&block)
      old_legacy_deprecations = @legacy_deprecations
      @legacy_deprecations = false
      yield
    ensure
      @legacy_deprecations = old_legacy_deprecations
    end

    def with_currency(new_currency)
      old_currency = current_currency
      self.current_currency = new_currency
      yield
    ensure
      self.current_currency = old_currency
    end
  end
end
