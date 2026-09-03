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

  it "roundtrips non-default decimal precision" do
    money = Money.new("0.057", "USD", decimal_precision: 3)
    serialized_job = MoneyTestJob.new(value: money).serialize

    serialized_value = serialized_job["arguments"][0]["value"]
    expect(serialized_value["decimal_precision"]).to eq(3)

    deserialized_job = MoneyTestJob.deserialize(serialized_job)
    deserialized_job.send(:deserialize_arguments_if_needed)
    deserialized_money = deserialized_job.arguments.first[:value]

    expect(deserialized_money).to eq(money)
    expect(deserialized_money.decimal_precision).to eq(3)
  end
end
