# frozen_string_literal: true
class Money
  module Parser
    class Simple
      class << self
        # Parses an input string using BigDecimal, it always expects a dot character as a decimal separator and
        # generally does not accept other characters other than minus-hyphen and digits. It is useful for APIs, interop
        # with other languages and other use cases where you expect well-formatted input and do not need to take user
        # locale into consideration.
        # @param input [String]
        # @param currency [String, Money::Currency]
        # @param strict [Boolean]
        # @return [Money, nil]
        def parse(input, currency, strict: false)
          currency = Money::Helpers.value_to_currency(currency)
          return unless currency

          amount = BigDecimal(input, exception: false)
          if amount
            Money.new(amount, currency)
          elsif strict
            raise ArgumentError, "unable to parse input=\"#{input}\" currency=\"#{currency}\""
          end
        end
      end
    end
  end
end
