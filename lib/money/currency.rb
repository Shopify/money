# frozen_string_literal: true

require "money/currency/loader"

class Money
  class Currency
    @@mutex = Mutex.new
    @@loaded_currencies = {}
    @@experimental_currencies = {}

    class UnknownCurrency < ArgumentError; end

    class << self
      def new(currency_iso, experimental: false)
        raise UnknownCurrency, "Currency can't be blank" if currency_iso.nil? || currency_iso.to_s.empty?
        iso = currency_iso.to_s.downcase
        cache = experimental ? @@experimental_currencies : @@loaded_currencies
        cache[iso] || @@mutex.synchronize do
          cache[iso] = super(iso, experimental: experimental)
        end
      end
      alias_method :find!, :new

      def find(currency_iso, experimental: false)
        new(currency_iso, experimental: experimental)
      rescue UnknownCurrency
        nil
      end

      def currencies(experimental: false)
        @@currencies ||= {}
        @@currencies[experimental] ||= Loader.load_currencies(experimental: experimental)
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

    def initialize(currency_iso, experimental: false)
      data = self.class.currencies(experimental: experimental)[currency_iso]
      raise UnknownCurrency, "Invalid currency '#{currency_iso}'" unless data
      @symbol                = data['symbol']
      @disambiguate_symbol   = data['disambiguate_symbol'] || data['symbol']
      @subunit_symbol        = data['subunit_symbol']
      @iso_code              = data['iso_code']
      @iso_numeric           = data['iso_numeric']
      @name                  = data['name']
      @smallest_denomination = data['smallest_denomination']
      @subunit_to_unit       = data['subunit_to_unit']
      @decimal_mark          = data['decimal_mark']
      @minor_units           = subunit_to_unit == 0 ? 0 : Math.log(subunit_to_unit, 10).round.to_i
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
