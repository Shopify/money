# frozen_string_literal: true

class Money
  class Config
    attr_accessor :default_currency, :legacy_json_format, :legacy_deprecations, :experimental_crypto_currencies

    def legacy_default_currency!
      @default_currency ||= Money::NULL_CURRENCY
    end

    def legacy_deprecations!
      @legacy_deprecations = true
    end

    def legacy_json_format!
      @legacy_json_format = true
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
  end
end
