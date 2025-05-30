# frozen_string_literal: true

class Money
  module Converters
    class LegacyDollarsConverter < Converter
      def subunit_to_unit(currency)
        100
      end
    end
  end
end
Money::Converters.register(:legacy_dollar, Money::Converters::LegacyDollarsConverter)
