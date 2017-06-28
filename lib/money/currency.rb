class Money
  class Currency
    class UnknownCurrency < ArgumentError; end

    CURRENCY_DATA_PATH = "#{File.expand_path('../../../config', __FILE__)}/currency_iso.json".freeze

    @@mutex = Mutex.new

    attr_reader :iso_code, :iso_numeric, :name, :smallest_denomination, :subunit_to_unit, :minor_units

    class << self
      def new(currency_iso)
        iso = currency_iso.to_s.downcase
        loaded_currencies[iso] || @@mutex.synchronize { loaded_currencies[iso] = super(iso) }
      end
      alias_method :find!, :new

      def find(currency_iso)
        return nil if currency_iso.blank?
        new(currency_iso)
      rescue UnknownCurrency
        nil
      end

      def loaded_currencies
        @@loaded_currencies ||= {}
      end

      def currencies_json
        @@currencies_json ||= begin
          json = File.read(CURRENCY_DATA_PATH)
          json.force_encoding(::Encoding::UTF_8) if defined?(::Encoding)
          JSON.parse(json)
        end
      end
    end
    currencies_json

    def initialize(currency_iso)
      unless data = self.class.currencies_json[currency_iso]
        raise UnknownCurrency, "Invalid iso4217 currency '#{currency_iso}'"
      end
      @iso_code              = data['iso_code']
      @iso_numeric           = data['iso_numeric']
      @name                  = data['name']
      @smallest_denomination = data['smallest_denomination']
      @subunit_to_unit       = data['subunit_to_unit']
      @minor_units           = subunit_to_unit == 0 ? 0 : Math.log(subunit_to_unit, 10).round.to_i
      freeze
    end

    def ==(other)
      eql?(other)
    end

    def eql?(other)
      self.class == other.class && iso_code == other.iso_code
    end

    def to_s
      iso_code
    end
  end
end
