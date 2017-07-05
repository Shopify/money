class Money
  include Comparable

  attr_reader :value, :cents, :currency

  class << self
    attr_accessor :parser, :default_currency

    def new(value = 0, currency = nil)
      currency ||= default_currency

      if value == 0
        @@zero_money ||= {}
        @@zero_money[currency] ||= super(0, currency)
      else
        super(value, currency)
      end
    end
    alias_method :from_amount, :new

    def zero(currency = nil)
      new(0, currency)
    end
    alias_method :empty, :zero

    def parse(input, _currency = nil)
      parser.parse(input)
    end

    def from_cents(cents, currency = nil)
      new(cents.round.to_f / 100, currency)
    end

    def from_subunits(subunits, currency_iso)
      currency = Helpers.value_to_currency(currency_iso)
      value = Helpers.value_to_decimal(subunits) / currency.subunit_to_unit
      new(value, currency)
    end

    def default_settings
      self.parser = MoneyParser
      self.default_currency = Money::NullCurrency.new
    end
  end
  default_settings

  def initialize(value = 0, currency = nil)
    raise ArgumentError if value.respond_to?(:nan?) && value.nan?
    @currency = Helpers.value_to_currency(currency)
    @value = Helpers.value_to_decimal(value).round(2)
    @cents = (@value * 100).to_i
    freeze
  end

  def init_with(coder)
    initialize(coder.map['value'], coder.map['currency'])
  end

  def -@
    Money.new(-value, currency)
  end

  def <=>(other)
    arithmetic(other) do |money|
      cents <=> money.cents
    end
  end

  def +(other)
    arithmetic(other) do |money|
      Money.new(value + money.value, currency)
    end
  end

  def -(other)
    arithmetic(other) do |money|
      Money.new(value - money.value, currency)
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
    "#<#{self.class} value:#{self.to_s} currency:#{self.currency}>"
  end

  def ==(other)
    eql?(other)
  end

  def eql?(other)
    return false unless other.is_a?(Money)
    arithmetic(other) do |money|
      value == money.value
    end
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

  def to_money(_currency = nil)
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

  def to_s(style = nil)
    case style
    when :legacy_dollars, nil
      sprintf("%.2f", value)
    when :legacy_cents
      (value * 100).round.to_i.to_s
    when :minor_units
      (value * currency.subunit_to_unit).round.to_i.to_s
    when :major_units
      sprintf("%.#{currency.minor_units}f", value)
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
      allocations = splits.inject(0) { |sum, n| sum + Helpers.value_to_decimal(n) }
    end

    if (allocations - BigDecimal("1")) > Float::EPSILON
      raise ArgumentError, "splits add to more than 100%"
    end

    amounts, left_over = amounts_from_splits(allocations, splits)

    left_over.to_i.times { |i| amounts[i % amounts.length] += 1 }

    amounts.collect { |cents| Money.from_cents(cents, currency) }
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

    cents_amounts.map { |cents| Money.from_cents(cents, currency) }
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
    low = Money.from_cents(cents / num, currency)
    high = Money.from_cents(low.cents + 1, currency)

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

  def amounts_from_splits(allocations, splits, cents_to_split = cents)
    left_over = cents_to_split

    amounts = splits.collect do |ratio|
      frac = (Helpers.value_to_decimal(cents_to_split * ratio) / allocations).floor
      left_over -= frac
      frac
    end

    [amounts, left_over]
  end

  def arithmetic(money_or_numeric)
    raise TypeError, "#{money_or_numeric.class.name} can't be coerced into Money" unless money_or_numeric.respond_to?(:to_money)
    other = money_or_numeric.to_money(currency)

    unless currency.compatible?(other.currency)
      Money.deprecate("mathematical operation not permitted for Money objects with different currencies #{other.currency} and #{currency}.")
    end
    yield(other)
  end
end
