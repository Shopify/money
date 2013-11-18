require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class MoneyRecord < ActiveRecord::Base
  money_column :price
end

describe "MoneyColumn" do

  it "should typecast string to money" do
    m = MoneyRecord.new(:price => "100")

    m.price.should == Money.new(100)
  end

  it "should typecast numeric to money" do
    m = MoneyRecord.new(:price => 100)

    m.price.should == Money.new(100)
  end

  it "should typecast blank to nil" do
    m = MoneyRecord.new(:price => "")

    m.price.should == nil
  end

  it "should typecast invalid string to empty money" do
    m = MoneyRecord.new(:price => "magic")

    m.price.should == Money.new(0)
  end
end
