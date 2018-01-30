require "money/currency/loader"

class Money
  class Currency
    @@mutex = Mutex.new
    @@loaded_currencies = {}

    class UnknownCurrency < ArgumentError; end

    class << self
      def new(currency_iso)
        raise UnknownCurrency, "Currency can't be blank" if currency_iso.nil? || currency_iso.to_s.empty?
        iso = currency_iso.to_s.downcase
        @@loaded_currencies[iso] || @@mutex.synchronize { @@loaded_currencies[iso] = super(iso) }
      end
      alias_method :find!, :new

      def find(currency_iso)
        new(currency_iso)
      rescue UnknownCurrency
        nil
      end

      def currencies
        @@currencies ||= Loader.load_currencies
      end
    end

    attr_reader(
      :iso_code,
      :iso_numeric,
      :name,
      :smallest_denomination,
      :subunit_symbol,
      :subunit_to_unit,
      :minor_units,
      :symbol,
      :disambiguate_symbol,
      :decimal_mark,
      :thousands_separator
    )

    def initialize(currency_iso)
      data = self.class.currencies[currency_iso]
      raise UnknownCurrency, "Invalid iso4217 currency '#{currency_iso}'" unless data
      @symbol                = data['symbol']
      @disambiguate_symbol   = data['disambiguate_symbol'] || data['symbol']
      @subunit_symbol        = data['subunit_symbol']
      @iso_code              = data['iso_code']
      @iso_numeric           = data['iso_numeric']
      @name                  = data['name']
      @smallest_denomination = data['smallest_denomination']
      @subunit_to_unit       = data['subunit_to_unit']
      @decimal_mark          = data['decimal_mark']
      @thousands_separator   = data['thousands_separator']
      @minor_units           = subunit_to_unit == 0 ? 0 : Math.log(subunit_to_unit, 10).round.to_i
      freeze
    end

    def eql?(other)
      self.class == other.class && iso_code == other.iso_code
    end

    def compatible?(other)
      other.is_a?(NullCurrency) || eql?(other)
    end

    alias_method :==, :eql?
    alias_method :to_s, :iso_code
  end
end
