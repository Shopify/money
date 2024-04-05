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
      expect(new_allocator(2.25).allocate(splits)).to eq([Money.new(1.42), Money.new(0.23), Money.new(0.16), Money.new(0.16), Money.new(0.28)])
    end

    specify "#allocate will convert rationals with high precision" do
      ratios = [Rational(1, 1), Rational(0)]
      expect(new_allocator("858993456.12").allocate(ratios)).to eq([Money.new("858993456.12"), Money.new(0, Money::NULL_CURRENCY)])
      ratios = [Rational(1, 6), Rational(5, 6)]
      expect(new_allocator("3.00").allocate(ratios)).to eq([Money.new("0.50"), Money.new("2.50")])
    end

    specify "#allocate doesn't raise with weird negative rational ratios" do
      rate = Rational(-5, 1201)
      expect { new_allocator(1).allocate([rate, 1 - rate]) }.not_to raise_error
    end

    specify "#allocate raise ArgumentError when invalid strategy is provided" do
      expect { new_allocator(0.03).allocate([0.5, 0.5], :bad_strategy_name) }.to raise_error(ArgumentError, "Invalid strategy. Valid options: :roundrobin, :roundrobin_reverse, :nearest")
    end

    specify "#allocate raises an error when splits exceed 100%" do
      expect { new_allocator(0.03).allocate([0.5, 0.6]) }.to raise_error(ArgumentError, "splits add to more than 100%")
    end

    specify "#allocate scales up allocations less than 100%, preserving the relative magnitude of each chunk" do
      # Allocations sum to 0.3
      # This is analogous to new_allocator(12).allocate([1/3, 2/3])
      moneys = new_allocator(12).allocate([0.1, 0.2])
      expect(moneys[0]).to eq(Money.new(4))
      expect(moneys[1]).to eq(Money.new(8))

      # Allocations sum to .661
      moneys = new_allocator(488.51).allocate([0.111, 0.05, 0.5])
      expect(moneys[0]).to eq(Money.new(82.04)) # <-- leftover penny
      expect(moneys[1]).to eq(Money.new(36.95))
      expect(moneys[2]).to eq(Money.new(369.52))

      moneys = new_allocator(488.51).allocate([0.111, 0.05, 0.5], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(82.03))
      expect(moneys[1]).to eq(Money.new(36.95))
      expect(moneys[2]).to eq(Money.new(369.53)) # <-- leftover penny

      moneys = new_allocator(488.51).allocate([0.05, 0.111, 0.5], :nearest)
      expect(moneys[0]).to eq(Money.new(36.95))
      expect(moneys[1]).to eq(Money.new(82.04)) # <-- leftover penny
      expect(moneys[2]).to eq(Money.new(369.52))
    end

    specify "#allocate fills pennies from beginning to end with roundrobin strategy" do
      #round robin for 1 penny
      moneys = new_allocator(0.03).allocate([0.5, 0.5], :roundrobin)
      expect(moneys[0]).to eq(Money.new(0.02)) # <-- gets 1 penny
      expect(moneys[1]).to eq(Money.new(0.01)) # <-- gets no penny

      #round robin for 2 pennies
      moneys = new_allocator(10.55).allocate([0.25, 0.5, 0.25], :roundrobin)
      expect(moneys[0]).to eq(Money.new(2.64)) # <-- gets 1 penny
      expect(moneys[1]).to eq(Money.new(5.28)) # <-- gets 1 penny
      expect(moneys[2]).to eq(Money.new(2.63)) # <-- gets no penny

      #round robin for 3 pennies
      moneys = new_allocator(195.35).allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :roundrobin)
      expect(moneys[0]).to eq(Money.new(4.89)) # <-- gets 1 penny
      expect(moneys[1]).to eq(Money.new(4.89)) # <-- gets 1 penny
      expect(moneys[2]).to eq(Money.new(24.42)) # <-- gets 1 penny
      expect(moneys[3]).to eq(Money.new(24.41)) # <-- gets no penny
      expect(moneys[4]).to eq(Money.new(78.14)) # <-- gets no penny
      expect(moneys[5]).to eq(Money.new(58.60)) # <-- gets no penny

      #round robin for 0 pennies
      moneys = new_allocator(101).allocate([0.25, 0.25, 0.25, 0.25], :roundrobin)
      expect(moneys[0]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[1]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[2]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[3]).to eq(Money.new(25.25)) # <-- gets no penny
    end

    specify "#allocate fills pennies from end to beginning with roundrobin_reverse strategy" do
      #round robin reverse for 1 penny
      moneys = new_allocator(0.05).allocate([0.3,0.7], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(0.01)) # <-- gets no penny
      expect(moneys[1]).to eq(Money.new(0.04)) # <-- gets 1 penny

      #round robin reverse for 2 pennies
      moneys = new_allocator(10.55).allocate([0.25, 0.5, 0.25], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(2.63)) # <-- gets no penny
      expect(moneys[1]).to eq(Money.new(5.28)) # <-- gets 1 penny
      expect(moneys[2]).to eq(Money.new(2.64)) # <-- gets 1 penny

      #round robin reverse for 3 pennies
      moneys = new_allocator(195.35).allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(4.88)) #  <-- gets no penny
      expect(moneys[1]).to eq(Money.new(4.88)) #  <-- gets no penny
      expect(moneys[2]).to eq(Money.new(24.41)) # <-- gets no penny
      expect(moneys[3]).to eq(Money.new(24.42)) # <-- gets 1 penny
      expect(moneys[4]).to eq(Money.new(78.15)) # <-- gets 1 penny
      expect(moneys[5]).to eq(Money.new(58.61)) # <-- gets 1 penny

      #round robin reverse for 0 pennies
      moneys = new_allocator(101).allocate([0.25, 0.25, 0.25, 0.25], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[1]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[2]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[3]).to eq(Money.new(25.25)) # <-- gets no penny
    end

    specify "#allocate :nearest strategy distributes pennies first to the number which is nearest to the next whole cent" do
      #nearest for 1 penny
      moneys = new_allocator(0.03).allocate([0.5, 0.5], :nearest)
      expect(moneys[0]).to eq(Money.new(0.02)) # <-- gets 1 penny
      expect(moneys[1]).to eq(Money.new(0.01)) # <-- gets no penny

      #Nearest for 2 pennies
      moneys = new_allocator(10.55).allocate([0.25, 0.5, 0.25], :nearest)
      expect(moneys[0]).to eq(Money.new(2.64)) # <-- gets 1 penny
      expect(moneys[1]).to eq(Money.new(5.27)) # <-- gets no penny
      expect(moneys[2]).to eq(Money.new(2.64)) # <-- gets 1 penny

      #Nearest for 3 pennies
      moneys = new_allocator(195.35).allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :nearest)
      expect(moneys[0]).to eq(Money.new(4.88)) #  <-- gets no penny
      expect(moneys[1]).to eq(Money.new(4.88)) #  <-- gets no penny
      expect(moneys[2]).to eq(Money.new(24.42)) # <-- gets 1 penny
      expect(moneys[3]).to eq(Money.new(24.42)) # <-- gets 1 penny
      expect(moneys[4]).to eq(Money.new(78.14)) # <-- gets no penny
      expect(moneys[5]).to eq(Money.new(58.61)) # <-- gets 1 penny

      #Nearest for 0 pennies
      moneys = new_allocator(101).allocate([0.25, 0.25, 0.25, 0.25], :nearest)
      expect(moneys[0]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[1]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[2]).to eq(Money.new(25.25)) # <-- gets no penny
      expect(moneys[3]).to eq(Money.new(25.25)) # <-- gets no penny
    end

    specify "#allocate :roundrobin strategy distributes leftover Yen from left to right" do
      #Roundrobin for 1 yen
      moneys = new_allocator(31, 'JPY').allocate([0.5,0.5], :roundrobin)
      expect(moneys[0]).to eq(Money.new(16, 'JPY'))
      expect(moneys[1]).to eq(Money.new(15, 'JPY'))

      #Roundrobin for 3 yen
      moneys = new_allocator(19535, "JPY").allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :roundrobin)
      expect(moneys[0]).to eq(Money.new(489, "JPY")) #  <-- gets 1 yen
      expect(moneys[1]).to eq(Money.new(489, "JPY")) #  <-- gets 1 yen
      expect(moneys[2]).to eq(Money.new(2442, "JPY")) # <-- gets 1 yen
      expect(moneys[3]).to eq(Money.new(2441, "JPY")) # <-- gets no yen
      expect(moneys[4]).to eq(Money.new(7814, "JPY")) # <-- gets no yen
      expect(moneys[5]).to eq(Money.new(5860, "JPY")) # <-- gets no yen
    end

    specify "#allocate :roundrobin_reverse strategy distributes leftover Yen from right to left" do
      #Roundrobin for 1 yen
      moneys = new_allocator(31, 'JPY').allocate([0.5,0.5], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(15, 'JPY'))
      expect(moneys[1]).to eq(Money.new(16, 'JPY'))

      #Roundrobin for 3 yen
      moneys = new_allocator(19535, "JPY").allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :roundrobin_reverse)
      expect(moneys[0]).to eq(Money.new(488, "JPY")) #  <-- gets no yen
      expect(moneys[1]).to eq(Money.new(488, "JPY")) #  <-- gets no yen
      expect(moneys[2]).to eq(Money.new(2441, "JPY")) # <-- gets no yen
      expect(moneys[3]).to eq(Money.new(2442, "JPY")) # <-- gets 1 yen
      expect(moneys[4]).to eq(Money.new(7815, "JPY")) # <-- gets 1 yen
      expect(moneys[5]).to eq(Money.new(5861, "JPY")) # <-- gets 1 yen
    end

    specify "#allocate :nearest strategy distributes leftover Yen to the nearest whole Yen" do
      #Nearest for 1 yen
      moneys = new_allocator(31, 'JPY').allocate([0.5,0.5], :nearest)
      expect(moneys[0]).to eq(Money.new(16, 'JPY'))
      expect(moneys[1]).to eq(Money.new(15, 'JPY'))

      #Nearest for 3 yen
      moneys = new_allocator(19535, "JPY").allocate([0.025, 0.025, 0.125, 0.125, 0.4, 0.3], :nearest)
      expect(moneys[0]).to eq(Money.new(488, "JPY")) #  <-- gets no yen
      expect(moneys[1]).to eq(Money.new(488, "JPY")) #  <-- gets no yen
      expect(moneys[2]).to eq(Money.new(2442, "JPY")) # <-- gets 1 yen
      expect(moneys[3]).to eq(Money.new(2442, "JPY")) # <-- gets 1 yen
      expect(moneys[4]).to eq(Money.new(7814, "JPY")) # <-- gets no yen
      expect(moneys[5]).to eq(Money.new(5861, "JPY")) # <-- gets 1 yen
    end

  end

  describe 'allocate_max_amounts' do
    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room for the remainder" do
      expect(
        new_allocator(30.75).allocate_max_amounts([Money.new(26), Money.new(4.75)]),
      ).to eq([Money.new(26), Money.new(4.75)])
    end

    specify "#allocate_max_amounts returns the weighted allocation without exceeding the maxima when there is room for the remainder with currency" do
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

    specify "#allocate_max_amounts drops the remainder when returning the weighted allocation without exceeding the maxima when there is no room for the remainder" do
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
        new_allocator(3).allocate_max_amounts([Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY)]),
      ).to eq([Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY), Money.new(0, Money::NULL_CURRENCY)])
    end

    specify "#allocate_max_amounts allocates the right amount without rounding error" do
      expect(
        new_allocator(24.2).allocate_max_amounts([Money.new(46), Money.new(46), Money.new(50), Money.new(50),Money.new(50)]),
        ).to eq([Money.new(4.6), Money.new(4.6), Money.new(5), Money.new(5), Money.new(5)])
    end
  end

  def new_allocator(amount, currency = nil)
    Money::Allocator.new(Money.new(amount, currency))
  end
end
