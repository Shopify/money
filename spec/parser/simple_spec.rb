# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Money::Parser::Simple do
  context "parsing amounts with period decimal separator" do
    it "parses an empty string to nil" do
      expect(described_class.parse("", "CAD")).to be_nil
    end

    it "parses an invalid string when not strict" do
      expect(described_class.parse("no money", "CAD")).to be_nil
      expect(described_class.parse("1..", "CAD")).to be_nil
      expect(described_class.parse("10.", "CAD")).to be_nil
      expect(described_class.parse("10.1E2", "CAD")).to be_nil
    end

    it "raises with an invalid string and strict option" do
      expect { described_class.parse("no money", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("1..1", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("10.", "CAD", strict: true) }.to raise_error(ArgumentError)
      expect { described_class.parse("10.1E2", "CAD", strict: true) }.to raise_error(ArgumentError)
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

    it "does not parse a float string amount with a leading random character" do
      expect(described_class.parse("$1.37", "CAD")).to be_nil
      expect(described_class.parse(",1.37", "CAD")).to be_nil
      expect(described_class.parse("€1.37", "CAD")).to be_nil
      expect(described_class.parse(" 1.37", "CAD")).to be_nil
    end

    it "does not parse a float string amount with a trailing random character" do
      expect(described_class.parse("1.37$", "CAD")).to be_nil
      expect(described_class.parse("1.37,", "CAD")).to be_nil
      expect(described_class.parse("1.37€", "CAD")).to be_nil
      expect(described_class.parse("1.37 ", "CAD")).to be_nil
    end

    it "does not parse an amount with one or more thousands separators" do
      expect(described_class.parse("100,000", "CAD")).to be_nil
      expect(described_class.parse("-100,000", "CAD")).to be_nil
      expect(described_class.parse("100,000.01", "CAD")).to be_nil
      expect(described_class.parse("1,00,000.01", "CAD")).to be_nil
      expect(described_class.parse("1,00,000.001", "JOD")).to be_nil
    end
  end
end
