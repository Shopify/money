# frozen_string_literal: true
require 'forwardable'

class Money
  class Config
    attr_accessor :parser, :default_currency

    def legacy_support?
      @legacy_support
    end

    def legacy_support!
      @legacy_support = true
      @default_currency ||= Money::NULL_CURRENCY
    end

    def initialize
      @parser = MoneyParser
      @default_currency = nil
      @legacy_support = false
    end
  end
end
