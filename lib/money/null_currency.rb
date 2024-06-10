# frozen_string_literal: true
class Money
  # A placeholder currency for instances where no actual currency is available,
  # as defined by ISO4217. You should rarely, if ever, need to use this
  # directly. It's here mostly for backwards compatibility and for that reason
  # behaves like a dollar, which is how this gem worked before the introduction
  # of currency.
  #
  # Here follows a list of preferred alternatives over using Money with
  # NullCurrency:
  #
  # For comparisons where you don't know the currency beforehand, you can use
  # Numeric predicate methods like #positive?/#negative?/#zero?/#nonzero?.
  # Comparison operators with Numeric (==, !=, <=, =>, <, >) work as well.
  #
  # @example
  #   Money.new(1, 'CAD').positive? #=> true
  #   Money.new(2, 'CAD') >= 0      #=> true
  #
  # Money with NullCurrency has behaviour that may surprise you, such as
  # database validations or GraphQL enum not allowing the string representation
  # of NullCurrency. Prefer using Money.new(0, currency) where possible, as
  # this sidesteps these issues and provides additional currency check
  # safeties.
  #
  # Unlike other currencies, it is allowed to calculate a Money object with
  # NullCurrency with another currency. The resulting Money object will have
  # the other currency.
  #
  # @example
  #   Money.new(0, Money::NULL_CURRENCY) + Money.new(5, 'CAD')
  #   #=> #<Money value:5.00 currency:CAD>
  #
  class NullCurrency

    attr_reader :iso_code, :iso_numeric, :name, :smallest_denomination, :subunit_symbol,
                :subunit_to_unit, :minor_units, :symbol, :disambiguate_symbol, :decimal_mark

    def initialize
      @symbol                = '$'
      @disambiguate_symbol   = nil
      @subunit_symbol        = nil
      @iso_code              = 'XXX'
      @iso_numeric           = '999'
      @name                  = 'No Currency'
      @smallest_denomination = 1
      @subunit_to_unit       = 10000
      @minor_units           = 4
      @decimal_mark          = '.'
      freeze
    end

    def compatible?(other)
      other.is_a?(Currency) || other.is_a?(NullCurrency)
    end

    def eql?(other)
      self.class == other.class && iso_code == other.iso_code
    end

    def to_s
      ''
    end

    alias_method :==, :eql?
  end
end
