# frozen_string_literal: true

class Money
  class Config
    attr_accessor :default_currency, :legacy_json_format, :legacy_deprecations

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
    end
  end
end
