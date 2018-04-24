require 'spec_helper'

class RecordWithCurrencyValidation < ActiveRecord::Base
  self.table_name = 'money_records'
  validates :currency, presence: true, currency_code: true
end

RSpec.describe 'CurrencyCodeValidator' do
  it 'does not apply invalid_currency error when currency is blank' do
    subject = RecordWithCurrencyValidation.new

    expect(subject.valid?).to be false
    expect(subject.errors.details[:currency]).not_to include({:error => :invalid_currency})
  end

  it 'does not apply invalid_currency error when currency is valid' do
    subject = RecordWithCurrencyValidation.new(price: 10, currency: 'USD')

    expect(subject.valid?).to be true
    expect(subject.errors.details[:currency]).not_to include({:error => :invalid_currency})
  end

  it 'applies invalid_currency error when currency is invalid' do
    subject = RecordWithCurrencyValidation.new(price: 10, currency: 'some_invalid_currency')

    expect(subject.valid?).to be false
    expect(subject.errors.details[:currency]).to include({:error => :invalid_currency})
    expect(subject.errors[:currency]).to include('some_invalid_currency is not a valid currency')
  end
end
