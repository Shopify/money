# frozen_string_literal: true
require 'delegate'

class Money
  class Allocator < SimpleDelegator
    def initialize(money)
      super
    end

    ONE = BigDecimal("1")

    # Allocates money between different parties without losing pennies.
    # After the mathematically split has been performed, left over pennies will
    # be distributed round-robin amongst the parties. This means that parties
    # listed first will likely receive more pennies than ones that are listed later
    #
    # @param splits [Array<Numeric>]
    # @param strategy Symbol
    # @return [Array<Money>]
    #
    # Strategies:
    # - `:roundrobin` (default): leftover pennies will be accumulated starting from the first allocation left to right
    # - `:roundrobin_reverse`: leftover pennies will be accumulated starting from the last allocation right to left
    #
    # @example
    #   Money.new(5, "USD").allocate([0.50, 0.25, 0.25])
    #     #=> [#<Money value:2.50 currency:USD>, #<Money value:1.25 currency:USD>, #<Money value:1.25 currency:USD>]
    #   Money.new(5, "USD").allocate([0.3, 0.7])
    #     #=> [#<Money value:1.50 currency:USD>, #<Money value:3.50 currency:USD>]
    #   Money.new(100, "USD").allocate([0.33, 0.33, 0.33])
    #     #=> [#<Money value:33.34 currency:USD>, #<Money value:33.33 currency:USD>, #<Money value:33.33 currency:USD>]

    # @example left over cents distributed to first party due to rounding, and two solutions for a more natural distribution
    #   Money.new(30, "USD").allocate([0.667, 0.333])
    #     #=> [#<Money value:20.01 currency:USD>, #<Money value:9.99 currency:USD>]
    #   Money.new(30, "USD").allocate([0.333, 0.667])
    #     #=> [#<Money value:20.00 currency:USD>, #<Money value:10.00 currency:USD>]
    #   Money.new(30, "USD").allocate([Rational(2, 3), Rational(1, 3)])
    #     #=> [#<Money value:20.00 currency:USD>, #<Money value:10.00 currency:USD>]

    # @example left over pennies distributed reverse order when using roundrobin_reverse strategy
    #   Money.new(10.01, "USD").allocate([0.5, 0.5], :roundrobin_reverse)
    #     #=> [#<Money value:5.00 currency:USD>, #<Money value:5.01 currency:USD>]
    def allocate(splits, strategy = :roundrobin)
      splits.map!(&:to_r)
      allocations = splits.inject(0, :+)

      if (allocations - ONE) > Float::EPSILON
        raise ArgumentError, "splits add to more than 100%"
      end

      amounts, left_over = amounts_from_splits(allocations, splits)

      left_over.to_i.times do |i|
        amounts[allocation_index_for(strategy, amounts.length, i)] += 1
      end

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
      allocation_currency = extract_currency(maximums + [self.__getobj__])
      maximums = maximums.map { |max| max.to_money(allocation_currency) }
      maximums_total = maximums.reduce(Money.new(0, allocation_currency), :+)

      splits = maximums.map do |max_amount|
        next(Rational(0)) if maximums_total.zero?
        Money.rational(max_amount, maximums_total)
      end

      total_allocatable = [maximums_total.subunits, self.subunits].min

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

    private

    def extract_currency(money_array)
      currencies = money_array.lazy.select { |money| money.is_a?(Money) }.reject(&:no_currency?).map(&:currency).to_a.uniq
      if currencies.size > 1
        raise ArgumentError, "operation not permitted for Money objects with different currencies #{currencies.join(', ')}"
      end
      currencies.first || NULL_CURRENCY
    end

    def amounts_from_splits(allocations, splits, subunits_to_split = subunits)
      raise ArgumentError, "All splits values must be of type Rational." unless all_rational?(splits)

      left_over = subunits_to_split

      amounts = splits.collect do |ratio|
        frac = (subunits_to_split * ratio / allocations.to_r).floor
        left_over -= frac
        frac
      end

      [amounts, left_over]
    end

    def all_rational?(splits)
      splits.all? { |split| split.is_a?(Rational) }
    end

    def allocation_index_for(strategy, length, idx)
      case strategy
      when :roundrobin
        idx % length
      when :roundrobin_reverse
        length - (idx % length) - 1
      else
        raise ArgumentError, "Invalid strategy. Valid options: :roundrobin, :roundrobin_reverse"
      end
    end
  end
end
