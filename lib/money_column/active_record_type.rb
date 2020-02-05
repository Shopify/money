# frozen_string_literal: true
class MoneyColumn::ActiveRecordType < ActiveRecord::Type::Decimal
  def serialize(money)
    return nil unless money
    super(money.to_d)
  end
end
