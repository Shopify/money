# Allows Writing of 100.to_money for +Numeric+ types
#   100.to_money => #<Money @fractional=100>
#   100.37.to_money => #<Money @fractional=10037>
class Numeric
  def to_money
    Money.new(self * 100)
  end

  def exchange_to(arg)
    to_money
  end
end

# Allows Writing of '100'.to_money for +String+ types
# Excess characters will be discarded
#   '100'.to_money => #<Money @cents=10000>
#   '100.37'.to_money => #<Money @cents=10037>
class String
  def to_money
    empty? ? Money.empty : Money.parse(self)
  end
end
