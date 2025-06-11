# frozen_string_literal: true

require 'delegate'
require 'bigdecimal'

class Money
  class Allocator < SimpleDelegator
    def initialize(money)
      super
    end

    ONE = BigDecimal("1")

    # Allocates money between different parties without losing subunits. A "subunit"
    # in this context is the smallest unit of a currency that can be divided no
    # further. In USD the unit is dollars and the subunit is cents. In JPY the unit
    # is yen and the subunit is also yen. So given $1 divided by 3, the resulting subunits
    # should be [34¢, 33¢, 33¢]. Notice that one of these chunks is larger than the other
    # two, because we cannot transact in amounts less than 1 subunit.
    #
    # After the mathematically split has been performed, left over subunits will
    # be distributed round-robin or nearest-subunit strategy amongst the parties.
    # Round-robin strategy has the virtue of being easier to understand, while
    # nearest-subunit is a more complex alogirthm that results in the most fair
    # distribution.
    #
    # @param splits [Array<Numeric>]
    # @param strategy Symbol
    # @return [Array<Money>]
    #
    # Strategies:
    # - `:roundrobin` (default): leftover subunits will be accumulated starting from the first allocation left to right
    # - `:roundrobin_reverse`: leftover subunits will be accumulated starting from the last allocation right to left
    # - `:nearest`: leftover subunits will by given first to the party closest to the next whole subunit
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

    # @example left over subunits distributed reverse order when using roundrobin_reverse strategy
    #   Money.new(10.01, "USD").allocate([0.5, 0.5], :roundrobin_reverse)
    #     #=> [#<Money value:5.00 currency:USD>, #<Money value:5.01 currency:USD>]

    # @examples left over subunits distributed by nearest strategy
    #   Money.new(10.55, "USD").allocate([0.25, 0.5, 0.25], :nearest)
    #     #=> [#<Money value:2.64 currency:USD>, #<Money value:5.27 currency:USD>, #<Money value:2.64 currency:USD>]

    def allocate(splits, strategy = :roundrobin)
      if splits.empty?
        raise ArgumentError, 'at least one split must be provided'
      end

      splits.map!(&:to_r)
      allocations = splits.inject(0, :+)

      if (allocations - ONE) > Float::EPSILON
        raise ArgumentError, "allocations add to more than 100%"
      end

      amounts, left_over = amounts_from_splits(allocations, splits)

      order = case strategy
      when :roundrobin
        (0...left_over).to_a
      when :roundrobin_reverse
        (0...amounts.length).to_a.reverse
      when :nearest
        rank_by_nearest(amounts)
      else
        raise ArgumentError, "Invalid strategy. Valid options: :roundrobin, :roundrobin_reverse, :nearest"
      end

      left_over.to_i.times do |i|
        amounts[order[i]][:whole_subunits] += 1
      end

      amounts.map { |amount| Money.from_subunits(amount[:whole_subunits], currency) }
    end

    # Allocates money between different parties up to the maximum amounts specified.
    # Left over subunits will be assigned round-robin up to the maximum specified.
    # Subunits are dropped when the maximums are attained.
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
      allocation_currency = extract_currency(maximums + [__getobj__])
      maximums = maximums.map { |max| max.to_money(allocation_currency) }
      maximums_total = maximums.reduce(Money.new(0, allocation_currency), :+)

      splits = maximums.map do |max_amount|
        next(Rational(0)) if maximums_total.zero?
        Money.rational(max_amount, maximums_total)
      end

      total_allocatable = [maximums_total.subunits, subunits].min

      subunits_amounts, left_over = amounts_from_splits(1, splits, total_allocatable)
      subunits_amounts.map! { |amount| amount[:whole_subunits] }

      subunits_amounts.each_with_index do |amount, index|
        break if left_over <= 0

        max_amount = maximums[index].value * allocation_currency.subunit_to_unit
        next if amount >= max_amount

        left_over -= 1
        subunits_amounts[index] += 1
      end

      subunits_amounts.map { |cents| Money.from_subunits(cents, allocation_currency) }
    end

    private

    def extract_currency(money_array)
      currencies = money_array.lazy.select do |money|
        money.is_a?(Money)
      end.reject(&:no_currency?).map(&:currency).to_a.uniq
      if currencies.size > 1
        raise ArgumentError,
          "operation not permitted for Money objects with different currencies #{currencies.join(", ")}"
      end
      currencies.first || NULL_CURRENCY
    end

    def amounts_from_splits(allocations, splits, subunits_to_split = subunits)
      raise ArgumentError, "All splits values must be of type Rational." unless all_rational?(splits)

      left_over = subunits_to_split

      amounts = splits.map do |ratio|
        whole_subunits = (subunits_to_split * ratio / allocations.to_r).floor
        fractional_subunits = (subunits_to_split * ratio / allocations.to_r).to_f - whole_subunits
        left_over -= whole_subunits
        {
          whole_subunits: whole_subunits,
          fractional_subunits: fractional_subunits,
        }
      end

      [amounts, left_over]
    end

    def all_rational?(splits)
      splits.all? { |split| split.is_a?(Rational) }
    end

    # Given a list of decimal numbers, return a list ordered by which is nearest to the next whole number.
    # For instance, given inputs [1.1, 1.5, 1.9] the correct ranking is 2, 1, 0. This is because 1.9 is nearly 2.
    # Note that we are not ranking by absolute size, we only care about the distance between our input number and
    # the next whole number. Similarly, given the input [9.1, 5.5, 3.9] the correct ranking is *still* 2, 1, 0. This
    # is because 3.9 is nearer to 4 than 9.1 is to 10.
    def rank_by_nearest(amounts)
      amounts.each_with_index.sort_by { |amount, _i| 1 - amount[:fractional_subunits] }.map(&:last)
    end
  end
end
