# frozen_string_literal: true

require_relative '../../../rubocop_helper'
require 'rubocop/cop/money/unsafe_to_money'

RSpec.describe RuboCop::Cop::Money::UnsafeToMoney do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context 'with default configuration' do
    it 'does not register an offense for literal integer' do
      expect_no_offenses(<<~RUBY)
        1.to_money
      RUBY
    end

    it 'does not register an offense for literal float' do
      expect_no_offenses(<<~RUBY)
        1.000.to_money
      RUBY
    end

    it 'registers an offense and corrects for Money.new without a currency argument' do
      expect_offense(<<~RUBY)
        '2.000'.to_money
                ^^^^^^^^ #{described_class::MSG}
      RUBY

      expect_correction(<<~RUBY)
        Money.new('2.000')
      RUBY
    end

    it 'registers an offense and corrects for Money.new with a currency argument' do
      expect_offense(<<~RUBY)
        '2.000'.to_money('USD')
                ^^^^^^^^ #{described_class::MSG}
      RUBY

      expect_correction(<<~RUBY)
        Money.new('2.000', 'USD')
      RUBY
    end

    it 'registers an offense and corrects for Money.new with a complex receiver' do
      expect_offense(<<~RUBY)
        obj.money.to_money('USD')
                  ^^^^^^^^ #{described_class::MSG}
      RUBY

      expect_correction(<<~RUBY)
        Money.new(obj.money, 'USD')
      RUBY
    end
  end
end
