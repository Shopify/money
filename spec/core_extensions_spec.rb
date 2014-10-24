require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

shared_examples_for "an object supporting to_money" do
  it "should support to_money" do
    @value.to_money.should == @money
  end
end

describe Integer do
  before(:each) do
    @value = 1
    @money = Money.new(100)
  end

  it_should_behave_like "an object supporting to_money"
end

describe Float do
  before(:each) do
    @value = 1.23
    @money = Money.new(123)
  end

  it_should_behave_like "an object supporting to_money"
end

describe String do
  before(:each) do
    @value = "1.23"
    @money = Money.new(123)
  end

  it_should_behave_like "an object supporting to_money"
end

describe BigDecimal do
  before(:each) do
    @value = BigDecimal.new('1.23')
    @money = Money.new(123)
  end

  it_should_behave_like "an object supporting to_money"
end
