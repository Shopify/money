# frozen_string_literal: true

class Money
  module Converters
    class StripeConverter < Iso4217Converter
      SUBUNIT_TO_UNIT = {
        # https://docs.stripe.com/currencies#special-cases
        'ISK' => 100,
        'UGX' => 100,
        'HUF' => 100,
        'TWD' => 100,
        # https://docs.stripe.com/currencies#zero-decimal
        'BIF' => 1,
        'CLP' => 1,
        'DJF' => 1,
        'GNF' => 1,
        'JPY' => 1,
        'KMF' => 1,
        'KRW' => 1,
        'MGA' => 1,
        'PYG' => 1,
        'RWF' => 1,
        'VND' => 1,
        'VUV' => 1,
        'XAF' => 1,
        'XOF' => 1,
        'XPF' => 1,
        'USDC' => 1_000_000,
      }.freeze

      def subunit_to_unit(currency)
        SUBUNIT_TO_UNIT.fetch(currency.iso_code, super)
      end
    end
  end
end
Money::Converters.register(:stripe, Money::Converters::StripeConverter)
