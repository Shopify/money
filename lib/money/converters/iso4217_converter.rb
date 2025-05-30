# frozen_string_literal: true

class Money
  module Converters
    class Iso4217Converter < Converter
      def subunit_to_unit(currency)
        currency.subunit_to_unit
      end
    end
  end
end
Money::Converters.register(:iso4217, Money::Converters::Iso4217Converter)
