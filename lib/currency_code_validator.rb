# frozen_string_literal: true

class CurrencyCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if value.present? && Money::Currency.find(value).nil?
      record.errors.add(attribute, :invalid_currency, message: "#{value} is not a valid currency")
    end
  end
end
