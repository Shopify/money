# frozen_string_literal: true

require "rails_spec_helper"

RSpec.describe Money::Rails::JobArgumentSerializer do
  it "roundtrip a Money argument returns the same object" do
    job = MoneyTestJob.new(value: Money.new(10.21, "BRL"))

    serialized_job = job.serialize
    serialized_value = serialized_job["arguments"][0]["value"]
    expect(serialized_value["_aj_serialized"]).to eq("Money::Rails::JobArgumentSerializer")
    expect(serialized_value["value"]).to eq("10.21")
    expect(serialized_value["currency"]).to eq("BRL")

    job2 = MoneyTestJob.deserialize(serialized_job)
    job2.send(:deserialize_arguments_if_needed)

    expect(job2.arguments.first[:value]).to eq(Money.new(10.21, "BRL"))
  end

  it "preserves calculation digits across successive job round trips and presentment" do
    money = Money.new("0.0057", "USD", decimal_precision: 3)

    [["0.0057", "0.01"], ["0.057", "0.06"]].each do |raw_value, formatted|
      expect(money.to_s).to eq(formatted)
      job = MoneyTestJob.deserialize(MoneyTestJob.new(value: money).serialize)
      job.send(:deserialize_arguments_if_needed)
      money = job.arguments.first[:value]

      expect(money.value).to eq(BigDecimal(raw_value))
      expect(money.decimal_precision).to eq(3)
      expect(money).to be_explicit_decimal_precision
      money *= 10
    end

    expect(money.value).to eq(BigDecimal("0.57"))
    expect(money.to_s).to eq("0.57")
    expect(money.decimal_precision).to eq(3)
  end

  it "roundtrips non-default decimal precision" do
    money = Money.new("0.0574", "USD", decimal_precision: 3)
    serialized_job = MoneyTestJob.new(value: money).serialize

    serialized_value = serialized_job["arguments"][0]["value"]
    expect(serialized_value["value"]).to eq("0.0574")
    expect(serialized_value["decimal_precision"]).to eq(3)

    deserialized_job = MoneyTestJob.deserialize(serialized_job)
    deserialized_job.send(:deserialize_arguments_if_needed)
    deserialized_money = deserialized_job.arguments.first[:value]

    expect(deserialized_money).to eq(money)
    expect(deserialized_money.value).to eq(BigDecimal("0.0574"))
    expect(deserialized_money.decimal_precision).to eq(3)
  end
end
