# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "Allocator" do
  describe "allocate"do
    specify "#allocate takes no action when one gets all" do
      expect(new_allocator(5).allocate([1])).to eq([Money.new(5)])
    end

    specify "#allocate does not lose pennies" do
      moneys = new_allocator(0.05).allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(0.02))
      expect(moneys[1]).to eq(Money.new(0.03))
    end

    specify "#allocate does not lose dollars with non-decimal currency" do
      moneys = new_allocator(5, 'JPY').allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(2, 'JPY'))
      expect(moneys[1]).to eq(Money.new(3, 'JPY'))
    end

    specify "#allocate does not lose dollars with three decimal currency" do
      moneys = new_allocator(0.005, 'JOD').allocate([0.3,0.7])
      expect(moneys[0]).to eq(Money.new(0.002, 'JOD'))
      expect(moneys[1]).to eq(Money.new(0.003, 'JOD'))
    end

    specify "#allocate does not lose pennies even when given a lossy split" do
      moneys = new_allocator(1).allocate([0.333,0.333, 0.333])
      expect(moneys[0].subunits).to eq(34)
      expect(moneys[1].subunits).to eq(33)
      expect(moneys[2].subunits).to eq(33)
    end

    specify "#allocate requires total to be less than 1" do
      expect { new_allocator(0.05).allocate([0.5,0.6]) }.to raise_error(ArgumentError)
    end

    specify "#allocate will use rationals if provided" do
      splits = [128400,20439,14589,14589,25936].map{ |num| Rational(num, 203953) } # sums to > 1 if converted to float
      expect(new_allocator(2.25).allocate(splits)).to eq([Money.new(1.42), Money.new(0.23), Money.new(0.16),
Money.new(0.16), Money.new(0.28)])
    end

    specify "#allocate will convert rationals with high precision" do
      ratios = [Rational(1, 1), Rational(0)]
      expect(new_allocator("858993456.12").allocate(ratios)).to eq([Money.new("858993456.12"),
Money.new(0, Money::NULL_CURRENCY)])
      ratios = [Rational(1, 6), Rational(5, 6)]
      expect(new_allocator("3.00").allocate(ratios)).to eq([Money.new("0.50"), Money.new("2.50")])
    end

    specify "#allocate doesn't raise with weird negative rational ratios" do
      rate = Rational(-5, 1201)
      expect { new_allocator(1).allocate([rate, 1 - rate]) }.not_to raise_error
    end

    specify "#allocate fills pennies from beginning to end with roundrobin strategy" do
      moneys = new_allocator(0.05).allocate([0.3,0.7], :roundrobin)
      expect(moneys[0]).to eq(Money.new(0.02))
      expect(moneys[1]).to eq(Money.new(0.03))
    end

    specify "#allocate fills pennies from end to beginning with roundrobin_reverse strategy" do
      moneys = new_allocator(0.05).allocate([0.3,0.7], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(0.01))
      expect(moneys[1]).to eq(Money.new(0.04))
    end

    specify "#allocate raise ArgumentError when invalid strategy is provided" do
      expect {
 new_allocator(0.03).allocate([0.5, 0.5],
:bad_strategy_name) }.to raise_error(ArgumentError, "Invalid strategy. Valid options: :roundrobin, :roundrobin_reverse")
    end

    specify "#allocate does not raise ArgumentError when invalid splits types are provided" do
      moneys = new_allocator(0.03).allocate([0.5, 0.5], :roundrobin)
      expect(moneys[0]).to eq(Money.new(0.02))
      expect(moneys[1]).to eq(Money.new(0.01))
    end
  end

  describe 'allocate_max_amounts' do
    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room " \
    "for the remainder" do
      expect(
        new_allocator(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)]),
      ).to eq([Money.new(26), Money.new(4.75)])
    end

    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room " \
    "for the remainder with currency" do
      expect(
        new_allocator(3075, 'JPY').allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
    end

    specify "#allocate_max_amounts legal computation with no currency objects" do
      expect(
        new_allocator(3075, 'JPY').allocate_max_amounts([2600, 475]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])

      expect(
        new_allocator(3075, Money::NULL_CURRENCY).allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')]),
      ).to eq([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
    end

    specify "#allocate_max_amounts illegal computation across currencies" do
      expect {
        new_allocator(3075, 'USD').allocate_max_amounts([Money.new(2600, 'JPY'), Money.new(475, 'JPY')])
      }.to raise_error(ArgumentError)
    end

    specify "#allocate_max_amounts drops the remainder when returning the weighted allocation without exceeding the " \
    "maxima when there is no room for the remainder" do
      expect(
        new_allocator(30.75).allocate_max_amounts([Money.new(26), Money.new(4.74)]),
      ).to eq([Money.new(26), Money.new(4.74)])
    end

    specify "#allocate_max_amounts returns the weighted allocation when there is no remainder" do
      expect(
        new_allocator(30).allocate_max_amounts([Money.new(15), Money.new(15)]),
      ).to eq([Money.new(15), Money.new(15)])
    end

    specify "#allocate_max_amounts allocates the remainder round-robin when the maxima are not reached" do
      expect(
        new_allocator(1).allocate_max_amounts([Money.new(33), Money.new(33), Money.new(33)]),
      ).to eq([Money.new(0.34), Money.new(0.33), Money.new(0.33)])
    end

    specify "#allocate_max_amounts allocates up to the maxima specified" do
      expect(
        new_allocator(100).allocate_max_amounts([Money.new(5), Money.new(2)]),
      ).to eq([Money.new(5), Money.new(2)])
    end

    specify "#allocate_max_amounts supports all-zero maxima" do
      expect(
        new_allocator(3).allocate_max_amounts([Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY),
Money.new(0, Money::NULL_CURRENCY)]),
      ).to eq([Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY),
Money.new(0, Money::NULL_CURRENCY)])
    end

    specify "#allocate_max_amounts allocates the right amount without rounding error" do
      expect(
        new_allocator(24.2).allocate_max_amounts([Money.new(46), Money.new(46), Money.new(50), Money.new(50),
Money.new(50)]),
        ).to eq([Money.new(4.6), Money.new(4.6), Money.new(5), Money.new(5), Money.new(5)])
    end
  end

  def new_allocator(amount, currency = nil)
    Money::Allocator.new(Money.new(amount, currency))
  end
end
