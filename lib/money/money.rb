require 'bigdecimal'
require 'bigdecimal/util'

class Money
  include Comparable

  DECIMAL_ZERO = BigDecimal.new(0).freeze

  attr_reader :value, :cents

  class << self
    def new(value = 0, _currency = nil)
      if value == 0
        @empty ||= super(0)
      else
        super(value, _currency)
      end
    end

    def empty
      new(0)
    end

    alias_method :from_amount, :new
  end

  def initialize(value = 0, _currency = nil)
    raise ArgumentError if value.respond_to?(:nan?) && value.nan?

    @value = value_to_decimal(value).round(2)
    @value = 0.to_d if @value.sign == BigDecimal::SIGN_NEGATIVE_ZERO
    @cents = (@value * 100).to_i
    freeze
  end

  def init_with(coder)
    initialize(coder.map['value'.freeze])
  end

  def -@
    Money.new(-value)
  end

  def <=>(other)
    raise TypeError, "#{other.class.name} can't be coerced into Money" unless other.respond_to?(:to_money)
    cents <=> other.to_money.cents
  end

  def +(other)
    raise TypeError, "#{other.class.name} can't be coerced into Money" unless other.respond_to?(:to_money)
    Money.new(value + other.to_money.value)
  end

  def -(other)
    raise TypeError, "#{other.class.name} can't be coerced into Money" unless other.respond_to?(:to_money)
    Money.new(value - other.to_money.value)
  end

  def *(numeric)
    Money.new(value.to_r * numeric)
  end

  def /(numeric)
    raise "[Money] Dividing money objects can lose pennies. Use #split instead"
  end

  def inspect
    "#<#{self.class} value:#{self.to_s}>"
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    self.class == other.class && value == other.value
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

  def hash
    value.hash
  end

  def self.parse(input)
    parser.parse(input)
  end

  # allow parser to be set via dependency injection.
  def self.parser
    @@parser ||= MoneyParser
  end

  def self.parser=(new_parser_class)
    @@parser = new_parser_class
  end

  def self.from_cents(cents)
    Money.new(cents.round.to_f / 100)
  end

  def to_money
    self
  end

  def zero?
    value.zero?
  end

  # dangerous, this *will* shave off all your cents
  def to_i
    value.to_i
  end

  def to_f
    value.to_f
  end

  def to_d
    value
  end

  def to_s
    sprintf("%.2f", value.to_f)
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
    Money.new(value.abs)
  end

  def floor
    Money.new(value.floor)
  end

  def round(ndigits=0)
    Money.new(value.round(ndigits))
  end

  def fraction(rate)
    raise ArgumentError, "rate should be positive" if rate < 0

    result = value / (1 + rate)
    Money.new(result)
  end

  # Allocates money between different parties without losing pennies.
  # After the mathmatically split has been performed, left over pennies will
  # be distributed round-robin amongst the parties. This means that parties
  # listed first will likely recieve more pennies than ones that are listed later
  #
  # @param [0.50, 0.25, 0.25] to give 50% of the cash to party1, 25% ot party2, and 25% to party3.
  #
  # @return [Array<Money, Money, Money>]
  #
  # @example
  #   Money.new(5, "USD").allocate([0.3,0.7)) #=> [Money.new(2), Money.new(3)]
  #   Money.new(100, "USD").allocate([0.33,0.33,0.33]) #=> [Money.new(34), Money.new(33), Money.new(33)]
  def allocate(splits)
    if all_rational?(splits)
      allocations = splits.inject(0) { |sum, n| sum + n }
    else
      allocations = splits.inject(0) { |sum, n| sum + value_to_decimal(n) }
    end

    if (allocations - BigDecimal("1")) > Float::EPSILON
      raise ArgumentError, "splits add to more than 100%"
    end

    amounts, left_over = amounts_from_splits(allocations, splits)

    left_over.to_i.times { |i| amounts[i % amounts.length] += 1 }

    amounts.collect { |cents| Money.from_cents(cents) }
  end

  # Allocates money between different parties up to the maximum amounts specified.
  # Left over pennies will be assigned round-robin up to the maximum specified.
  # Pennies are dropped when the maximums are attained.
  #
  # @example
  #   Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)])
  #     #=> [Money.new(26), Money.new(4.75)]
  #
  #   Money.new(30.75).allocate_max_amounts([Money.new(26), Money.new(4.74)]
  #     #=> [Money.new(26), Money.new(4.74)]
  #
  #   Money.new(30).allocate_max_amounts([Money.new(15), Money.new(15)]
  #     #=> [Money.new(15), Money.new(15)]
  #
  #   Money.new(1).allocate_max_amounts([Money.new(33), Money.new(33), Money.new(33)])
  #     #=> [Money.new(0.34), Money.new(0.33), Money.new(0.33)]
  #
  #   Money.new(100).allocate_max_amounts([Money.new(5), Money.new(2)])
  #     #=> [Money.new(5), Money.new(2)]
  def allocate_max_amounts(maximums)
    cents_maximums = maximums.map { |max_amount| max_amount.to_money.cents }
    cents_maximums_total = cents_maximums.sum

    splits = cents_maximums.map do |cents_max_amount|
      next(Money.empty) if cents_maximums_total.zero?
      BigDecimal.new(cents_max_amount.to_s) / cents_maximums_total
    end

    total_allocatable = [cents, cents_maximums_total].min

    cents_amounts, left_over = amounts_from_splits(1, splits, total_allocatable)

    cents_amounts.each_with_index do |amount, index|
      break unless left_over > 0

      max_amount = cents_maximums[index]
      next unless amount < max_amount

      left_over -= 1
      cents_amounts[index] += 1
    end

    cents_amounts.map { |cents| Money.from_cents(cents) }
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
    raise ArgumentError, "need at least one party" if num < 1
    low = Money.from_cents(cents / num)
    high = Money.from_cents(low.cents + 1)

    remainder = cents % num
    result = []

    num.times do |index|
      result[index] = index < remainder ? high : low
    end

    return result
  end

  private

  def all_rational?(splits)
    splits.all? { |split| split.is_a?(Rational) }
  end

  def value_to_decimal(num)
    case num
    when BigDecimal
      num
    when nil
      ActiveSupport::Deprecation.warn('Money.new(nil) is deprecated in favor of Money.new(0). Support for passing a nil amount will be removed from the next major revision.') if defined?(ActiveSupport)
      DECIMAL_ZERO
    when Money
      num.value
    when Rational
      num.to_d(16)
    else
      if num.respond_to?(:to_d)
        num.to_d
      else
        raise ArgumentError, "value_to_decimal could not parse #{num.inspect}"
      end
    end
  end

  def amounts_from_splits(allocations, splits, cents_to_split = cents)
    left_over = cents_to_split

    amounts = splits.collect do |ratio|
      frac = (value_to_decimal(cents_to_split * ratio) / allocations).floor
      left_over -= frac
      frac
    end

    [amounts, left_over]
  end
end
