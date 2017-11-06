# Parse an amount from a string
class MoneyParser
  MARKS = "\.,·’"
  EXTRA_MARKS = "\s˙'"

  def self.parse(input, currency = nil)
    new.parse(input, currency)
  end

  def parse(input, currency = nil)
    amount = extract_money(input.to_s, currency)
    Money.new(amount, currency)
  end

  private

  def extract_money(input, currency)
    return '0' if input.empty?

    amount = input.scan(/(-?[\d#{MARKS}][\d#{MARKS}#{EXTRA_MARKS}]*)/).first
    return '0' unless amount
    amount = amount.first.tr(EXTRA_MARKS, '')

    *other_marks, last_mark = amount.scan(/[#{MARKS}]/)
    return amount unless last_mark

    *dollars, cents = amount.split(last_mark)
    dollars = dollars.join.tr(MARKS, '')

    if last_digits_decimals?(dollars, cents, last_mark, other_marks, currency)
      "#{dollars}.#{cents}"
    else
      "#{dollars}#{cents}"
    end
  end

  def last_digits_decimals?(first_digits, last_digits, last_mark, other_marks, currency)
    # Thousands marks are always different from decimal marks
    # Example: 1,234,456
    other_marks.uniq!
    if other_marks.size == 1
      return other_marks.first != last_mark
    end

    # Thousands always have more than 2 digits
    # Example: 1,23 must be 1 dollar and 23 cents
    if last_digits.size < 3
      return true
    end

    # 0 before the final mark indicates last digits are decimals
    # Example: 0,23
    if first_digits.to_i.zero?
      return true
    end

    # The last mark matches the one used by the provided currency to delimiter decimals
    if currency
      return Money::Helpers.value_to_currency(currency).decimal_mark == last_mark
    end

    # legacy support for 1.000
    last_digits.size != 3
  end
end
