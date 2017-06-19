class BasicMoneyParser
  class InvalidMoneyValue < ArgumentError; end

  REGEX = /\A-?\d*\.?\d*\z/

  def self.parse(input)
    new.parse(input)
  end

  def parse(input)
    normalized = extract_money(input.to_s)
    raise InvalidMoneyValue unless normalized =~ REGEX

    Money.new(normalized)
  end

  private

  def extract_money(input)
    input.gsub(/[\$,_ ]/,'')
  end
end
