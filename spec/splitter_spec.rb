# frozen_string_literal: true
require 'spec_helper'
require 'yaml'

RSpec.describe "Money::Splitter" do
  specify "#split needs at least one party" do
    expect {Money.new(1).split(0)}.to raise_error(ArgumentError)
    expect {Money.new(1).split(-1)}.to raise_error(ArgumentError)
    expect {Money.new(1).split(0.1)}.to raise_error(ArgumentError)
    expect(Money.new(1).split(BigDecimal("0.1e1")).to_a).to eq([Money.new(1)])
  end

  specify "#split can be zipped" do
    expect(Money.new(100).split(3).zip(Money.new(50).split(3)).to_a).to eq([
      [Money.new(33.34), Money.new(16.67)],
      [Money.new(33.33), Money.new(16.67)],
      [Money.new(33.33), Money.new(16.66)],
    ])
  end

  specify "#gives 1 cent to both people if we start with 2" do
    expect(Money.new(0.02).split(2).to_a).to eq([Money.new(0.01), Money.new(0.01)])
  end

  specify "#split may distribute no money to some parties if there isnt enough to go around" do
    expect(Money.new(0.02).split(3).to_a).to eq([Money.new(0.01), Money.new(0.01), Money.new(0)])
  end

  specify "#split does not lose pennies" do
    expect(Money.new(0.05).split(2).to_a).to eq([Money.new(0.03), Money.new(0.02)])
  end

  specify "#split does not lose dollars with non-decimal currencies" do
    expect(Money.new(5, 'JPY').split(2).to_a).to eq([Money.new(3, 'JPY'), Money.new(2, 'JPY')])
  end

  specify "#split a dollar" do
    moneys = Money.new(1).split(3)
    expect(moneys[0].subunits).to eq(34)
    expect(moneys[1].subunits).to eq(33)
    expect(moneys[2].subunits).to eq(33)
  end

  specify "#split a 100 yen" do
    moneys = Money.new(100, 'JPY').split(3)
    expect(moneys[0].value).to eq(34)
    expect(moneys[1].value).to eq(33)
    expect(moneys[2].value).to eq(33)
  end

  specify "#split return respond to #first" do
    expect(Money.new(100).split(3).first).to eq(Money.new(33.34))
    expect(Money.new(100).split(3).first(2)).to eq([Money.new(33.34), Money.new(33.33)])

    expect(Money.new(100).split(10).first).to eq(Money.new(10))
    expect(Money.new(100).split(10).first(2)).to eq([Money.new(10), Money.new(10)])
    expect(Money.new(20).split(2).first(4)).to eq([Money.new(10), Money.new(10)])
  end

  specify "#split return respond to #last" do
    expect(Money.new(100).split(3).last).to eq(Money.new(33.33))
    expect(Money.new(100).split(3).last(2)).to eq([Money.new(33.33), Money.new(33.33)])
    expect(Money.new(20).split(2).last(4)).to eq([Money.new(10), Money.new(10)])
  end

  specify "#split return supports destructuring" do
    first, second = Money.new(100).split(3)
    expect(first).to eq(Money.new(33.34))
    expect(second).to eq(Money.new(33.33))

    first, *rest = Money.new(100).split(3)
    expect(first).to eq(Money.new(33.34))
    expect(rest).to eq([Money.new(33.33), Money.new(33.33)])
  end

  specify "#split return can be reversed" do
    list = Money.new(100).split(3)
    expect(list.first).to eq(Money.new(33.34))
    expect(list.last).to eq(Money.new(33.33))

    list = list.reverse
    expect(list.first).to eq(Money.new(33.33))
    expect(list.last).to eq(Money.new(33.34))
  end

  describe "calculate_splits" do
    specify "#calculate_splits gives 1 cent to both people if we start with 2" do
      actual = Money.new(0.02, 'CAD').calculate_splits(2)

      expect(actual).to eq({
        Money.new(0.01, 'CAD') => 2,
      })
    end

    specify "#calculate_splits gives an extra penny to one" do
      actual = Money.new(0.04, 'CAD').calculate_splits(3)

      expect(actual).to eq({
        Money.new(0.02, 'CAD') => 1,
        Money.new(0.01, 'CAD') => 2,
      })
    end
  end
end
