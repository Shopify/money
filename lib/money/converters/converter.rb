# frozen_string_literal: true

class Money
  module Converters
    class Converter
      def to_subunits(money)
        raise ArgumentError, "money cannot be nil" if money.nil?
        (money.value * subunit_to_unit(money.currency)).to_i
      end

      def from_subunits(subunits, currency)
        currency = Helpers.value_to_currency(currency)
        value = Helpers.value_to_decimal(subunits) / subunit_to_unit(currency)
        Money.new(value, currency)
      end

      protected

      def subunit_to_unit(currency)
        raise NotImplementedError, "subunit_to_unit method must be implemented in subclasses"
      end
    end
  end
end
