# frozen_string_literal: true

module MoneyColumn
  class ActiveRecordType < ActiveRecord::Type::Decimal
    def serialize(money)
      return unless money
      super(money.to_d)
    end
  end
end
