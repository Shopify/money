module MoneyColumn
  class Type < ActiveRecord::Type::Value
    def cast(value)
      return nil if value.blank? || !value.respond_to?(:to_money)
      value.to_money
    end

    def serialize(money)
      money.value
    end
  end

  module ActiveRecordHooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def money_column(*columns)
        Array(columns).flatten.each do |name|
          attribute name, MoneyColumn::Type.new
        end
      end
    end
  end
end
