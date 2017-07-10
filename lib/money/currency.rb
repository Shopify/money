class Money
  class Currency
    class UnknownCurrency < ArgumentError; end

    CURRENCY_DATA = "#{File.expand_path('../../../config', __FILE__)}/currency_iso.json".freeze

    @@mutex = Mutex.new
    @@loaded_currencies = {}

    attr_reader :iso_code, :iso_numeric, :name, :smallest_denomination,
                :subunit_to_unit, :minor_units, :symbol, :disambiguate_symbol

    class << self
      def new(currency_iso)
        raise UnknownCurrency, "Currency can't be blank" if currency_iso.nil? || currency_iso.empty?
        iso = currency_iso.to_s.downcase
        @@loaded_currencies[iso] || @@mutex.synchronize do
          @@loaded_currencies[iso] =
            if iso == 'xxx'
              NullCurrency.new
            else
              super(iso)
            end
        end
      end
      alias_method :find!, :new

      def find(currency_iso)
        new(currency_iso)
      rescue UnknownCurrency
        nil
      end

      def currencies_data
        @@currencies_data ||= begin
          json = File.read(CURRENCY_DATA)
          json.force_encoding(::Encoding::UTF_8) if defined?(::Encoding)
          JSON.parse(json)
        end
      end
    end

    def initialize(currency_iso)
      data = self.class.currencies_data[currency_iso]
      raise UnknownCurrency, "Invalid iso4217 currency '#{currency_iso}'" unless data
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
