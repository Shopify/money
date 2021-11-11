# frozen_string_literal: true

require "active_job"
require_relative "spec_helper"

Money::Railtie.initializers.each(&:run)

class MoneyTestJob < ActiveJob::Base
  def perform(_params)
  end
end
