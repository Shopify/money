# frozen_string_literal: true

class Money
  class Config
    CONFIG_THREAD = :shopify_money__configs

    class << self
      def global
        @config ||= new
      end

      def current
        thread_local_config[Fiber.current.object_id] ||= global.dup
      end

      def current=(config)
        thread_local_config[Fiber.current.object_id] = config
      end

      def configure_current(**configs, &block)
        old_config = current.dup
        current.tap do |config|
          configs.each do |k, v|
            config.public_send("#{k}=", v)
          end
        end
        yield
      ensure
        self.current = old_config
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

    attr_accessor :legacy_json_format, :experimental_crypto_currencies, :default_subunit_format

    attr_reader :default_currency
    alias_method :currency, :default_currency

    def default_currency=(value)
      @default_currency =
        case value
        when String
          Currency.find!(value)
        when Money::Currency, Money::NullCurrency, nil
          value
        else
          raise ArgumentError, "Invalid currency"
        end
    end
    alias_method :currency=, :default_currency=

    def legacy_json_format!
      @legacy_json_format = true
    end

    def experimental_crypto_currencies!
      @experimental_crypto_currencies = true
    end

    def initialize
      @default_currency = nil
      @legacy_json_format = false
      @experimental_crypto_currencies = false
      @default_subunit_format = :iso4217
    end
  end
end
