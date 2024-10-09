# frozen_string_literal: true

require "money/currency/loader"

class Money
  class Currency
    class UnknownCurrency < ArgumentError; end

    @mutex = Mutex.new

    class << self
      alias_method :original_new, :new

      def find!(currency_iso)
        find(currency_iso).tap do |currency|
          unless currency
            raise UnknownCurrency, "Unknown currency '#{currency_iso}'"
          end
        end
      end
      alias_method :new, :find!

      def find(currency_iso)
        return if currency_iso.nil? || currency_iso.to_s.empty?

        iso_code = currency_iso.to_s.downcase

        fetch_cached_currency(iso_code) do
          data = currencies[iso_code]
          original_new(data) if data
        end
      end

      def find_by_alternate_symbols(symbol)
        fetch_cached_currency_by_symbol(symbol) do
          data = currencies.values.find do |data|
            [
              data['disambiguate_symbol'],
              data['alternate_symbols'],
            ].flatten.compact.map(&:downcase).include?(symbol)
          end
          original_new(data) if data
        end
      end

      private

      def fetch_cached_currency(iso_code, &block)
        @cached_currency ||= {}
        @cached_currency[iso_code] || @mutex.synchronize do
          @cached_currency[iso_code] = yield
        end
      end

      def fetch_cached_currency_by_symbol(symbol, &block)
        @cached_currency_by_symbol ||= {}
        @cached_currency_by_symbol[symbol] || @mutex.synchronize do
          @cached_currency_by_symbol[symbol] = yield
        end
      end

      def currencies
        @currencies ||= Loader.load_currencies
      end
    end

    attr_reader :iso_code,
      :iso_numeric,
      :name,
      :smallest_denomination,
      :subunit_symbol,
      :subunit_to_unit,
      :minor_units,
      :symbol,
      :disambiguate_symbol,
      :decimal_mark

    def initialize(data)
      @symbol                = data['symbol']
      @disambiguate_symbol   = data['disambiguate_symbol'] || data['symbol']
      @subunit_symbol        = data['subunit_symbol']
      @iso_code              = data['iso_code']
      @iso_numeric           = data['iso_numeric']
      @name                  = data['name']
      @smallest_denomination = data['smallest_denomination']
      @subunit_to_unit       = data['subunit_to_unit']
      @decimal_mark          = data['decimal_mark']
      @minor_units           = subunit_to_unit.zero? ? 0 : Math.log(subunit_to_unit, 10).round.to_i
      freeze
    end

    def eql?(other)
      self.class == other.class && iso_code == other.iso_code
    end

    def hash
      [self.class, iso_code].hash
    end

    def compatible?(other)
      other.is_a?(NullCurrency) || eql?(other)
    end

    alias_method :==, :eql?
    alias_method :to_s, :iso_code
  end
end
