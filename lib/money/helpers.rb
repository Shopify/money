# frozen_string_literal: true

require 'bigdecimal'

class Money
  module Helpers
    extend self

    DECIMAL_ZERO = BigDecimal(0).freeze
    MAX_DECIMAL = 21

    def value_to_decimal(num)
      value =
        case num
        when Money
          num.value
        when BigDecimal
          num
        when nil, 0, ''
          DECIMAL_ZERO
        when Integer
          BigDecimal(num)
        when Float
          BigDecimal(num, Float::DIG)
        when Rational
          BigDecimal(num, MAX_DECIMAL)
        when String
          BigDecimal(num)
        else
          raise ArgumentError, "could not parse as decimal #{num.inspect}"
        end
      return DECIMAL_ZERO if value.sign == BigDecimal::SIGN_NEGATIVE_ZERO
      value
    end

    def money_to_units(money, decimal_precision: money.explicit_decimal_precision? ? money.decimal_precision : nil)
      return money.subunits if decimal_precision.nil?

      (money.value * 10**decimal_precision).to_i
    end

    def money_from_units(units, currency, decimal_precision: nil)
      return Money.from_subunits(units, currency) if decimal_precision.nil?

      value = value_to_decimal(units) / 10**decimal_precision
      Money.new(value, currency, decimal_precision: decimal_precision)
    end

    def value_to_currency(currency)
      case currency
      when Money::Currency, Money::NullCurrency
        currency
      when nil, ''
        default = Money::Config.current.currency
        raise(Money::Currency::UnknownCurrency, 'missing currency') if default.nil? || default == ''
        value_to_currency(default)
      when 'xxx', 'XXX'
        Money::NULL_CURRENCY
      when String
        Currency.find!(currency)
      else
        raise ArgumentError, "could not parse as currency #{currency.inspect}"
      end
    end
  end
end
