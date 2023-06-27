# frozen_string_literal: true
# Allows Writing of 100.to_money for +Numeric+ types
#   100.to_money => #<Money @cents=10000>
#   100.37.to_money => #<Money @cents=10037>
class Numeric
  def to_money(currency = nil)
    Money.new(self, currency)
  end
end

# Allows Writing of '100'.to_money for +String+ types
# Excess characters will be discarded
#   '100'.to_money => #<Money @cents=10000>
#   '100.37'.to_money => #<Money @cents=10037>
class String
  def to_money(currency = nil)
    if Money.config.legacy_deprecations
      Money.deprecate("`#{self}.to_money` will raise an ArgumentError in the next major release")
      Money::Parser::Fuzzy.parse(self, currency)
    else
      Money.new(self, currency)
    end
  end
end
