class Money
  include Comparable
  extend Forwardable

  NULL_CURRENCY = NullCurrency.new.freeze

  attr_reader :value, :currency
  def_delegators :@value, :zero?, :nonzero?, :positive?, :negative?, :to_i, :to_f, :hash

  class << self
    attr_accessor :parser, :default_currency

    def new(value = 0, currency = nil)
      currency ||= resolve_currency

      value = Helpers.value_to_decimal(value)
      if value.zero?
        @@zero_money ||= {}
        @@zero_money[currency] ||= super(Helpers::DECIMAL_ZERO, currency)
      else
        super(value, currency)
      end
    end
    alias_method :from_amount, :new

    def zero
      new(0, NULL_CURRENCY)
    end
    alias_method :empty, :zero

    def parse(input, currency = nil)
      parser.parse(input, currency)
    end

    def from_cents(cents, currency = nil)
      new(cents.round.to_f / 100, currency)
    end

    def from_subunits(subunits, currency_iso)
      currency = Helpers.value_to_currency(currency_iso)
      value = Helpers.value_to_decimal(subunits) / currency.subunit_to_unit
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

    private

    def resolve_currency
      current_currency || default_currency || raise(ArgumentError, 'missing currency')
    end
  end
  default_settings

  def initialize(value, currency)
    raise ArgumentError if value.nan?
    @currency = Helpers.value_to_currency(currency)
    @value = value.round(@currency.minor_units)
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

  def subunits
    (@value * @currency.subunit_to_unit).to_i
  end

  def no_currency?
    currency.is_a?(NullCurrency)
  end

  def -@
    Money.new(-value, currency)
  end

  def <=>(other)
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

  def to_money(_currency = nil)
    self
  end

  def to_d
    value
  end

  def to_s(style = nil)
    case style
    when :legacy_dollars
      sprintf("%.2f", value)
    when :amount, nil
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
  # After the mathematically split has been performed, left over pennies will
  # be distributed round-robin amongst the parties. This means that parties
  # listed first will likely receive more pennies than ones that are listed later
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

    amounts.collect { |subunits| Money.from_subunits(subunits, currency) }
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
    allocation_currency = extract_currency(maximums + [self])
    maximums = maximums.map { |max| max.to_money(allocation_currency) }
    maximums_total = maximums.reduce(Money.new(0, allocation_currency), :+)

    splits = maximums.map do |max_amount|
      next(0) if maximums_total.zero?
      Money.rational(max_amount, maximums_total)
    end

    total_allocatable = [
      value * allocation_currency.subunit_to_unit,
      maximums_total.value * allocation_currency.subunit_to_unit
    ].min

    subunits_amounts, left_over = amounts_from_splits(1, splits, total_allocatable)

    subunits_amounts.each_with_index do |amount, index|
      break unless left_over > 0

      max_amount = maximums[index].value * allocation_currency.subunit_to_unit
      next unless amount < max_amount

      left_over -= 1
      subunits_amounts[index] += 1
    end

    subunits_amounts.map { |cents| Money.from_subunits(cents, allocation_currency) }
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
    subunits = self.subunits
    low = Money.from_subunits(subunits / num, currency)
    high = Money.from_subunits(low.subunits + 1, currency)

    remainder = subunits % num
    result = []

    num.times do |index|
      result[index] = index < remainder ? high : low
    end

    return result
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

    clamped_value = [min, self.value, max].sort[1]
    if self.value == clamped_value
      self
    else
      Money.new(clamped_value, self.currency)
    end
  end

  private

  def all_rational?(splits)
    splits.all? { |split| split.is_a?(Rational) }
  end

  def amounts_from_splits(allocations, splits, subunits_to_split = subunits)
    left_over = subunits_to_split

    amounts = splits.collect do |ratio|
      frac = (Helpers.value_to_decimal(subunits_to_split * ratio) / allocations).floor
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

  def calculated_currency(other)
    no_currency? ? other : currency
  end

  def extract_currency(money_array)
    currencies = money_array.lazy.select { |money| money.is_a?(Money) }.reject(&:no_currency?).map(&:currency).to_a.uniq
    if currencies.size > 1
      raise ArgumentError, "operation not permitted for Money objects with different currencies #{currencies.join(', ')}"
    end
    currencies.first || NULL_CURRENCY
  end
end
