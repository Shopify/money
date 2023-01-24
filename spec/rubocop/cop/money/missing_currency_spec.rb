# frozen_string_literal: true

require_relative '../../../rubocop_helper'
require 'rubocop/cop/money/missing_currency'

RSpec.describe RuboCop::Cop::Money::MissingCurrency do
  subject(:cop) { described_class.new(config) }

  let(:config) { RuboCop::Config.new }

  context 'with default configuration' do
    it 'registers an offense and corrects for Money.new without a currency argument' do
      expect_offense(<<~RUBY)
        Money.new(1)
        ^^^^^^^^^^^^ Money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        Money.new(1, Money::NULL_CURRENCY)
      RUBY
    end

    it 'does not register an offense for Money.new with currency argument' do
      expect_no_offenses(<<~RUBY)
        Money.new(1, 'CAD')
      RUBY
    end

    it 'does not register an offense for Money.new with splat argument' do
      expect_no_offenses(<<~RUBY)
        value_and_currency = [1, 'CAD']
        Money.new(*value_and_currency)
      RUBY
    end

    it 'registers an offense and corrects for Money.new without a currency argument' do
      expect_offense(<<~RUBY)
        Money.new
        ^^^^^^^^^ Money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        Money.new(0, Money::NULL_CURRENCY)
      RUBY
    end

    it 'registers an offense and corrects for Money.from_amount without a currency argument' do
      expect_offense(<<~RUBY)
        Money.from_amount(1)
        ^^^^^^^^^^^^^^^^^^^^ Money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        Money.from_amount(1, Money::NULL_CURRENCY)
      RUBY
    end

    it 'does not register an offense for Money.from_amount with currency argument' do
      expect_no_offenses(<<~RUBY)
        Money.from_amount(1, 'CAD')
      RUBY
    end

    it 'registers an offense and corrects for Money.from_cents without a currency argument' do
      expect_offense(<<~RUBY)
        Money.from_cents(1)
        ^^^^^^^^^^^^^^^^^^^ Money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        Money.from_cents(1, Money::NULL_CURRENCY)
      RUBY
    end

    it 'does not register an offense for Money.from_cents with currency argument' do
      expect_no_offenses(<<~RUBY)
        Money.from_cents(1, 'CAD')
      RUBY
    end

    it 'registers an offense and corrects for to_money without a currency argument' do
      expect_offense(<<~RUBY)
        '1'.to_money
        ^^^^^^^^^^^^ to_money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        '1'.to_money(Money::NULL_CURRENCY)
      RUBY
    end

    it 'registers an offense and corrects for safe navigation to_money without a currency argument' do
      expect_offense(<<~RUBY)
        item&.to_money
        ^^^^^^^^^^^^^^ to_money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        item&.to_money(Money::NULL_CURRENCY)
      RUBY
    end

    it 'does not register an offense for to_money with currency argument' do
      expect_no_offenses(<<~RUBY)
        '1'.to_money('CAD')
      RUBY
    end

    it 'registers an offense and corrects for to_money block pass form' do
      expect_offense(<<~RUBY)
        ['1'].map(&:to_money)
        ^^^^^^^^^^^^^^^^^^^^^ to_money is missing currency argument
      RUBY

      expect_correction(<<~RUBY)
        ['1'].map { |x| x.to_money(Money::NULL_CURRENCY) }
      RUBY
    end
  end

  context 'with ReplacementCurrency configuration' do
    let(:config) do
      RuboCop::Config.new(
        'Money/MissingCurrency' => {
          'ReplacementCurrency' => 'CAD'
        }
      )
    end

    it 'corrects Money.new without currency' do
      new_source = autocorrect_source('Money.new(1)')
      expect(new_source).to eq("Money.new(1, 'CAD')")
    end

    it 'corrects Money.new without amount or currency' do
      new_source = autocorrect_source('Money.new')
      expect(new_source).to eq("Money.new(0, 'CAD')")
    end

    it 'corrects to_money without currency' do
      new_source = autocorrect_source('1.to_money')
      expect(new_source).to eq("1.to_money('CAD')")
    end

    it 'corrects to_money block pass form' do
      new_source = autocorrect_source("['1'].map(&:to_money)")
      expect(new_source).to eq("['1'].map { |x| x.to_money('CAD') }")
    end
  end
end
