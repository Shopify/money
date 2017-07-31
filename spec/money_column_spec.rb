require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  RATE = 1.17
  before_validation do
    self.price_usd = Money.new(self[:price] * RATE, 'USD') if attribute_present?('price')
  end

  money_column :price
  money_column :prix, currency_column: :devise
  money_column :price_usd, currency_column: false, currency: 'USD'
end

class MoneyWithValidation < ActiveRecord::Base
  self.table_name = 'money_records'
  validates :price, :currency, presence: true
  money_column :price
end

RSpec.describe 'MoneyColumn' do
  let(:amount) { 1.23 }
  let(:currency) { 'EUR' }
  let(:money) { Money.new(amount, currency) }
  let(:toonie) { Money.new(2.00, 'CAD') }
  let(:subject) { MoneyRecord.new(price: money, prix: toonie) }
  let(:record) do
    subject.save
    subject.class.find(subject.id)
  end

  it 'returns money with currency from the default column' do
    expect(record.price).to eq(Money.new(1.23, 'EUR'))
  end

  it 'returns money with currency from the specified column' do
    expect(record.prix).to eq(Money.new(2.00, 'CAD'))
  end

  it 'returns money with the hardcoded currency' do
    expect(record.price_usd).to eq(Money.new(1.44, 'USD'))
  end

  describe 'non-fractional-currencies' do
    let(:money) { Money.new(1, 'JPY') }

    it 'returns money with currency from the default column' do
      expect(record.price).to eq(Money.new(1, 'JPY'))
    end
  end

  describe 'three-decimal currencies' do
    let(:money) { Money.new(1.234, 'JOD') }

    it 'returns money with currency from the default column' do
      expect(record.price).to eq(Money.new(1.234, 'JOD'))
    end
  end

  describe 'garbage amount' do
    let(:amount) { 'foo' }

    it 'raises a deprecation warning' do
      expect { subject }.to raise_error(ActiveSupport::DeprecationException)
    end
  end

  describe 'garbage currency' do
    let(:currency) { 'foo' }

    it 'raises an UnknownCurrency error' do
      expect { subject }.to raise_error(ActiveSupport::DeprecationException)
    end
  end

  describe 'wrong money_column currency arguments' do
    let(:subject) do
      class MoneyWithWrongCurrencyArguments < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency_column: :currency, currency: 'USD'
      end
    end

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError, 'cannot set both currency_column and a fixed currency')
    end
  end

  describe 'missing money_column currency arguments' do
    let(:subject) do
      class MoneyWithMissingCurrencyArguments < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency_column: false, currency: false
      end
    end

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError, 'need to set either currency_column or currency')
    end
  end

  describe 'null currency and validations' do
    let(:currency) { Money::NullCurrency.new }
    let(:subject) { MoneyWithValidation.new(price: money) }

    it 'is not allowed to be saved because `to_s` returns a blank string' do
      subject.valid?
      expect(subject.errors[:currency]).to include("can't be blank")
    end
  end
end
