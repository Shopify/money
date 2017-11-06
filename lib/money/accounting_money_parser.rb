class AccountingMoneyParser < MoneyParser
  private
  def extract_money(input, currency = nil)
    # set () to mean negativity. ignore $
    super(input.gsub(/\(\$?(.*?)\)/, '-\1'), currency)
  end
end
