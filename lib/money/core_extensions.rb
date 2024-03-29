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
      Money::Parser::Fuzzy.parse(self, currency).tap do |money|
        message = "`#{self}.to_money` will behave like `Money.new` and raise on the next release. " \
          "To parse user input, do so on the browser and use the user's locale."
        Money.deprecate(message) if money.value != BigDecimal(self, exception: false)
      end
    else
      Money.new(self, currency)
    end
  end
end
