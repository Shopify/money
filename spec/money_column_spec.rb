require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  RATE = 1.17
  before_validation do
    self.price_usd = Money.new(self[:price] * RATE, 'USD')
  end
  money_column :price, currency_column: 'currency'
  money_column :prix, currency_column: :devise
  money_column :price_usd, currency: 'USD'
end

class MoneyWithValidation < ActiveRecord::Base
  self.table_name = 'money_records'
  validates :price, :currency, presence: true
  money_column :price, currency_column: 'currency'
end

class MoneyWithReadOnlyCurrency < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'currency', currency_read_only: true
end

RSpec.describe 'MoneyColumn' do
  let(:amount) { 1.23 }
  let(:currency) { 'EUR' }
  let(:money) { Money.new(amount, currency) }
  let(:toonie) { Money.new(2.00, 'CAD') }
  let(:subject) { MoneyRecord.new(price: money, prix: toonie) }
  let(:record) do
    subject.save
    subject.reload
  end

  it 'returns money with currency from the default column' do
    expect(record.price).to eq(Money.new(1.23, 'EUR'))
  end

  it 'duplicating the record keeps the money values' do
    expect(MoneyRecord.new(price: money).clone.price).to eq(money)
    expect(MoneyRecord.new(price: money).dup.price).to eq(money)
  end

  it 'returns money with currency from the specified column' do
    expect(record.prix).to eq(Money.new(2.00, 'CAD'))
  end

  it 'returns money with the hardcoded currency' do
    expect(record.price_usd).to eq(Money.new(1.44, 'USD'))
  end

  it 'returns money with null currency when the currency in the DB is invalid' do
    expect(Money).to receive(:deprecate).once
    record.update_columns(currency: 'invalid')
    record.reload
    expect(record.price.currency).to be_a(Money::NullCurrency)
    expect(record.price.value).to eq(1.23)
  end

  it 'handles legacy support for saving floats' do
    record.update(price: 3.21, prix: 3.21)
    expect(record.price.value).to eq(3.21)
    expect(record.price.currency.to_s).to eq(currency)
    expect(record.price_usd.value).to eq(3.76)
    expect(record.price_usd.currency.to_s).to eq('USD')
    expect(record.prix.value).to eq(3.21)
    expect(record.prix.currency.to_s).to eq('CAD')
  end

  it 'handles legacy support for saving string' do
    record.update(price: '3.21', prix: '3.21')
    expect(record.price.value).to eq(3.21)
    expect(record.price.currency.to_s).to eq(currency)
    expect(record.price_usd.value).to eq(3.76)
    expect(record.price_usd.currency.to_s).to eq('USD')
    expect(record.prix.value).to eq(3.21)
    expect(record.prix.currency.to_s).to eq('CAD')
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

  describe 'null currency and validations' do
    let(:currency) { Money::NullCurrency.new }
    let(:subject) { MoneyWithValidation.new(price: money) }

    it 'is not allowed to be saved because `to_s` returns a blank string' do
      subject.valid?
      expect(subject.errors[:currency]).to include("can't be blank")
    end
  end

  describe 'read_only_currency true' do
    it 'does not write the currency to the db' do
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(price: 1, currency: 'USD')
      expect(Money).to receive(:deprecate).once
      record.update(price: Money.new(4, 'CAD'))
      expect(record.price.value).to eq(4)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'reads the currency that is already in the db' do
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(currency: 'USD', price: 1)
      record.reload
      expect(record.price.value).to eq(1)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'reads an invalid currency from the db and generates a no currency object' do
      expect(Money).to receive(:deprecate).once
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(currency: 'invalid', price: 1)
      record.reload
      expect(record.price.value).to eq(1)
      expect(record.price.currency.to_s).to eq('')
    end

    it 'sets the currency correctly when the currency is changed' do
      record = MoneyWithReadOnlyCurrency.create(currency: 'CAD', price: 1)
      record.currency = 'USD'
      expect(record.price.currency.to_s).to eq('USD')
    end
  end

  describe 'saving null' do
    it 'returns nil when money value have not been set' do
      record = MoneyRecord.new(price: nil, price_usd: nil)
      expect(record.price).to eq(nil)
      expect(record.price_usd).to eq(nil)
    end
  end
end
