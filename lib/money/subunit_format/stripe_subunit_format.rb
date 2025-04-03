# frozen_string_literal: true

class Money
  class SubunitFormat
    class StripeSubunitFormat < Iso4217SubunitFormat
      STRIPE_ZERO_DECIMAL_OVERRIDE = {
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
        'UGX' => 1,
        'VND' => 1,
        'VUV' => 1,
        'XAF' => 1,
        'XOF' => 1,
        'XPF' => 1,
      }.freeze

      def subunit_to_unit(currency)
        STRIPE_ZERO_DECIMAL_OVERRIDE.fetch(currency.iso_code, super(currency))
      end
    end
  end
end
