# frozen_string_literal: true
require 'spec_helper'

RSpec.describe "deprecations" do
  it "has the deprecation_horizon as the next major release" do
    expect(Money.active_support_deprecator.deprecation_horizon).to eq("4.0.0")
  end
end
