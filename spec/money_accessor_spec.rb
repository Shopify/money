require 'spec_helper'

class NormalObject
  include MoneyAccessor

  money_accessor :price

  def initialize(price)
    @price = price
  end
end

class StructObject < Struct.new(:price)
  include MoneyAccessor

  money_accessor :price
end

RSpec.shared_examples_for "an object with a money accessor" do
  it "generates an attribute reader that returns a money object" do
    object = described_class.new(100)

    expect(object.price).to eq(Money.new(100))
  end

  it "generates an attribute reader that returns a nil object if the value was nil" do
    object = described_class.new(nil)

    expect(object.price).to eq(nil)
  end

  it "generates an attribute reader that returns a nil object if the value was blank" do
    object = described_class.new('')

    expect(object.price).to eq(nil)
  end

  it "generates an attribute writer that allow setting a money object" do
    object = described_class.new(0)
    object.price = Money.new(10)

    expect(object.price).to eq(Money.new(10))
  end

  it "generates an attribute writer that allow setting a integer value" do
    object = described_class.new(0)
    object.price = 10

    expect(object.price).to eq(Money.new(10))
  end

  it "generates an attribute writer that allow setting a float value" do
    object = described_class.new(0)
    object.price = 10.12

    expect(object.price).to eq(Money.new(10.12))
  end

  it "generates an attribute writer that allow setting a nil value" do
    object = described_class.new(0)
    object.price = nil

    expect(object.price).to eq(nil)
  end

  it "generates an attribute writer that allow setting a blank value" do
    object = described_class.new(0)
    object.price = ''

    expect(object.price).to eq(nil)
  end
end

RSpec.describe NormalObject do
  it_behaves_like "an object with a money accessor"

  it 'preserves the currency value when passed to money_accessor' do
    object = described_class.new(Money.new(10, 'USD'))
    currency = Money::Currency.new('USD')
    expect(object.price.currency).to eq(currency)
  end
end

RSpec.describe StructObject do
  it_behaves_like "an object with a money accessor"

  it 'does not generate an ivar to store the price value' do
    object = described_class.new(10.00)

    expect(object.instance_variable_get(:@price)).to eq(nil)
  end
end
