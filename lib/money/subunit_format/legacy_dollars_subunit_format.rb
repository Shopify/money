# frozen_string_literal: true

class Money
  class SubunitFormat
    class LegacyDollarsSubunitFormat < BaseSubunitFormat
      def subunit_to_unit(currency)
        100
      end
    end
  end
end
