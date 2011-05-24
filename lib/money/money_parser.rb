class MoneyParser
  ZERO_MONEY = "0.00"

  # parse a amount from a string
  def self.parse(input)
    new.parse(input)
  end
  
  def parse(input)
    Money.new(extract_money(input))
  end
  
  private
  def extract_money(input)
    return ZERO_MONEY if input.to_s.empty?
    
    amount = input.scan(/\-?[\d\.\,]+/).first
            
    return ZERO_MONEY if amount.nil?
    
    # Convert 0.123 or 0,123 into what will be parsed as a decimal amount 0.12 or 0.13
    amount.gsub!(/^(-)?(0[,.]\d\d)\d+$/, '\1\2')
            
    segments = amount.scan(/^(.*?)(?:[\.\,](\d{1,2}))?$/).first
        
    return ZERO_MONEY if segments.empty?    
    
    amount   = segments[0].gsub(/[^-\d]/, '')
    decimals = segments[1].to_s.ljust(2, '0')
    
    "#{amount}.#{decimals}"
  end
end