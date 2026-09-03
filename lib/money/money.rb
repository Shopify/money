# frozen_string_literal: true

require 'forwardable'
require 'json'

class Money
  include Comparable

  NULL_CURRENCY = NullCurrency.new.freeze

  attr_reader :value, :currency

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

    def new(value = 0, currency = nil, decimal_precision: nil)
      return new_from_money(value, currency, decimal_precision) if value.is_a?(Money)

      value = Helpers.value_to_decimal(value)
      currency = Helpers.value_to_currency(currency)
      if value.zero?
        @@zero_money ||= {}
        cache_key = [currency.iso_code, decimal_precision]
        @@zero_money[cache_key] ||= super(Helpers::DECIMAL_ZERO, currency, decimal_precision)
      else
        super(value, currency, decimal_precision)
      end
    end
    alias_method :from_amount, :new

    def from_subunits(subunits, currency_iso, format: nil)
      Converters.for(format).from_subunits(subunits, currency_iso)
    end

    def from_json(string)
      hash = JSON.parse(string, symbolize_names: true)
      Money.new(hash.fetch(:value), hash.fetch(:currency), decimal_precision: hash[:decimal_precision])
    end

    def from_hash(hash)
      hash = hash.transform_keys(&:to_sym)
      Money.new(hash.fetch(:value), hash.fetch(:currency), decimal_precision: hash[:decimal_precision])
    end

    def rational(money1, money2)
      money1.send(:arithmetic, money2) do
        factor = money1.currency.subunit_to_unit * money2.currency.subunit_to_unit
        Rational((money1.value * factor).to_i, (money2.value * factor).to_i)
      end
    end

    private

    def new_from_money(amount, currency, decimal_precision)
      currency = Helpers.value_to_currency(currency)

      if amount.no_currency?
        precision = decimal_precision
        precision ||= amount.decimal_precision if amount.explicit_decimal_precision?
        return Money.new(amount.value, currency, decimal_precision: precision)
      end

      if amount.currency.compatible?(currency)
        return amount if decimal_precision.nil?
        return amount if amount.explicit_decimal_precision? && decimal_precision == amount.decimal_precision

        currency = amount.currency if currency.is_a?(NullCurrency)
        return Money.new(amount.value, currency, decimal_precision: decimal_precision)
      end

      msg = "Money.new(Money.new(amount, #{amount.currency}), #{currency}) " \
        "is changing the currency of an existing money object"

      raise Money::IncompatibleCurrencyError, msg
    end
  end

  def initialize(value, currency, decimal_precision)
    raise ArgumentError if value.nan?
    raise ArgumentError if value.infinite?
    unless decimal_precision.nil? || (decimal_precision.is_a?(Integer) && decimal_precision >= 0)
      raise ArgumentError, "decimal_precision must be a non-negative Integer"
    end

    @currency = currency
    @decimal_precision = decimal_precision
    @value = BigDecimal(value.round(self.decimal_precision))
    freeze
  end

  def init_with(coder)
    initialize(
      Helpers.value_to_decimal(coder['value']),
      Helpers.value_to_currency(coder['currency']),
      coder['decimal_precision'],
    )
  end

  def encode_with(coder)
    coder['value'] = @value.to_s('F')
    coder['currency'] = @currency.iso_code
    coder['decimal_precision'] = decimal_precision if explicit_decimal_precision?
  end

  def subunits(format: nil)
    Converters.for(format).to_subunits(self)
  end

  def no_currency?
    currency.is_a?(NullCurrency)
  end

  def decimal_precision
    @decimal_precision || currency.minor_units
  end

  def explicit_decimal_precision?
    !@decimal_precision.nil?
  end

  def -@
    Money.new(-value, currency, decimal_precision: precision_argument)
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
      result_decimal_precision = calculated_decimal_precision(money)
      return self if money.value.zero? && !no_currency?
      Money.new(value + money.value, calculated_currency(money.currency), decimal_precision: result_decimal_precision)
    end
  end

  def -(other)
    arithmetic(other) do |money|
      result_decimal_precision = calculated_decimal_precision(money)
      return self if money.value.zero? && !no_currency?
      Money.new(value - money.value, calculated_currency(money.currency), decimal_precision: result_decimal_precision)
    end
  end

  def *(other)
    raise ArgumentError, "Money objects can only be multiplied by a Numeric" unless other.is_a?(Numeric)

    return self if other == 1
    Money.new(value.to_r * other, currency, decimal_precision: precision_argument)
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

  def zero? = @value.zero?
  def nonzero? = @value.nonzero?
  def positive? = @value.positive?
  def negative? = @value.negative?
  def to_i = @value.to_i
  def to_f = @value.to_f
  def hash = @value.hash

  def coerce(other)
    raise TypeError, "Money can't be coerced into #{other.class}" unless other.is_a?(Numeric)
    [ReverseOperationProxy.new(other), self]
  end

  def convert_currency(exchange_rate, new_currency)
    Money.new(value * exchange_rate, new_currency, decimal_precision: precision_argument)
  end

  def to_money(new_currency = nil)
    if new_currency.nil?
      return self
    end

    if no_currency?
      return Money.new(value, new_currency, decimal_precision: precision_argument)
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
      decimal_precision
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
      hash = { value: to_s(:amount), currency: currency.to_s }
      hash[:decimal_precision] = decimal_precision if explicit_decimal_precision?
      hash
    end
  end
  alias_method :to_h, :as_json

  def abs
    abs = value.abs
    return self if value == abs
    Money.new(abs, currency, decimal_precision: precision_argument)
  end

  def floor
    floor = value.floor
    return self if floor == value
    Money.new(floor, currency, decimal_precision: precision_argument)
  end

  def round(ndigits = 0)
    round = value.round(ndigits)
    return self if round == value
    Money.new(round, currency, decimal_precision: precision_argument)
  end

  def fraction(rate)
    raise ArgumentError, "rate should be positive" if rate < 0

    result = value / (1 + rate)
    Money.new(result, currency, decimal_precision: precision_argument)
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
      Money.new(clamped_value, currency, decimal_precision: precision_argument)
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
      yield(Money.new(other, currency, decimal_precision: precision_argument))

    else
      raise TypeError, "#{other.class.name} can't be coerced into a Money object"
    end
  end

  def ensure_compatible_currency(other_currency, msg)
    return if currency.compatible?(other_currency)

    raise Money::IncompatibleCurrencyError, msg
  end

  def calculated_decimal_precision(other)
    return other.decimal_precision if no_currency? && !explicit_decimal_precision? && other.explicit_decimal_precision?
    return if no_currency? && !explicit_decimal_precision?
    return precision_argument if other.no_currency? && !other.explicit_decimal_precision?
    if decimal_precision == other.decimal_precision
      return precision_argument || other.decimal_precision if other.explicit_decimal_precision?
      return precision_argument
    end

    raise Money::IncompatiblePrecisionError,
      "mathematical operation not permitted for Money objects with different decimal precisions " \
        "#{decimal_precision} and #{other.decimal_precision}."
  end

  def precision_argument
    decimal_precision if explicit_decimal_precision?
  end

  def calculated_currency(other)
    no_currency? ? other : currency
  end
end
