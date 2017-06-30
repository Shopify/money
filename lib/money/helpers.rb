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
          raise ArgumentError, "could not parse #{num.inspect}"
        end
      return DECIMAL_ZERO if value.sign == BigDecimal::SIGN_NEGATIVE_ZERO
      value
    end
  end
end
