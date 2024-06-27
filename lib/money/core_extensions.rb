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
    currency = Money::Helpers.value_to_currency(currency)

    unless Money.config.legacy_deprecations
      return Money.new(self, currency)
    end

    new_value = BigDecimal(self, exception: false)&.round(currency.minor_units)
    unless new_value.nil?
      return Money.new(self, currency)
    end

    Money::Parser::Fuzzy.parse(self, currency).tap do |money|
      old_value = money.value

      if new_value != old_value
        message = "`\"#{self}\".to_money` will soon behave like `Money.new(\"#{self}\")` and " \
          "raise an ArgumentError exception. Use the browser's locale to parse money strings."

        Money.deprecate(message)
      end
    end
  end
end
