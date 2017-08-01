require "money/currency/loader"

class Money
  class Currency
    @@mutex = Mutex.new
    @@loaded_currencies = {}
    @@currency_normalization_map = nil

    class UnknownCurrency < ArgumentError; end

    class << self
      def new(currency_iso)
        raise UnknownCurrency, "Currency can't be blank" if currency_iso.nil? || currency_iso.empty?
        iso = normalize_currency(currency_iso)
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

      def normalize_currency(currency_code)
        code = currency_code.to_s.downcase
        return code if currencies.keys.include?(code)

        code = currency_normalization_map[code.upcase]
        return code.downcase if code

        raise(UnknownCurrency, "Currency #{code} is not a known currency, nor can it be converted to one.")
      end

      def currency_normalization_map
        @@currency_normalization_map ||= Loader.load_currency_normalization_map
      end
    end

    attr_reader :iso_code, :iso_numeric, :name, :smallest_denomination,
                :subunit_to_unit, :minor_units, :symbol, :disambiguate_symbol

    def initialize(currency_iso)
      data = self.class.currencies[currency_iso]
      raise UnknownCurrency, "Invalid currency '#{currency_iso}'" unless data
      @symbol                = data['symbol']
      @disambiguate_symbol   = data['disambiguate_symbol'] || data['symbol']
      @iso_code              = data['iso_code']
      @iso_numeric           = data['iso_numeric']
      @name                  = data['name']
      @smallest_denomination = data['smallest_denomination']
      @subunit_to_unit       = data['subunit_to_unit']
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
