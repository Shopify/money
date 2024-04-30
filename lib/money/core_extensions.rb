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
    return Money.new(self, currency) unless Money.config.legacy_deprecations

    Money::Parser::Fuzzy.parse(self, currency).tap do |money|
      new_value = BigDecimal(self, exception: false)
      old_value = money.value

      if new_value != old_value
        message = "`\"#{self}\".to_money` will soon behave like `Money.new(\"#{self}\")` and "
        message +=
          if new_value.nil?
            "raise an ArgumentError exception."
          else
            "return #{new_value} instead of #{old_value}."
          end
        message += " Best practice to parse user input is to do so on the browser and use the user's locale."
        Money.deprecate(message)
      end
    end
  end
end
