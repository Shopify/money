class AccountingMoneyParser < MoneyParser
  private
  def extract_money(input)
    # set () to mean negativity
    super(input.gsub(/\(\$?(.*?)\)/, '-\1'))
  end
end