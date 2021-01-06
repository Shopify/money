# frozen_string_literal: true
require 'forwardable'

class Money
  include Comparable
  extend Forwardable

  NULL_CURRENCY = NullCurrency.new.freeze

  attr_reader :value, :currency
  def_delegators :@value, :zero?, :nonzero?, :positive?, :negative?, :to_i, :to_f, :hash

  class << self
    attr_accessor :parser, :default_currency

    def new(value = 0, currency = nil)
      value = Helpers.value_to_decimal(value)
      currency = Helpers.value_to_currency(currency)

      if value.zero?
        @@zero_money ||= {}
        @@zero_money[currency.iso_code] ||= super(Helpers::DECIMAL_ZERO, currency)
      else
        super(value, currency)
      end
    end
    alias_method :from_amount, :new

    def parse(*args, **kwargs)
      parser.parse(*args, **kwargs)
    end

    def from_cents(cents, currency = nil)
      new(cents.round.to_f / 100, currency)
    end

    def from_subunits(subunits, currency_iso, format: :iso4217)
      currency = Helpers.value_to_currency(currency_iso)

      subunit_to_unit_value = if format == :iso4217
        currency.subunit_to_unit
      elsif format == :stripe
        Helpers::STRIPE_SUBUNIT_OVERRIDE.fetch(currency.iso_code, currency.subunit_to_unit)
      else
        raise ArgumentError, "unknown format #{format}"
      end

      value = Helpers.value_to_decimal(subunits) / subunit_to_unit_value
      new(value, currency)
    end

    def rational(money1, money2)
      money1.send(:arithmetic, money2) do
        factor = money1.currency.subunit_to_unit * money2.currency.subunit_to_unit
        Rational((money1.value * factor).to_i, (money2.value * factor).to_i)
      end
    end

    def current_currency
      Thread.current[:money_currency]
    end

    def current_currency=(currency)
      Thread.current[:money_currency] = currency
    end

    # Set Money.default_currency inside the supplied block, resets it to
    # the previous value when done to prevent leaking state. Similar to
    # I18n.with_locale and ActiveSupport's Time.use_zone. This won't affect
    # instances being created with explicitly set currency.
    def with_currency(new_currency)
      begin
        old_currency = Money.current_currency
        Money.current_currency = new_currency
        yield
      ensure
        Money.current_currency = old_currency
      end
    end

    def default_settings
      self.parser = MoneyParser
      self.default_currency = Money::NULL_CURRENCY
    end
  end
  default_settings

  def initialize(value, currency)
    raise ArgumentError if value.nan?
    @currency = Helpers.value_to_currency(currency)
    @value = BigDecimal(value.round(@currency.minor_units))
    freeze
  end

  def init_with(coder)
    initialize(Helpers.value_to_decimal(coder['value']), coder['currency'])
  end

  def encode_with(coder)
    coder['value'] = @value.to_s('F')
    coder['currency'] = @currency.iso_code
  end

  def cents
    # Money.deprecate('`money.cents` is deprecated and will be removed in the next major release. Please use `money.subunits` instead. Keep in mind, subunits are currency aware.')
    (value * 100).to_i
  end

  def subunits(format: :iso4217)
    subunit_to_unit_value = if format == :iso4217
      @currency.subunit_to_unit
    elsif format == :stripe
      Helpers::STRIPE_SUBUNIT_OVERRIDE.fetch(@currency.iso_code, @currency.subunit_to_unit)
    else
      raise ArgumentError, "unknown format #{format}"
    end

    (@value * subunit_to_unit_value).to_i
  end

  def no_currency?
    currency.is_a?(NullCurrency)
  end

  def -@
    Money.new(-value, currency)
  end

  def <=>(other)
    return unless other.respond_to?(:to_money)
    arithmetic(other) do |money|
      value <=> money.value
    end
  end

  def +(other)
    arithmetic(other) do |money|
      Money.new(value + money.value, calculated_currency(money.currency))
    end
  end

  def -(other)
    arithmetic(other) do |money|
      Money.new(value - money.value, calculated_currency(money.currency))
    end
  end

  def *(numeric)
    unless numeric.is_a?(Numeric)
      Money.deprecate("Multiplying Money with #{numeric.class.name} is deprecated and will be removed in the next major release.")
    end
    Money.new(value.to_r * numeric, currency)
  end

  def /(numeric)
    raise "[Money] Dividing money objects can lose pennies. Use #split instead"
  end

  def inspect
    "#<#{self.class} value:#{self} currency:#{self.currency}>"
  end

  def ==(other)
    eql?(other)
  end

  # TODO: Remove once cross-currency mathematical operations are no longer allowed
  def eql?(other)
    return false unless other.is_a?(Money)
    return false unless currency.compatible?(other.currency)
    value == other.value
  end

  class ReverseOperationProxy
    include Comparable

    def initialize(value)
      @value = value
    end

    def <=>(other)
      -(other <=> @value)
    end

    def +(other)
      other + @value
    end

    def -(other)
      -(other - @value)
    end

    def *(other)
      other * @value
    end
  end

  def coerce(other)
    raise TypeError, "Money can't be coerced into #{other.class}" unless other.is_a?(Numeric)
    [ReverseOperationProxy.new(other), self]
  end

  def to_money(curr = nil)
    if !curr.nil? && no_currency?
      return Money.new(value, curr)
    end

    curr = Helpers.value_to_currency(curr)
    unless currency.compatible?(curr)
      Money.deprecate("mathematical operation not permitted for Money objects with different currencies #{curr} and #{currency}. " \
        "A Money::IncompatibleCurrencyError will raise in the next major release")
    end

    self
  end

  def to_d
    value
  end

  def to_s(style = nil)
    units = case style
    when :legacy_dollars
      2
    when :amount, nil
      currency.minor_units
    else
      raise ArgumentError, "Unexpected style: #{style}"
    end

    rounded_value = value.round(units)
    if units == 0
      sprintf("%d", rounded_value)
    else
      sign = rounded_value < 0 ? '-' : ''
      rounded_value = rounded_value.abs
      sprintf("%s%d.%0#{units}d", sign, rounded_value.truncate, rounded_value.frac * (10 ** units))
    end
  end

  def to_liquid
    cents
  end

  def to_json(options = {})
    to_s
  end

  def as_json(*args)
    to_s
  end

  def abs
    Money.new(value.abs, currency)
  end

  def floor
    Money.new(value.floor, currency)
  end

  def round(ndigits=0)
    Money.new(value.round(ndigits), currency)
  end

  def fraction(rate)
    raise ArgumentError, "rate should be positive" if rate < 0

    result = value / (1 + rate)
    Money.new(result, currency)
  end

  # @see Money::Allocator#allocate
  def allocate(splits, strategy = :roundrobin)
    Money::Allocator.new(self).allocate(splits, strategy)
  end

  # @see Money::Allocator#allocate_max_amounts
  def allocate_max_amounts(maximums)
    Money::Allocator.new(self).allocate_max_amounts(maximums)
  end

  # Split money amongst parties evenly without losing pennies.
  #
  # @param [2] number of parties.
  #
  # @return [Array<Money, Money, Money>]
  #
  # @example
  #   Money.new(100, "USD").split(3) #=> [Money.new(34), Money.new(33), Money.new(33)]
  def split(num)
    calculate_splits(num).sum([]) { |value, count| Array.new(count, value) }
  end

  # Calculate the splits evenly without losing pennies.
  # Returns the number of high and low splits and the value of the high and low splits.
  # Where high represents the Money value with the extra penny
  # and low a Money without the extra penny.
  #
  # @param [2] number of parties.
  #
  # @return [Hash<Money, Integer>]
  #
  # @example
  #   Money.new(100, "USD").calculate_splits(3) #=> {Money.new(34) => 1, Money.new(33) => 2}
  def calculate_splits(num)
    raise ArgumentError, "need at least one party" if num < 1
    subunits = self.subunits
    low = Money.from_subunits(subunits / num, currency)
    high = Money.from_subunits(low.subunits + 1, currency)

    num_high = subunits % num

    {}.tap do |result|
      result[high] = num_high if num_high > 0
      result[low] = num - num_high
    end
  end

  # Clamps the value to be within the specified minimum and maximum. Returns
  # self if the value is within bounds, otherwise a new Money object with the
  # closest min or max value.
  #
  # @example
  #   Money.new(50, "CAD").clamp(1, 100) #=> Money.new(50, "CAD")
  #
  #   Money.new(120, "CAD").clamp(0, 100) #=> Money.new(100, "CAD")
  def clamp(min, max)
    raise ArgumentError, 'min cannot be greater than max' if min > max

    clamped_value = min if self.value < min
    clamped_value = max if self.value > max

    if clamped_value.nil?
      self
    else
      Money.new(clamped_value, self.currency)
    end
  end

  private

  def arithmetic(money_or_numeric)
    raise TypeError, "#{money_or_numeric.class.name} can't be coerced into Money" unless money_or_numeric.respond_to?(:to_money)
    other = money_or_numeric.to_money(currency)

    yield(other)
  end

  def calculated_currency(other)
    no_currency? ? other : currency
  end
end
