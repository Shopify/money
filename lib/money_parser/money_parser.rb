class MoneyParser < BasicMoneyParser
  ZERO_MONEY = "0.00"

  private

  def extract_money(input)
    Money.deprecate("MoneyParser is depreciated and will be removed in 1.0.0 in favor of the BasicMoneyParser. Please implement your own parser if you'd like to keep this functionality")

    return ZERO_MONEY if input.to_s.empty?

    amount = input.scan(/\-?[\d\.\,]+/).first

    return ZERO_MONEY if amount.nil?

    # Convert 0.123 or 0,123 into what will be parsed as a decimal amount 0.12 or 0.13
    amount.gsub!(/^(-)?(0[,.]\d\d)\d+$/, '\1\2')

    segments = amount.scan(/^(.*?)(?:[\.\,](\d{1,2}))?$/).first

    return ZERO_MONEY if segments.empty?

    amount   = segments[0].gsub(/[^-\d]/, '')
    decimals = segments[1].to_s.ljust(2, '0')

    super("#{amount}.#{decimals}")
  end
end
