require 'bigdecimal'

class Money
  module Helpers
    extend self

    NUMERIC_REGEX = /\A-?\d*\.?\d*\z/.freeze
    DECIMAL_ZERO = BigDecimal.new(0).freeze

    def value_to_decimal(num)
      value =
        case num
        when Money
          num.value
        when BigDecimal
          num
        when nil
          DECIMAL_ZERO
        when Integer
          BigDecimal.new(num)
        when Float, Rational
          BigDecimal.new(num, Float::DIG)
        when String
          if num !~ NUMERIC_REGEX
            Money.deprecate("using Money.new('#{num}') is deprecated and will raise an ArgumentError in the next major release")
          end
          BigDecimal.new(num)
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
      else
        if no_currency?(currency)
          Money.default_currency
        else
          begin
            Currency.find!(currency)
          rescue Money::Currency::UnknownCurrency => error
            Money.deprecate(error.message)
            Money::NullCurrency.new
          end
        end
      end
    end

    def no_currency?(currency)
      currency.nil? || currency.to_s.empty? || currency.to_s.downcase == 'xxx'
    end
  end
end
