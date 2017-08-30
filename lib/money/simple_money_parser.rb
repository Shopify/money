# Parses amount with optionally a space and currency code. Raises an error if
# it is unable to parse the amount. Intended for use in APIs where you can expect
# well formed input and do not want to fall back to 0 money if parsing fails
# (which is what BigDecimal does with an empty string).

class SimpleMoneyParser
  ParseError = Class.new(StandardError)

  REGEX = /^(-?\d*\.?\d*)(?: ([A-Z]{3}))?/

  class << self
    def parse(input)
      input = input.to_s
      amount, currency = input.scan(REGEX).first

      if amount.empty?
        raise ParseError, "empty amount: #{input[0,32]}"
      else
        Money.new(amount, currency)
      end
    end
  end
end
