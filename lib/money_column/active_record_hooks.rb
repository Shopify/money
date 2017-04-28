module MoneyColumn
  class Type < ActiveRecord::Type::Value
    def cast(value)
      return nil if value.blank? || !value.respond_to?(:to_money)
      value.to_money
    end

    def serialize(money)
      case money
      when ::Money
        money.value
      else
        money
      end
    end
  end

  module ActiveRecordHooks
    def money_column(*columns)
      Array(columns).flatten.each do |name|
        attribute name, MoneyColumn::Type.new
      end
    end
  end
end
