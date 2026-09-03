# frozen_string_literal: true

class Money
  module AllocationUnits
    extend self

    def to_units(money)
      return money.subunits unless money.explicit_decimal_precision?

      (money.value * scale(money.decimal_precision)).to_i
    end

    def from_units(units, currency, decimal_precision: nil)
      return Money.from_subunits(units, currency) if decimal_precision.nil?

      value = Helpers.value_to_decimal(units) / scale(decimal_precision)
      Money.new(value, currency, decimal_precision: decimal_precision)
    end

    private

    def scale(decimal_precision)
      10**decimal_precision
    end
  end

  private_constant :AllocationUnits
end
