require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class NormalObject
  include MoneyAccessor

  money_accessor :price

  def initialize(price)
    @price = price
  end
end

describe NormalObject do
  before(:each) do 
    @object = Object.new
    @money = Money.new("1.00")
  end

  it "generates an attribute reader that returns a money object" do
    object = NormalObject.new(100)

    expect(object.price).to eq(Money.new(100))
  end

  it "generates an attribute reader that returns a nil object if the value was nil" do
    object = NormalObject.new(nil)

    expect(object.price).to eq(nil)
  end

  it "generates an attribute reader that returns a nil object if the value was blank" do
    object = NormalObject.new('')

    expect(object.price).to eq(nil)
  end

  it "generates an attribute writer that allow setting a money object" do
    object = NormalObject.new(0)
    object.price = Money.new(10)

    expect(object.price).to eq(Money.new(10))
  end

  it "generates an attribute writer that allow setting a integer value" do
    object = NormalObject.new(0)
    object.price = 10

    expect(object.price).to eq(Money.new(10))
  end

  it "generates an attribute writer that allow setting a float value" do
    object = NormalObject.new(0)
    object.price = 10.12

    expect(object.price).to eq(Money.new(10.12))
  end

  it "generates an attribute writer that allow setting a nil value" do
    object = NormalObject.new(0)
    object.price = nil

    expect(object.price).to eq(nil)
  end

  it "generates an attribute writer that allow setting a blank value" do
    object = NormalObject.new(0)
    object.price = ''

    expect(object.price).to eq(nil)
  end
end
