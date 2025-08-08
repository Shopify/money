# frozen_string_literal: true
require 'spec_helper'

class MoneyRecord < ActiveRecord::Base
  RATE = 1.17
  before_validation do
    self.price_usd = Money.new(self["price"] * RATE, 'USD') if self["price"]
  end
  money_column :price, currency_column: 'price_currency'
  money_column :prix, currency_column: :prix_currency
  money_column :price_usd, currency: 'USD'
end

class MoneyWithValidation < ActiveRecord::Base
  self.table_name = 'money_records'
  validates :price, :price_currency, presence: true
  money_column :price, currency_column: 'price_currency'
end

class MoneyWithReadOnlyCurrency < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'price_currency', currency_read_only: true
end

class MoneyRecordCoerceNull < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'price_currency', coerce_null: true
  money_column :price_usd, currency: 'USD', coerce_null: true
end

class MoneyWithDelegatedCurrency < ActiveRecord::Base
  self.table_name = 'money_records'
  delegate :price_currency, to: :delegated_record
  money_column :price, currency_column: 'price_currency', currency_read_only: true
  money_column :prix, currency_column: 'currency2', currency_read_only: true
  def currency2
    delegated_record.price_currency
  end

  private

  def delegated_record
    MoneyRecord.new(price_currency: 'USD')
  end
end

class MoneyWithCustomAccessors < ActiveRecord::Base
  self.table_name = 'money_records'
  money_column :price, currency_column: 'price_currency'
  def price
    read_money_attribute(:price)
  end
  def price=(value)
    write_money_attribute(:price, value + 1)
  end
end

class MoneyClassInheritance < MoneyWithCustomAccessors
  money_column :prix, currency_column: 'price_currency'
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
    subject.prix_currency = 'CAD'
    subject.save
    subject.reload
  end

  it 'returns money with currency from the default column' do
    expect(record.price).to eq(Money.new(1.23, 'EUR'))
  end

  it 'writes the currency to the db' do
    record.update(price_currency: nil)
    record.update(price: Money.new(4, 'JPY'))
    record.reload
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

  describe 'hard-coded currency (currency: "USD")' do
    let(:record) { MoneyRecord.new }

    it 'raises CurrencyMismatchError when assigning Money with wrong currency' do
      expect {
        record.price_usd = Money.new(5, 'EUR')
      }.to raise_error(MoneyColumn::CurrencyMismatchError)
    end

    it 'allows assigning Money with the correct currency' do
      record.price_usd = Money.new(8, 'USD')
      expect(record.price_usd.value).to eq(8)
      expect(record.price_usd.currency.to_s).to eq('USD')
    end

    it 'deprecates (but does not raise) under legacy_deprecations' do
      configure(legacy_deprecations: true) do
        expect(Money).to receive(:deprecate).once
        record.price_usd = Money.new(9, 'EUR')
        expect(record.price_usd.value).to eq(9)
        expect(record.price_usd.currency.to_s).to eq('USD')
      end
    end
  end

  it 'returns money with null currency when the currency in the DB is invalid' do
    configure(legacy_deprecations: true) do
      expect(Money).to receive(:deprecate).once
      record.update_columns(price_currency: 'invalid')
      record.reload
      expect(record.price.currency).to be_a(Money::NullCurrency)
      expect(record.price.value).to eq(1.23)
    end
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

  it 'handles legacy support for saving floats as provided' do
    record.update(price: 3.2112, prix: 3.2156)
    expect(record.attributes['price']).to eq(3.2112)
    expect(record.price.value).to eq(3.21)
    expect(record.price.currency.to_s).to eq(currency)
    expect(record.attributes['prix']).to eq(3.2156)
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
    expect(record.price_currency.to_s).to eq('EUR')
    record.update(price: Money.new(0, Money::NULL_CURRENCY))
    expect(record.price_currency.to_s).to eq('EUR')
  end

  it 'does overwrite a currency' do
    expect(record.price_currency.to_s).to eq('EUR')
    record.update(price: Money.new(4, 'JPY'))
    expect(record.price_currency.to_s).to eq('JPY')
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

    it 'raises an ArgumentError' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  describe 'garbage currency' do
    let(:currency) { 'foo' }

    it 'raises an UnknownCurrency error' do
      expect { subject }.to raise_error(Money::Currency::UnknownCurrency)
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
      expect(subject.errors[:price_currency]).to include("can't be blank")
    end
  end

  describe 'read_only_currency true' do
    it 'raises CurrencyReadOnlyError when updating price with different currency' do
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(price_currency: 'USD')
      expect { record.update(price: Money.new(4, 'CAD')) }.to raise_error(MoneyColumn::CurrencyReadOnlyError)
    end

    it 'raises CurrencyReadOnlyError when assigning money with different currency' do
      record = MoneyWithReadOnlyCurrency.create(price_currency: 'USD', price: 1)
      expect { record.price = Money.new(2, 'CAD') }.to raise_error(MoneyColumn::CurrencyReadOnlyError)
    end

    it 'allows updating price when currency matches existing currency' do
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(price_currency: 'USD')
      record.update(price: Money.new(4, 'USD'))
      expect(record.price.value).to eq(4)
    end

    it 'allows assigning price when currency matches existing currency' do
      record = MoneyWithReadOnlyCurrency.create(price_currency: 'CAD', price: 1)
      record.price = Money.new(2, 'CAD')
      expect(record.price.value).to eq(2)
    end

    it 'legacy_deprecations does not write the currency to the db' do
      configure(legacy_deprecations: true) do
        record = MoneyWithReadOnlyCurrency.create
        record.update_columns(price_currency: 'USD')

        expect(Money).to receive(:deprecate).once
        record.update(price: Money.new(4, 'CAD'))
        expect(record.price.value).to eq(4)
        expect(record.price.currency.to_s).to eq('USD')
      end
    end

    it 'reads the currency that is already in the db' do
      record = MoneyWithReadOnlyCurrency.create
      record.update_columns(price_currency: 'USD', price: 1)
      record.reload
      expect(record.price.value).to eq(1)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'reads an invalid currency from the db and generates a no currency object' do
      configure(legacy_deprecations: true) do
        expect(Money).to receive(:deprecate).once
        record = MoneyWithReadOnlyCurrency.create
        record.update_columns(price_currency: 'invalid', price: 1)
        record.reload
        expect(record.price.value).to eq(1)
        expect(record.price.currency.to_s).to eq('')
      end
    end

    it 'sets the currency correctly when the currency is changed' do
      record = MoneyWithReadOnlyCurrency.create(price_currency: 'CAD', price: 1)
      record.price_currency = 'USD'
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handle cases where the delegate allow_nil is false' do
      record = MoneyWithDelegatedCurrency.new(price: Money.new(10, 'USD'))
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handle cases where a manual delegate does not allow nil' do
      record = MoneyWithDelegatedCurrency.new(prix: Money.new(10, 'USD'))
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
      expect(MoneyClassInheritance.instance_variable_get(:@money_column_options).dig('price', :currency_column)).to eq('price_currency')
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
      configure(default_currency: nil) { example.run }
    end

    it 'writes currency from input value to the db' do
      record.update(price_currency: nil)
      record.update(price: Money.new(7, 'GBP'))
      record.reload
      expect(record.price.value).to eq(7)
      expect(record.price.currency.to_s).to eq('GBP')
    end

    it 'raises missing currency error reading a value that was saved using legacy non-money object' do
      record.update(price_currency: nil, price: 3)
      expect { record.price }.to raise_error(ArgumentError, 'missing currency')
    end

    it 'handles legacy support for saving price and currency separately' do
      record.update(price_currency: nil)
      record.update(price: 7, price_currency: 'GBP')
      record.reload
      expect(record.price.value).to eq(7)
      expect(record.price.currency.to_s).to eq('GBP')
    end
  end

  describe 'updating amount and currency simultaneously' do
    let(:record) { MoneyWithReadOnlyCurrency.create!(price_currency: "CAD") }

    it 'allows updating both amount and currency at the same time' do
      record.update!(
        price: Money.new(10, 'USD'),
        price_currency: 'USD'
      )
      record.reload
      expect(record.price.value).to eq(10)
      expect(record.price.currency.to_s).to eq('USD')
      expect(record.price_currency).to eq('USD')
    end
  end

  describe 'multiple money columns' do
    it 'handles multiple money columns with different currencies' do
      record = MoneyRecord.create!(
        price: Money.new(100, 'USD'),
        prix: Money.new(200, 'EUR'),
        prix_currency: 'EUR'
      )
      record.reload
      expect(record.price.value).to eq(100)
      expect(record.price.currency.to_s).to eq('USD')
      expect(record.prix.value).to eq(200)
      expect(record.prix.currency.to_s).to eq('EUR')
      # price_usd is calculated from price * RATE (1.17) in before_validation
      expect(record.price_usd.value).to eq(117)
      expect(record.price_usd.currency.to_s).to eq('USD')
    end

    it 'maintains separate caches for each money column' do
      record = MoneyRecord.new
      record.price = Money.new(100, 'USD')
      record.prix = Money.new(200, 'EUR')

      expect(record.price).to eq(Money.new(100, 'USD'))
      expect(record.prix).to eq(Money.new(200, 'EUR'))

      # Verify they're independent by changing one
      record.price = Money.new(300, 'CAD')
      expect(record.price).to eq(Money.new(300, 'CAD'))
      expect(record.prix).to eq(Money.new(200, 'EUR'))
    end
  end

  describe 'blank money handling' do
    it 'handles empty string as nil' do
      record = MoneyRecord.new(price: '')
      expect(record.price).to be_nil
    end

    it 'handles whitespace string as nil' do
      record = MoneyRecord.new(price: '   ')
      expect(record.price).to be_nil
    end

    it 'clears cache when setting to blank' do
      record = MoneyRecord.new(price: Money.new(100, 'USD'))
      expect(record.price).to eq(Money.new(100, 'USD'))

      record.price = ''
      expect(record.price).to be_nil

      # Verify the cache was cleared by setting a new value
      record.price = Money.new(200, 'EUR')
      expect(record.price).to eq(Money.new(200, 'EUR'))
    end
  end

  describe 'currency column cache clearing' do
    it 'clears all money column caches when currency changes' do
      record = MoneyRecord.new(
        price: Money.new(100, 'USD'),
        price_currency: 'USD'
      )

      expect(record.price).to eq(Money.new(100, 'USD'))

      # Change currency should invalidate the cache
      record.price_currency = 'EUR'
      expect(record.price.currency.to_s).to eq('EUR')
    end

    it 'only defines currency setter once for shared currency columns' do
      class MoneyWithSharedCurrency < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency_column: 'price_currency'
        money_column :prix, currency_column: 'price_currency'
      end

      record = MoneyWithSharedCurrency.new
      methods_count = record.methods.count { |m| m.to_s == 'price_currency=' }
      expect(methods_count).to eq(1)
    end
  end

  describe 'no_currency handling' do
    it 'does not write currency when money has no_currency' do
      record = MoneyRecord.create!(price_currency: 'USD')
      record.price = Money.new(100, Money::NULL_CURRENCY)
      record.save!
      record.reload
      expect(record.price_currency).to eq('USD')
    end
  end

  describe 'edge cases' do
    it 'handles BigDecimal values' do
      record = MoneyRecord.new(price: BigDecimal('123.45'))
      expect(record.price.value).to eq(123.45)
    end

    it 'handles negative values' do
      record = MoneyRecord.new(price: Money.new(-100, 'USD'))
      record.save!
      record.reload
      expect(record.price.value).to eq(-100)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handles very large values' do
      large_value = BigDecimal('999999999999999.999')
      record = MoneyRecord.new(price: Money.new(large_value, 'USD'))
      record.save!
      record.reload
      # Database might round very large values
      expect(record.price.value).to be_within(0.001).of(large_value)
    end

    it 'handles zero values' do
      record = MoneyRecord.new(price: Money.new(0, 'USD'))
      record.save!
      record.reload
      expect(record.price.value).to eq(0)
      expect(record.price.currency.to_s).to eq('USD')
    end
  end

  describe 'ActiveRecord callbacks integration' do
    class MoneyWithCallbacks < ActiveRecord::Base
      self.table_name = 'money_records'
      money_column :price, currency_column: 'price_currency'

      before_save :double_price

      private

      def double_price
        self.price = price * 2 if price
      end
    end

    it 'works with before_save callbacks' do
      record = MoneyWithCallbacks.new(price: Money.new(50, 'USD'))
      record.save!
      expect(record.price.value).to eq(100)
    end
  end

  describe 'validation integration' do
    class MoneyWithCustomValidation < ActiveRecord::Base
      self.table_name = 'money_records'
      money_column :price, currency_column: 'price_currency'

      validate :price_must_be_positive

      private

      def price_must_be_positive
        errors.add(:price, 'must be positive') if price && price.value < 0
      end
    end

    it 'works with custom validations' do
      record = MoneyWithCustomValidation.new(price: Money.new(-10, 'USD'))
      expect(record).not_to be_valid
      expect(record.errors[:price]).to include('must be positive')
    end

    it 'allows valid values' do
      record = MoneyWithCustomValidation.new(price: Money.new(10, 'USD'))
      expect(record).to be_valid
    end
  end

  describe 'ActiveRecord query interface' do
    before do
      MoneyRecord.delete_all
      MoneyRecord.create!(price: Money.new(100, 'USD'), price_currency: 'USD')
      MoneyRecord.create!(price: Money.new(200, 'USD'), price_currency: 'USD')
      MoneyRecord.create!(price: Money.new(150, 'EUR'), price_currency: 'EUR')
    end

    it 'supports where queries with money values' do
      records = MoneyRecord.where(price: 100)
      expect(records.count).to eq(1)
      expect(records.first.price.value).to eq(100)
    end

    it 'supports range queries' do
      records = MoneyRecord.where(price: 100..200)
      expect(records.count).to eq(3)
    end

    it 'supports ordering by money columns' do
      records = MoneyRecord.order(:price)
      expect(records.map { |r| r.price.value }).to eq([100, 150, 200])
    end

    it 'supports pluck with money columns' do
      values = MoneyRecord.pluck(:price)
      expect(values).to contain_exactly(100, 200, 150)
    end
  end

  describe 'thread safety' do
    it 'maintains separate caches per instance' do
      record1 = MoneyRecord.new
      record2 = MoneyRecord.new

      record1.price = Money.new(100, 'USD')
      record2.price = Money.new(200, 'EUR')

      expect(record1.price).to eq(Money.new(100, 'USD'))
      expect(record2.price).to eq(Money.new(200, 'EUR'))
    end
  end

  describe 'attribute assignment' do
    it 'handles hash assignment with string keys' do
      record = MoneyRecord.new('price' => 100, 'price_currency' => 'USD')
      expect(record.price.value).to eq(100)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handles hash assignment with symbol keys' do
      record = MoneyRecord.new(price: 100, price_currency: 'USD')
      expect(record.price.value).to eq(100)
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'handles update_attributes' do
      record = MoneyRecord.create!(price: Money.new(100, 'USD'))
      record.update!(price: Money.new(200, 'EUR'))
      expect(record.price.value).to eq(200)
      expect(record.price.currency.to_s).to eq('EUR')
    end
  end

  describe 'error handling' do
    it 'provides helpful error message for invalid currency in money object' do
      expect {
        MoneyRecord.new(price: Money.new(100, 'INVALID'))
      }.to raise_error(Money::Currency::UnknownCurrency)
    end

    it 'handles non-numeric string values' do
      expect {
        MoneyRecord.new(price: 'not a number')
      }.to raise_error(ArgumentError)
    end
  end

  describe 'coerce_null with different scenarios' do
    it 'coerces nil to zero money with proper currency from column' do
      record = MoneyRecordCoerceNull.new(price_currency: 'EUR')
      expect(record.price.value).to eq(0)
      expect(record.price.currency.to_s).to eq('EUR')
    end

    it 'coerces nil to zero money with hardcoded currency' do
      record = MoneyRecordCoerceNull.new
      expect(record.price_usd.value).to eq(0)
      expect(record.price_usd.currency.to_s).to eq('USD')
    end

    it 'does not coerce non-nil values' do
      record = MoneyRecordCoerceNull.new(price: Money.new(100, 'USD'))
      expect(record.price.value).to eq(100)
    end
  end

  describe 'currency_read_only with edge cases' do
    it 'allows setting money when currency column is nil' do
      record = MoneyWithReadOnlyCurrency.new
      record.price = Money.new(100, 'USD')
      expect(record.price.value).to eq(100)
      # Currency is not written for read_only columns when not saved
      expect(record.price_currency).to be_nil
    end

    it 'allows setting money with compatible currency using string' do
      record = MoneyWithReadOnlyCurrency.create!(price_currency: 'USD')
      record.price = Money.new(100, 'USD')
      expect(record.price.value).to eq(100)
    end
  end

  describe 'initialize_dup behavior' do
    it 'creates independent cache for duplicated record' do
      original = MoneyRecord.new(price: Money.new(100, 'USD'))
      duplicate = original.dup

      duplicate.price = Money.new(200, 'EUR')

      expect(original.price).to eq(Money.new(100, 'USD'))
      expect(duplicate.price).to eq(Money.new(200, 'EUR'))
    end

    it 'preserves money values when duplicating' do
      original = MoneyRecord.create!(
        price: Money.new(100, 'USD'),
        prix: Money.new(200, 'EUR')
      )

      duplicate = original.dup
      expect(duplicate.price).to eq(Money.new(100, 'USD'))
      expect(duplicate.prix).to eq(Money.new(200, 'EUR'))
      expect(duplicate).to be_new_record
    end
  end

  describe 'ActiveRecord dirty tracking' do
    it 'tracks changes to money columns' do
      record = MoneyRecord.create!(price: Money.new(100, 'USD'))
      record.price = Money.new(200, 'USD')

      expect(record.price_changed?).to be true
      expect(record.price_was).to eq(100)
      expect(record.price_change).to eq([100, 200])
    end

    it 'tracks currency changes' do
      record = MoneyRecord.create!(price_currency: 'USD', price: 100)
      record.price_currency = 'EUR'

      expect(record.price_currency_changed?).to be true
      expect(record.price_currency_was).to eq('USD')
    end
  end

  describe 'mass assignment with currency updates' do
    it 'handles simultaneous updates of money and currency in mass assignment' do
      record = MoneyWithReadOnlyCurrency.create!(price_currency: 'USD', price: 100)

      record.assign_attributes(
        price_currency: 'EUR',
        price: Money.new(200, 'EUR')
      )

      expect { record.save! }.not_to raise_error
      expect(record.price.value).to eq(200)
      expect(record.price_currency).to eq('EUR')
    end
  end

  describe 'decimal precision handling' do
    it 'preserves precision up to currency minor units' do
      # USD has 2 minor units, so 123.456 will be rounded to 123.46
      record = MoneyRecord.create!(price: Money.new(123.456, 'USD'))
      record.reload
      expect(record.price.value.to_f).to eq(123.46)
    end

    it 'preserves full precision for currencies with 3 decimal places' do
      # JOD has 3 minor units, so it preserves 3 decimal places
      record = MoneyRecord.create!(price: Money.new(123.456, 'JOD'), price_currency: 'JOD')
      record.reload
      expect(record.price.value).to eq(123.456)
    end

    it 'rounds database values beyond 3 decimal places' do
      record = MoneyRecord.new
      record['price'] = 123.4567
      record.price_currency = 'USD'
      record.save!
      record.reload
      expect(record['price'].to_f.round(3)).to eq(123.457)
    end
  end

  describe 'ActiveRecord Type integration' do
    it 'uses MoneyColumn::ActiveRecordType for money columns' do
      type = MoneyRecord.attribute_types['price']
      expect(type).to be_a(MoneyColumn::ActiveRecordType)
    end
  end

  describe 'money column options inheritance' do
    it 'does not share options between different models' do
      class MoneyModel1 < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency_column: 'currency'
      end

      class MoneyModel2 < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency: 'EUR'
      end

      expect(MoneyModel1.money_column_options['price'][:currency_column]).to eq('currency')
      expect(MoneyModel1.money_column_options['price'][:currency]).to be_nil

      expect(MoneyModel2.money_column_options['price'][:currency]).to eq('EUR')
      expect(MoneyModel2.money_column_options['price'][:currency_column]).to be_nil
    end
  end

  describe 'raw attributes access' do
    it 'allows direct access to raw decimal value' do
      record = MoneyRecord.create!(price: Money.new(123.45, 'USD'))
      expect(record['price']).to eq(123.45)
      expect(record.read_attribute(:price)).to eq(123.45)
    end

    it 'allows direct writing of raw decimal value' do
      record = MoneyRecord.new
      record['price'] = 99.99
      record.price_currency = 'EUR'
      expect(record.price.value).to eq(99.99)
      expect(record.price.currency.to_s).to eq('EUR')
    end
  end

  describe 'nil handling' do
    it 'returns Money with default currency for zero values' do
      record = MoneyRecord.new
      # The default value in the schema is 0.000, not nil
      expect(record['price']).to eq(0)
      # With default currency CAD, it returns Money with 0 value
      expect(record.price).to eq(Money.new(0, 'CAD'))
    end

    it 'returns nil when value is explicitly nil' do
      record = MoneyRecord.new
      record['price'] = nil
      expect(record.price).to be_nil
    end

    it 'handles nil assignment' do
      record = MoneyRecord.create!(price: Money.new(100, 'USD'))
      record.price = nil
      record.save!
      record.reload
      expect(record.price).to be_nil
    end
  end

  describe 'currency normalization' do
    it 'normalizes currency strings to uppercase' do
      record = MoneyRecord.new(price: Money.new(100, 'usd'))
      expect(record.price.currency.to_s).to eq('USD')
    end

    it 'freezes currency strings for performance' do
      class MoneyWithFrozenCurrency < ActiveRecord::Base
        self.table_name = 'money_records'
        money_column :price, currency: 'USD'
      end

      expect(MoneyWithFrozenCurrency.money_column_options['price'][:currency]).to be_frozen
    end
  end

  describe 'error messages' do
    it 'provides clear error for missing currency when default_currency is nil' do
      configure(default_currency: nil) do
        record = MoneyRecord.create!(price: 100, price_currency: nil)
        expect { record.reload.price }.to raise_error(ArgumentError, 'missing currency')
      end
    end
  end

  describe 'money column with different column names' do
    class MoneyWithCustomColumns < ActiveRecord::Base
      self.table_name = 'money_records'
      money_column :price, currency_column: :prix_currency
      money_column :prix, currency_column: 'price_currency'
    end

    it 'supports both string and symbol currency column names' do
      record = MoneyWithCustomColumns.new(
        price: Money.new(100, 'EUR'),
        prix_currency: 'EUR',
        prix: Money.new(200, 'USD'),
        price_currency: 'USD'
      )

      expect(record.price.currency.to_s).to eq('EUR')
      expect(record.prix.currency.to_s).to eq('USD')
    end
  end

  describe 'money column array syntax' do
    class MoneyWithArrayColumns < ActiveRecord::Base
      self.table_name = 'money_records'
      money_column [:price, :prix], currency_column: 'price_currency'
    end

    it 'supports defining multiple columns at once' do
      record = MoneyWithArrayColumns.new(
        price: Money.new(100, 'USD'),
        prix: Money.new(200, 'USD'),
        price_currency: 'USD'
      )

      expect(record.price).to eq(Money.new(100, 'USD'))
      expect(record.prix).to eq(Money.new(200, 'USD'))
    end
  end

  describe 'ActiveRecord scopes' do
    it 'works with ActiveRecord scopes' do
      MoneyRecord.delete_all
      cheap = MoneyRecord.create!(price: Money.new(10, 'USD'))
      expensive = MoneyRecord.create!(price: Money.new(100, 'USD'))

      scope = MoneyRecord.where('price < ?', 50)
      expect(scope.to_a).to eq([cheap])
    end
  end

  describe 'JSON serialization' do
    it 'includes money values in as_json' do
      record = MoneyRecord.new(price: Money.new(100, 'USD'))
      json = record.as_json
      # Money columns are serialized as a hash with symbol keys
      expect(json['price']).to eq({ currency: 'USD', value: '100.00' })
      expect(json['price_currency']).to eq('USD')
    end
  end

  describe 'update_columns behavior' do
    it 'bypasses money column methods when using update_columns' do
      record = MoneyRecord.create!(price: Money.new(100, 'USD'))
      record.update_columns(price: 200)
      record.reload
      expect(record.price.value).to eq(200)
      expect(record.price.currency.to_s).to eq('USD')
    end
  end
end
