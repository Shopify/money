require 'bigdecimal'
require 'bigdecimal/util'

class Money
  include Comparable

  attr_reader :value, :cents

  def initialize(value = 0)
    raise ArgumentError if value.respond_to?(:nan?) && value.nan?

    @value = value_to_decimal(value).round(2)
    @value = 0.to_d if @value.sign == BigDecimal::SIGN_NEGATIVE_ZERO
    @cents = (@value * 100).to_i
  end

  def -@
    Money.new(-value)
  end

  def <=>(other)
    cents <=> other.to_money.cents
  end

  def +(other)
    Money.new(value + other.to_money.value)
  end

  def -(other)
    Money.new(value - other.to_money.value)
  end

  def *(numeric)
    Money.new(value * numeric)
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

  def self.empty
    Money.new
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
    allocations = splits.inject(0) { |sum, n| sum + value_to_decimal(n) }

    if (allocations - BigDecimal("1")) > Float::EPSILON
      raise ArgumentError, "splits add to more than 100%"
    end

    amounts, left_over = amounts_from_splits(allocations, splits)

    left_over.to_i.times { |i| amounts[i % amounts.length] += 1 }

    amounts.collect { |cents| Money.from_cents(cents) }
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

  def value_to_decimal(num)
    if num.respond_to?(:to_d)
      num.is_a?(Rational) ? num.to_d(16) : num.to_d
    else
      BigDecimal.new(num.to_s)
    end
  end

  def amounts_from_splits(allocations, splits)
    left_over = cents

    amounts = splits.collect do |ratio|
      (cents * ratio / allocations).floor.tap do |frac|
        left_over -= frac
      end
    end

    [amounts, left_over]
  end
end
