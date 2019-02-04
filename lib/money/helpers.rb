# frozen_string_literal: true
require 'bigdecimal'

class Money
  module Helpers
    module_function

    NUMERIC_REGEX = /\A\s*[\+\-]?(\d+|\d*\.\d+)\s*\z/
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
          string_to_decimal(num)
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
        default = Money.current_currency || Money.default_currency
        raise(ArgumentError, 'missing currency') if default.nil? || default == ''
        value_to_currency(default)
      when 'xxx', 'XXX'
        Money::NULL_CURRENCY
      when String
        begin
          Currency.find!(currency)
        rescue Money::Currency::UnknownCurrency => error
          Money.deprecate(error.message)
          Money::NULL_CURRENCY
        end
      else
        raise ArgumentError, "could not parse as currency #{currency.inspect}"
      end
    end

    def string_to_decimal(num)
      unless num =~ NUMERIC_REGEX
        raise ArgumentError, "`#{num}` is not a number, consider using Money.parse('#{num}', currency)"
      end

      BigDecimal(num)
    end
  end
end
