# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Money::Parser::LocaleAware do
  context "parsing amounts with period decimal separator" do
    around(:example) do |example|
      with_decimal_separator(".") { example.run }
    end

    it "parses an empty string to nil" do
      expect(described_class.parse("", "CAD")).to be_nil
    end

    it "parses an invalid string when not strict" do
      expect(described_class.parse("no money", "CAD")).to be_nil
      expect(described_class.parse("1..", "CAD")).to be_nil
    end

    it "raises with an invalid string and strict option" do
      expect { described_class.parse("no money", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("1..1", "CAD", strict: true) }.to raise_error(ArgumentError)
    end

    it "parses an integer string amount" do
      expect(described_class.parse("1", "CAD")).to eq(Money.new(1.00, "CAD"))
      expect(described_class.parse("-1", "CAD")).to eq(Money.new(-1.00, "CAD"))
    end

    it "parses a float string amount" do
      expect(described_class.parse("1.37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("-1.37", "CAD")).to eq(Money.new(-1.37, "CAD"))
    end

    it "parses a float string with 3 decimals" do
      expect(described_class.parse("1.378", "JOD")).to eq(Money.new(1.378, "JOD"))
      expect(described_class.parse("-1.378", "JOD")).to eq(Money.new(-1.378, "JOD"))
      expect(described_class.parse("123.456", "USD")).to eq(Money.new(123.46, "USD"))
    end

    it "parses a float string amount with a leading random character" do
      expect(described_class.parse("$1.37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse(",1.37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("€1.37", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses a float string amount with a trailing random character" do
      expect(described_class.parse("1.37$", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("1.37,", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("1.37€", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses an amount with one or more thousands separators" do
      expect(described_class.parse("100,000", "CAD")).to eq(Money.new(100_000.00, "CAD"))
      expect(described_class.parse("-100,000", "CAD")).to eq(Money.new(-100_000.00, "CAD"))
      expect(described_class.parse("100,000.01", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("1,00,000.01", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("1,00,000.001", "JOD")).to eq(Money.new(100_000.001, "JOD"))
    end
  end

  context "parsing amounts with comma decimal separator" do
    around(:example) do |example|
      with_decimal_separator(",") { example.run }
    end

    it "parses an empty string to nil" do
      expect(described_class.parse("", "CAD")).to be_nil
    end

    it "parses an invalid string when not strict" do
      expect(described_class.parse("no money", "CAD")).to be_nil
      expect(described_class.parse("1,,", "CAD")).to be_nil
    end

    it "raises with an invalid string and strict option" do
      expect { described_class.parse("no money", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("1,,1", "CAD", strict: true) }.to raise_error(ArgumentError)
    end

    it "parses an integer string amount" do
      expect(described_class.parse("1", "CAD")).to eq(Money.new(1.00, "CAD"))
      expect(described_class.parse("-1", "CAD")).to eq(Money.new(-1.00, "CAD"))
    end

    it "parses a float string amount" do
      expect(described_class.parse("1,37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("-1,37", "CAD")).to eq(Money.new(-1.37, "CAD"))
    end

    it "parses a float string with 3 decimals" do
      expect(described_class.parse("1,378", "JOD")).to eq(Money.new(1.378, "JOD"))
      expect(described_class.parse("-1,378", "JOD")).to eq(Money.new(-1.378, "JOD"))
    end

    it "parses a float string amount with a leading random character" do
      expect(described_class.parse("$1,37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse(".1,37", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("€1,37", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses a float string amount with a trailing random character" do
      expect(described_class.parse("1,37$", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("1,37.", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("1,37€", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses an amount with one or more thousands separators" do
      expect(described_class.parse("100.000", "CAD")).to eq(Money.new(100_000.00, "CAD"))
      expect(described_class.parse("-100.000", "CAD")).to eq(Money.new(-100_000.00, "CAD"))
      expect(described_class.parse("100.000,01", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("1.00.000,01", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("1.00.000,001", "JOD")).to eq(Money.new(100_000.001, "JOD"))
    end
  end

  context "parsing amounts with fullwidth characters" do
    around(:example) do |example|
      with_decimal_separator(".") { example.run }
    end

    it "parses an empty string to nil" do
      expect(described_class.parse("", "CAD")).to be_nil
    end

    it "parses an invalid string when not strict" do
      expect(described_class.parse("ｎｏ ｍｏｎｅｙ", "CAD")).to be_nil
      expect(described_class.parse("１．．", "CAD")).to be_nil
    end

    it "raises with an invalid string and strict option" do
      expect { described_class.parse("ｎｏ ｍｏｎｅｙ", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("１．．１", "CAD", strict: true) }.to raise_error(ArgumentError)
    end

    it "parses an integer string amount" do
      expect(described_class.parse("１", "CAD")).to eq(Money.new(1.00, "CAD"))
      expect(described_class.parse("-１", "CAD")).to eq(Money.new(-1.00, "CAD"))
    end

    it "parses a float string amount" do
      expect(described_class.parse("１．３７", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("－１．３７", "CAD")).to eq(Money.new(-1.37, "CAD"))
    end

    it "parses a float string with 3 decimals" do
      expect(described_class.parse("１．３７８", "JOD")).to eq(Money.new(1.378, "JOD"))
      expect(described_class.parse("－１．３７８", "JOD")).to eq(Money.new(-1.378, "JOD"))
    end

    it "parses a float string amount with a leading random character" do
      expect(described_class.parse("$１．３７", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("，１．３７", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("€１．３７", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses a float string amount with a trailing random character" do
      expect(described_class.parse("１．３７$", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("１．３７，", "CAD")).to eq(Money.new(1.37, "CAD"))
      expect(described_class.parse("１．３７€", "CAD")).to eq(Money.new(1.37, "CAD"))
    end

    it "parses an amount with one or more thousands separators" do
      expect(described_class.parse("１００，０００", "CAD")).to eq(Money.new(100_000.00, "CAD"))
      expect(described_class.parse("－１００，０００", "CAD")).to eq(Money.new(-100_000.00, "CAD"))
      expect(described_class.parse("１００，０００．０１", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("１，００，０００．０１", "CAD")).to eq(Money.new(100_000.01, "CAD"))
      expect(described_class.parse("１，００，０００．００１", "JOD")).to eq(Money.new(100_000.001, "JOD"))
      expect(described_class.parse("１００,０００、０００", "JPY")).to eq(Money.new(100_000_000, "JPY"))
    end
  end

  context "bad decimal_separator_proc" do
    context "raises when called" do
      around(:example) do |example|
        with_decimal_separator_proc(->() { raise NoMethodError }) { example.run }
      end

      it "raises the original error" do
        expect { described_class.parse("1", "CAD") }.to raise_error(NoMethodError)
      end
    end

    context "returning nil" do
      around(:example) do |example|
        with_decimal_separator(nil) { example.run }
      end

      it "raises the original error" do
        expect { described_class.parse("1", "CAD") }.to raise_error(ArgumentError)
      end
    end
  end

  private

  def with_decimal_separator(character)
    with_decimal_separator_proc(->() { character }) do
      yield
    end
  end

  def with_decimal_separator_proc(proc)
    old = described_class.decimal_separator_resolver
    described_class.decimal_separator_resolver = proc
    yield
    described_class.decimal_separator_resolver = old
  end
end
