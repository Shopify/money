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
end
