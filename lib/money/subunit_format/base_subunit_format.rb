# frozen_string_literal: true

class Money
  class SubunitFormat
    class << self
      def subunit_formats
        @subunit_formats ||= {
          iso4217: Iso4217SubunitFormat,
          stripe: StripeSubunitFormat,
          legacy_dollars: LegacySubunitFormat,
        }
      end

      def register(klass, key)
        subunit_formats[key.to_sym] = klass
      end

      def for(format)
        case format || Money.config.default_subunit_format
        when BaseSubunitFormat
          format.new
        else
          klass = subunit_formats[format.to_sym]
          klass ? klass.new : raise(ArgumentError, "Unknown subunit format type: #{format}")
        end
      end
    end

    class BaseSubunitFormat
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
