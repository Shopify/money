# frozen_string_literal: true

# Parse an amount from a string
class StrictMoneyParser
  def self.parse(value, currency = nil, **options)
    new.parse(value, currency, **options)
  end

  def parse(value, currency = nil, *_)
    if value.nil?
      raise ArgumentError, "value can't be nil"
    end

    value = value.to_s.strip

    if value.empty?
      return Money.new(0, currency)
    end

    value = value.sub(/\.\z/, "")

    unless value =~ /\A[+-]?(\d+|\d+\.\d+|\.\d+)\z/
      raise Money::ParserError, "invalid money value #{value}"
    end

    Money.new(value, currency)
  end
end
