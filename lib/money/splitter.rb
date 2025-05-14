# frozen_string_literal: true

class Money
  class Splitter
    include Enumerable

    def initialize(money, num)
      @num = Integer(num)
      raise ArgumentError, "need at least one party" if num < 1
      @money = money
      @split = nil
    end

    protected attr_writer(:split)

    def split
      @split ||= begin
        subunits = @money.subunits
        low = Money.from_subunits(subunits / @num, @money.currency)
        high = Money.from_subunits(low.subunits + 1, @money.currency)

        num_high = subunits % @num

        split = {}
        split[high] = num_high if num_high > 0
        split[low] = @num - num_high
        split.freeze
      end
    end

    alias_method :to_ary, :to_a

    def first(count = (count_undefined = true))
      if count_undefined
        each do |money|
          return money
        end
      elsif count >= size
        to_a
      else
        result = Array.new(count)
        index = 0
        each do |money|
          result[index] = money
          index += 1
          break if index == count
        end
        result
      end
    end

    def last(count = (count_undefined = true))
      if count_undefined
        reverse_each do |money|
          return money
        end
      elsif count >= size
        to_a
      else
        result = Array.new(count)
        index = 0
        reverse_each do |money|
          result[index] = money
          index += 1
          break if index == count
        end
        result.reverse!
        result
      end
    end

    def [](index)
      offset = 0
      split.each do |money, count|
        offset += count
        if index < offset
          return money
        end
      end
      nil
    end

    def reverse_each(&block)
      split.reverse_each do |money, count|
        count.times do
          yield money
        end
      end
    end

    def each(&block)
      split.each do |money, count|
        count.times do
          yield money
        end
      end
    end

    def reverse
      copy = dup
      copy.split = split.reverse_each.to_h.freeze
      copy
    end

    def size
      count = 0
      split.each_value { |c| count += c }
      count
    end
  end
end
