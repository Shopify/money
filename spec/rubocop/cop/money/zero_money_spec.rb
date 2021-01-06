# frozen_string_literal: true

require_relative '../../../rubocop_helper'
require 'rubocop/cop/money/zero_money'

RSpec.describe RuboCop::Cop::Money::ZeroMoney do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context 'with default configuration' do
    it 'registers an offense and corrects Money.zero without currency' do
      expect_offense(<<~RUBY)
        Money.zero
        ^^^^^^^^^^ Money.zero is removed, use `Money.new(0, Money::NULL_CURRENCY)`.
      RUBY

      expect_correction(<<~RUBY)
        Money.new(0, Money::NULL_CURRENCY)
      RUBY
    end

    it 'registers an offense and corrects Money.zero with currency' do
      expect_offense(<<~RUBY)
        Money.zero('CAD')
        ^^^^^^^^^^^^^^^^^ Money.zero is removed, use `Money.new(0, 'CAD')`.
      RUBY

      expect_correction(<<~RUBY)
        Money.new(0, 'CAD')
      RUBY
    end

    it 'does not register an offense when using Money.new with a currency' do
      expect_no_offenses(<<~RUBY)
        Money.new(0, 'CAD')
      RUBY
    end
  end

  context 'with ReplacementCurrency configuration' do
    let(:config) do
      RuboCop::Config.new(
        'Money/ZeroMoney' => {
          'ReplacementCurrency' => 'CAD'
        }
      )
    end

    it 'registers an offense and corrects Money.zero without currency' do
      expect_offense(<<~RUBY)
        Money.zero
        ^^^^^^^^^^ Money.zero is removed, use `Money.new(0, 'CAD')`.
      RUBY

      expect_correction(<<~RUBY)
        Money.new(0, 'CAD')
      RUBY
    end

    it 'registers an offense and corrects Money.zero with currency' do
      expect_offense(<<~RUBY)
        Money.zero('EUR')
        ^^^^^^^^^^^^^^^^^ Money.zero is removed, use `Money.new(0, 'EUR')`.
      RUBY

      expect_correction(<<~RUBY)
        Money.new(0, 'EUR')
      RUBY
    end

    it 'does not register an offense when using Money.new with a currency' do
      expect_no_offenses(<<~RUBY)
        Money.new(0, 'EUR')
      RUBY
    end
  end
end
