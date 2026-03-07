# frozen_string_literal: true

require 'forwardable'
require 'json'

class Money
  include Comparable
  extend Forwardable

  NULL_CURRENCY = NullCurrency.new.freeze

  attr_reader :value, :currency

  def_delegators :@value, :zero?, :nonzero?, :positive?, :negative?, :to_i, :to_f, :hash

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

  class << self
    extend Forwardable
    def_delegators :'Money::Config.global', :default_currency, :default_currency=

    def with_config(**configs, &block)
      Money::Config.configure_current(**configs, &block)
    end

    def config
      Money::Config.global
    end

    def configure(&block)
      Money::Config.global.tap(&block)
    end

    def current_currency
      Money::Config.current.currency
    end

    def current_currency=(value)
      Money::Config.current.currency = value
    end

    def with_currency(currency, &block)
      if currency.nil?
        currency = current_currency
      end
      with_config(currency: currency, &block)
    end

    def new(value = 0, currency = nil)
      return new_from_money(value, currency) if value.is_a?(Money)

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

    def from_subunits(subunits, currency_iso, format: nil)
      Converters.for(format).from_subunits(subunits, currency_iso)
    end

    def from_json(string)
      hash = JSON.parse(string, symbolize_names: true)
      Money.new(hash.fetch(:value), hash.fetch(:currency))
    end

    def from_hash(hash)
      hash = hash.transform_keys(&:to_sym)
      Money.new(hash.fetch(:value), hash.fetch(:currency))
    end

    def rational(money1, money2)
      money1.send(:arithmetic, money2) do
        factor = money1.currency.subunit_to_unit * money2.currency.subunit_to_unit
        Rational((money1.value * factor).to_i, (money2.value * factor).to_i)
      end
    end

    private

    def new_from_money(amount, currency)
      currency = Helpers.value_to_currency(currency)

      if amount.no_currency?
        return Money.new(amount.value, currency)
      end

      if amount.currency.compatible?(currency)
        return amount
      end

      msg = "Money.new(Money.new(amount, #{amount.currency}), #{currency}) " \
        "is changing the currency of an existing money object"

      raise Money::IncompatibleCurrencyError, msg
    end
  end

  def initialize(value, currency)
    raise ArgumentError if value.nan?
    raise ArgumentError if value.infinite?

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

  def subunits(format: nil)
    Converters.for(format).to_subunits(self)
  end

  def no_currency?
    currency.is_a?(NullCurrency)
  end

  def -@
    Money.new(-value, currency)
  end

  def <=>(other)
    if other.is_a?(Numeric)
      return value <=> other
    end

    if other.respond_to?(:to_money)
      arithmetic(other) do |money|
        value <=> money.value
      end
    end
  end

  def +(other)
    arithmetic(other) do |money|
      return self if money.value.zero? && !no_currency?
      Money.new(value + money.value, calculated_currency(money.currency))
    end
  end

  def -(other)
    arithmetic(other) do |money|
      return self if money.value.zero? && !no_currency?
      Money.new(value - money.value, calculated_currency(money.currency))
    end
  end

  def *(other)
    raise ArgumentError, "Money objects can only be multiplied by a Numeric" unless other.is_a?(Numeric)

    return self if other == 1
    Money.new(value.to_r * other, currency)
  end

  def /(other)
    raise "[Money] Dividing money objects can lose pennies. Use #split instead"
  end

  def inspect
    "#<#{self.class} value:#{self} currency:#{currency}>"
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

  def coerce(other)
    raise TypeError, "Money can't be coerced into #{other.class}" unless other.is_a?(Numeric)
    [ReverseOperationProxy.new(other), self]
  end

  def convert_currency(exchange_rate, new_currency)
    Money.new(value * exchange_rate, new_currency)
  end

  def to_money(new_currency = nil)
    if new_currency.nil?
      return self
    end

    if no_currency?
      return Money.new(value, new_currency)
    end

    ensure_compatible_currency(
      Helpers.value_to_currency(new_currency),
      "to_money is attempting to change currency of an existing money object from #{currency} to #{new_currency}",
    )

    self
  end

  def to_d
    value
  end

  def to_fs(style = nil)
    units = case style
    when :legacy_dollars
      2
    when :amount, nil
      currency.minor_units
    else
      raise ArgumentError, "Unexpected format: #{style}"
    end

    rounded_value = value.round(units)
    if units == 0
      format("%d", rounded_value)
    else
      formatted = rounded_value.to_s("F")
      decimal_digits = formatted.size - formatted.index(".") - 1
      (units - decimal_digits).times do
        formatted << '0'
      end
      formatted
    end
  end
  alias_method :to_s, :to_fs
  alias_method :to_formatted_s, :to_fs

  def to_json(options = nil)
    if (options.is_a?(Hash) && options[:legacy_format]) || Money::Config.current.legacy_json_format
      to_s
    else
      as_json(options).to_json
    end
  end

  def as_json(options = nil)
    if (options.is_a?(Hash) && options[:legacy_format]) || Money::Config.current.legacy_json_format
      to_s
    else
      { value: to_s(:amount), currency: currency.to_s }
    end
  end
  alias_method :to_h, :as_json

  def abs
    abs = value.abs
    return self if value == abs
    Money.new(abs, currency)
  end

  def floor
    floor = value.floor
    return self if floor == value
    Money.new(floor, currency)
  end

  def round(ndigits = 0)
    round = value.round(ndigits)
    return self if round == value
    Money.new(round, currency)
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
  # @return [Enumerable<Money, Money, Money>]
  #
  # @example
  #   Money.new(100, "USD").split(3) #=> Enumerable[Money.new(34), Money.new(33), Money.new(33)]
  def split(num)
    Splitter.new(self, num)
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
    Splitter.new(self, num).split.dup
  end

  # Calculate the unit price based on a total quantity of units.
  # A number of units to take can be optionally provided to get the sum of
  # their unit prices with correct rounding.
  #
  # The higher-valued splits are used first (i.e., units with the "extra penny").
  #
  # @param quantity [Integer] total number of units
  # @param take [Integer] number of unit prices to sum (default: 1)
  #
  # @return [Money]
  #
  # @example Get the unit price for 1 unit out of 3
  #   Money.new(1.00, 'USD').per_unit(3)
  #   # => Money.new(0.34, 'USD')  # the higher-valued split
  #
  # @example Get total for 3 units out of 3 (returns original amount)
  #   Money.new(1.00, 'USD').per_unit(3, take: 3)
  #   # => Money.new(1.00, 'USD')
  def per_unit(quantity, take: 1)
    raise ArgumentError, "take should be positive" if take < 0
    raise ArgumentError, "quantity should be positive" if quantity <= 0
    raise ArgumentError, "take cannot be greater than quantity" if take > quantity

    calculate_splits(quantity).sum(Money.new(0, currency)) do |value, count|
      count = [take, count].min
      take -= count
      value * count
    end
  end

  # Calculate the unit price based on a total quantity of units.
  # Uses the lesser-valued splits first (i.e., units without the "extra penny").
  #
  # A number of units to take can be optionally provided to get the sum of
  # their unit prices with correct rounding.
  #
  # @param quantity [Integer] total number of units
  # @param take [Integer] number of unit prices to sum (default: 1)
  #
  # @return [Money]
  #
  # @example Get the unit price for 1 unit out of 3 (lower value)
  #   Money.new(1.00, 'USD').reverse_per_unit(3)
  #   # => Money.new(0.33, 'USD')  # the lower-valued split
  #
  # @example Get total for 3 units out of 3 (returns original amount)
  #   Money.new(1.00, 'USD').reverse_per_unit(3, take: 3)
  #   # => Money.new(1.00, 'USD')
  def reverse_per_unit(quantity, take: 1)
    raise ArgumentError, "quantity should be positive" if quantity < 0
    raise ArgumentError, "take should be positive" if take <= 0
    raise ArgumentError, "take cannot be greater than quantity" if take > quantity

    calculate_splits(quantity).reverse_each.sum(Money.new(0, currency)) do |value, count|
      count = [take, count].min
      take -= count
      value * count
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

    clamped_value = min if value < min
    clamped_value = max if value > max

    if clamped_value.nil?
      self
    else
      Money.new(clamped_value, currency)
    end
  end

  private

  def arithmetic(other)
    case other
    when Money
      desc = "mathematical operation not permitted for Money objects with different currencies " \
        "#{other.currency} and #{currency}."

      ensure_compatible_currency(other.currency, desc)
      yield(other)

    when Numeric, String
      yield(Money.new(other, currency))

    else
      raise TypeError, "#{other.class.name} can't be coerced into a Money object"
    end
  end

  def ensure_compatible_currency(other_currency, msg)
    return if currency.compatible?(other_currency)

    raise Money::IncompatibleCurrencyError, msg
  end

  def calculated_currency(other)
    no_currency? ? other : currency
  end
end
