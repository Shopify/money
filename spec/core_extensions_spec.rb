require 'spec_helper'

RSpec.shared_examples_for "an object supporting to_money" do
  it "supports to_money" do
    expect(@value.to_money('CAD')).to eq(Money.new(@value, 'CAD'))
  end

  it "supports to_money without a currency [DEPRECATED]" do
    expect(Money).to receive(:deprecate).once
    expect(@value.to_money).to eq(@money)
  end
end

RSpec.describe Integer do
  before(:each) do
    @value = 1
    @money = Money.new("1.00")
  end

  it_should_behave_like "an object supporting to_money"
end

RSpec.describe Float do
  before(:each) do
    @value = 1.23
    @money = Money.new("1.23")
  end

  it_should_behave_like "an object supporting to_money"
end

RSpec.describe String do
  before(:each) do
    @value = "1.23"
    @money = Money.new(@value)
  end

  it_should_behave_like "an object supporting to_money"
end

RSpec.describe BigDecimal do
  before(:each) do
    @value = BigDecimal("1.23")
    @money = Money.new("1.23")
  end

  it_should_behave_like "an object supporting to_money"
end
