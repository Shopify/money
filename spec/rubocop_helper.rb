# frozen_string_literal: true

require_relative 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
end
