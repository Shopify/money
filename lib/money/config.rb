# frozen_string_literal: true
require 'forwardable'

class Money
  class Config
    attr_accessor :parser, :default_currency

    def opt_in_v1?
      @opt_in_v1
    end

    def opt_in_v1!
      @opt_in_v1 = true
      Money.active_support_deprecator.behavior = :raise
      if @default_currency == Money::NULL_CURRENCY
        @default_currency = nil
      end
    end

    def initialize
      @parser = MoneyParser
      @default_currency = Money::NULL_CURRENCY
      @opt_in_v1 = false
    end
  end
end
