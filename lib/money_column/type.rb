module MoneyColumn
  class Type < ActiveRecord::Type::Decimal
    def serialize(money)
      case money
      when ::Money
        super(money.value)
      else
        super(money.blank? ? nil : money)
      end
    end
  end
end
