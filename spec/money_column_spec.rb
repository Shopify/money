require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  RATE = 1.17
  before_validation do
    self.price_usd = Money.new(self["price"] * RATE, 'USD') if self["price"]
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

class MoneyRecordCoerceNull < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'currency', coerce_null: true
  money_column :price_usd, currency: 'USD', coerce_null: true
end

class MoneyWithDelegatedCurrency < ActiveRecord::Base
  self.table_name = 'money_records'
  attr_accessor :delegated_record
  delegate :currency, to: :delegated_record
  money_column :price, currency_column: 'currency', currency_read_only: true
  money_column :prix, currency_column: 'currency2', currency_read_only: true
  def currency2
    delegated_record.currency
  end
end

class MoneyWithCustomAccessors < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'currency'
  def price
    read_money_attribute(:price)
  end
  def price=(value)
    write_money_attribute(:price, value + 1)
  end
end

class MoneyClassInheritance < MoneyWithCustomAccessors
  money_column :prix, currency_column: 'currency'
end

class MoneyClassInheritance2 < MoneyWithCustomAccessors
  money_column :price, currency: 'CAD'
  money_column :price_usd, currency: 'USD'
end

RSpec.describe 'MoneyColumn' do
  let(:amount) { 1.23 }
  let(:currency) { 'EUR' }
  let(:money) { Money.new(amount, currency) }
  let(:toonie) { Money.new(2.00, 'CAD') }
  let(:subject) { MoneyRecord.new(price: money, prix: toonie) }
  let(:record) do
    subject.devise = 'CAD'
    subject.save
    subject.reload
  end

  it 'returns money with currency from the default column' do
    expect(record.price).to eq(Money.new(1.23, 'EUR'))
  end

  it 'writes the currency to the db using update' do
    record.update(currency: nil)
    record.update(price: Money.new(4, 'JPY'))
    record.reload
    expect(record.price.value).to eq(4)
    expect(record.price.currency.to_s).to eq('JPY')
  end

  it 'writes the currency to the db using update_column' do
    record.price
    record.currency
    record.devise

    record.update_columns(price: 4, currency: 'JPY', devise: 'ok')

    expect(record.devise).to eq('ok')
    expect(record.price.value).to eq(4)
    expect(record.price.currency.to_s).to eq('JPY')
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

  it 'handles legacy support for saving floats with correct currency rounding' do
    record.update(price: 3.2112, prix: 3.2156)
    expect(record.attributes['price']).to eq(3.21)
    expect(record.price.value).to eq(3.21)
    expect(record.price.currency.to_s).to eq(currency)
    expect(record.attributes['prix']).to eq(3.22)
    expect(record.prix.value).to eq(3.22)
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

  it 'does not overwrite a currency column with a default currency when saving zero' do
    expect(record.currency.to_s).to eq('EUR')
    record.update(price: Money.zero)
    expect(record.currency.to_s).to eq('EUR')
  end

  it 'does overwrite a currency if changed but will show a deprecation notice' do
    expect(record.currency.to_s).to eq('EUR')
    expect(Money).to receive(:deprecate).once
    record.update(price: Money.new(4, 'JPY'))
    expect(record.currency.to_s).to eq('JPY')
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
      expect { subject }.to raise_error(ArgumentError, 'cannot set both :currency_column and :currency options')
    end
  end

  describe 'missing money_column currency arguments' do
    let(:subject) do
      class MoneyWithWrongCurrencyArguments < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price
      end
    end

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError, 'must set one of :currency_column or :currency options')
    end
  end

  describe 'null currency and validations' do
    let(:currency) { Money::NULL_CURRENCY }
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

    it 'handle cases where the delegate allow_nil is false' do
      record = MoneyWithDelegatedCurrency.new(price: Money.new(10, 'USD'), delegated_record: MoneyRecord.new(currency: 'USD'))
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handle cases where a manual delegate does not allow nil' do
      record = MoneyWithDelegatedCurrency.new(prix: Money.new(10, 'USD'), delegated_record: MoneyRecord.new(currency: 'USD'))
      expect(record.price.currency.to_s).to eq('USD')
    end
  end

  describe 'coerce_null' do
    it 'returns nil when money value have not been set and coerce_null is false' do
      record = MoneyRecord.new(price: nil)
      expect(record.price).to eq(nil)
      expect(record.price_usd).to eq(nil)
    end

    it 'returns 0$ when money value have not been set and coerce_null is true' do
      record = MoneyRecordCoerceNull.new(price: nil)
      expect(record.price.value).to eq(0)
       expect(record.price_usd.value).to eq(0)
    end
  end

  describe 'memoization' do
    it 'correctly memoizes the read value' do
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(nil)
      price = Money.new(1, 'USD')
      record = MoneyRecord.new(price: price)
      expect(record.price).to eq(price)
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(price)
    end

    it 'memoizes values get reset when writing a new value' do
      price = Money.new(1, 'USD')
      record = MoneyRecord.new(price: price)
      expect(record.price).to eq(price)
      price = Money.new(2, 'USD')
      record.update!(price: price)
      expect(record.price).to eq(price)
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(price)
    end

    it 'reload will clear memoized money values' do
      price = Money.new(1, 'USD')
      record = MoneyRecord.create(price: price)
      expect(record.price).to eq(price)
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(price)
      record.reload
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(nil)
      record.price
      expect(record.instance_variable_get(:@money_column_cache)["price"]).to eq(price)
    end

    it 'reload will clear record cache' do
      price = Money.new(1, 'USD')
      price2 = Money.new(2, 'USD')

      record = MoneyRecord.create(price: price)
      expect(record.price).to eq(price)
      expect(record[:price]).to eq(price)

      ActiveRecord::Base.connection.execute("UPDATE money_records SET price=#{price2.value} WHERE id=#{record.id}")
      expect(record[:price]).to_not eq(price2)
      expect(record.price).to_not eq(price2)

      record.reload
      expect(record[:price]).to eq(price2)
      expect(record.price).to eq(price2)
    end
  end

  describe 'ActiveRecord querying' do
    it 'can be serialized for querying on the value' do
      price = Money.new(1, 'USD')
      record = MoneyRecord.create!(price: price)
      expect(MoneyRecord.find_by(price: price)).to eq(record)
    end

    it 'nil value persist in the DB' do
      record = MoneyRecord.create!(price: nil)
      expect(MoneyRecord.find_by(price: nil)).to eq(record)
    end
  end

  describe 'money column attribute accessors' do
    it 'allows to overwrite the setter' do
      amount = Money.new(1, 'USD')
      expect(MoneyWithCustomAccessors.new(price: amount).price).to eq(MoneyRecord.new(price: amount).price + 1)
    end

    it 'correctly assigns the money_column_cache' do
      amount = Money.new(1, 'USD')
      object = MoneyWithCustomAccessors.new(price: amount)
      expect(object.instance_variable_get(:@money_column_cache)['price']).to eql(nil)
      expect(object.price).to eql(amount + 1)
      expect(object.instance_variable_get(:@money_column_cache)['price']).to eql(amount + 1)
    end
  end

  describe 'class inheritance' do
    it 'shares money columns declared on the parent class' do
      expect(MoneyClassInheritance.instance_variable_get(:@money_column_options).dig('price', :currency_column)).to eq('currency')
      expect(MoneyClassInheritance.instance_variable_get(:@money_column_options).dig('price', :currency)).to eq(nil)
      expect(MoneyClassInheritance.new(price: Money.new(1, 'USD')).price).to eq(Money.new(2, 'USD'))
    end

    it 'subclass can define extra money columns' do
      expect(MoneyClassInheritance.instance_variable_get(:@money_column_options).keys).to include('prix')
      expect(MoneyClassInheritance.instance_variable_get(:@money_column_options).keys).to_not include('price_usd')
      expect(MoneyClassInheritance.new(prix: Money.new(1, 'USD')).prix).to eq(Money.new(1, 'USD'))
    end

    it 'subclass can redefine money columns from parent' do
      expect(MoneyClassInheritance2.instance_variable_get(:@money_column_options).dig('price', :currency)).to eq('CAD')
      expect(MoneyClassInheritance2.instance_variable_get(:@money_column_options).dig('price', :currency_column)).to eq(nil)
      expect(MoneyClassInheritance2.instance_variable_get(:@money_column_options).keys).to_not include('prix')
    end
  end

  describe 'default_currency = nil' do
    around do |example|
      default_currency = Money.default_currency
      Money.default_currency = nil
      example.run
      Money.default_currency = default_currency
    end

    it 'writes currency from input value to the db' do
      record.update(currency: nil)
      record.update(price: Money.new(7, 'GBP'))
      record.reload
      expect(record.price.value).to eq(7)
      expect(record.price.currency.to_s).to eq('GBP')
    end

    it 'raises missing currency error when input is not a money object' do
      record.update(currency: nil)

      expect { record.update(price: 3) }
        .to raise_error(ArgumentError, 'missing currency')
    end
  end
end
