class MoneyParser
  ZERO_MONEY = "0.00"

  # parse a amount from a string
  def self.parse(input)
    new.parse(input)
  end

  def parse(input)
    Money.new(extract_money(input.to_s))
  end

  private
  def extract_money(input)
    return ZERO_MONEY if input.to_s.empty?

    amount = input.scan(/\-?[\d\.\,]+/).first

    return ZERO_MONEY if amount.nil?

    # Convert amount with more than 3 decimals to amount with 2 decimals
    amount.gsub!(/^(-)?(\d{1,}[,.]\d\d)[1-9]+$/, '\1\2')

    segments = amount.scan(/^(.*?)(?:[\.\,](\d{1,2}))?$/).first

    return ZERO_MONEY if segments.empty?

    amount   = segments[0].gsub(/[^-\d]/, '')
    decimals = segments[1].to_s.ljust(2, '0')

    "#{amount}.#{decimals}"
  end
end
