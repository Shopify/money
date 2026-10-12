# frozen_string_literal: true

require 'bigdecimal'

class Money
  module Helpers
    extend self

    DECIMAL_ZERO = BigDecimal(0).freeze
    MAX_DECIMAL = 21
    FLOAT_DIG = Float::DIG
    SIGN_NEGATIVE_ZERO = BigDecimal::SIGN_NEGATIVE_ZERO
    private_constant :FLOAT_DIG, :SIGN_NEGATIVE_ZERO

    def value_to_decimal(num)
      # Ordered by frequency; branches that cannot produce a negative zero
      # (Integer, nil, BigDecimal input already checked) return directly.
      value =
        case num
        when BigDecimal
          return num unless num.sign == SIGN_NEGATIVE_ZERO
          return DECIMAL_ZERO
        when Integer
          return num.zero? ? DECIMAL_ZERO : BigDecimal(num)
        when String
          return DECIMAL_ZERO if num.empty?
          BigDecimal(num)
        when Float
          BigDecimal(num, FLOAT_DIG)
        when Money
          num.value
        when Rational
          BigDecimal(num, MAX_DECIMAL)
        when nil
          return DECIMAL_ZERO
        else
          raise ArgumentError, "could not parse as decimal #{num.inspect}"
        end
      return DECIMAL_ZERO if value.sign == SIGN_NEGATIVE_ZERO
      value
    end

    def value_to_currency(currency)
      case currency
      when Money::Currency, Money::NullCurrency
        currency
      when String
        if currency.empty?
          default_currency
        elsif currency == 'XXX' || currency == 'xxx'
          Money::NULL_CURRENCY
        else
          Currency.find!(currency)
        end
      when nil
        default_currency
      else
        raise ArgumentError, "could not parse as currency #{currency.inspect}"
      end
    end

    private

    def default_currency
      # Config#default_currency= coerces to a Currency/NullCurrency at set time,
      # so no further conversion is needed here.
      Money::Config.current.currency || raise(Money::Currency::UnknownCurrency, 'missing currency')
    end
  end
end
