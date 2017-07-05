class Money
  class NullCurrency

    attr_reader :iso_code, :iso_numeric, :name, :smallest_denomination,
                :subunit_to_unit, :minor_units, :symbol, :disambiguate_symbol

    def initialize
      @symbol                = '$'
      @disambiguate_symbol   = nil
      @iso_code              = 'XXX' # Valid ISO4217
      @iso_numeric           = '999'
      @name                  = 'No Currency'
      @smallest_denomination = 1
      @subunit_to_unit       = 100
      @minor_units           = 2
      freeze
    end

    def compatible?(other)
      other.is_a?(Currency) || other.is_a?(NullCurrency)
    end

    alias_method :to_s, :iso_code
  end
end
