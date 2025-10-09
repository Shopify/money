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
