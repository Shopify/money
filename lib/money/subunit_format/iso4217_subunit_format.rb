# frozen_string_literal: true

class Money
  class SubunitFormat
    class Iso4217SubunitFormat < BaseSubunitFormat
      def subunit_to_unit(currency)
        currency.subunit_to_unit
      end

      def minor_units(currency)
        currency.minor_units
      end
    end
  end
end
