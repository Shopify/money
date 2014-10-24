require 'money/money'

class Money
  def /(numeric)
    raise "[Money] Dividing money objects can lose pennies. Use #split instead"
  end

  class ReverseOperationProxy
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
    Money.new(cents.round)
  end

  def to_liquid
    fractional
  end

  def to_json(options = {})
    to_s
  end

  def as_json(*args)
    to_s
  end

  def floor
    to_i
  end

  def fraction(rate)
    raise ArgumentError, "rate should be positive" if rate < 0

    result = fractional / (1 + rate)
    Money.new(result)
  end
end
