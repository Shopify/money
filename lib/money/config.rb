# frozen_string_literal: true

class Money
  class Config
    CONFIG_THREAD = :shopify_money__configs

    class << self
      def current
        thread_local_config[Fiber.current.object_id] ||= Money.config.dup
      end

      def current=(config)
        thread_local_config[Fiber.current.object_id] = config
      end

      def reset_current
        thread_local_config.delete(Fiber.current.object_id)
        Thread.current[CONFIG_THREAD] = nil if thread_local_config.empty?
      end

      private

      def thread_local_config
        Thread.current[CONFIG_THREAD] ||= {}
      end
    end

    attr_accessor :legacy_json_format, :legacy_deprecations, :experimental_crypto_currencies

    attr_reader :default_currency
    alias_method :currency, :default_currency

    def default_currency=(value)
      @default_currency =
        case value
        when String
          Currency.find!(value)
        else
          value
        end
    end
    alias_method :currency=, :default_currency=

    def legacy_default_currency!
      @default_currency ||= Money::NULL_CURRENCY
    end

    def legacy_deprecations!
      @legacy_deprecations = true
    end

    def legacy_json_format!
      @legacy_json_format = true
    end

    def experimental_crypto_currencies!
      @experimental_crypto_currencies = true
    end

    def initialize
      @default_currency = nil
      @legacy_json_format = false
      @legacy_deprecations = false
      @experimental_crypto_currencies = false
    end

    def without_legacy_deprecations(&block)
      old_legacy_deprecations = @legacy_deprecations
      @legacy_deprecations = false
      yield
    ensure
      @legacy_deprecations = old_legacy_deprecations
    end

    def with_currency(new_currency)
      old_currency = @default_currency
      @default_currency = new_currency
      yield
    ensure
      @default_currency = old_currency
    end
  end
end
