# frozen_string_literal: true
require 'simplecov'
SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter "/spec/"
  add_filter "/lib/money/railtie"
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'pry-byebug'
require 'database_cleaner'
require 'ostruct'

require 'rails'
require 'active_record'
require 'money'

Money.active_support_deprecator.behavior = :raise
Money.default_currency = Money::Currency.new('CAD')

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

load File.join(File.dirname(__FILE__), "schema.rb")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.order = :random

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

 config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

RSpec::Matchers.define :quack_like do
  match do
    missing_methods.empty?
  end

  failure_message do
    "expected #{actual.name} to respond to #{missing_methods.join(', ')}"
  end

  def missing_methods
    expected.instance_methods - actual.instance_methods
  end
end


def configure(default_currency: nil, legacy_json_format: nil, legacy_deprecations: nil, legacy_default_currency: nil)
  Money::Config.current = Money::Config.new.tap do |config|
    config.default_currency = default_currency if default_currency
    config.legacy_json_format! if legacy_json_format
    config.legacy_deprecations! if legacy_deprecations
    config.legacy_default_currency! if legacy_default_currency
    config.experimental_crypto_currencies! if experimental_crypto_currencies
  end
  yield
ensure
  Money::Config.reset_current
end

def yaml_load(yaml)
  return YAML.load(yaml) if Psych::VERSION < '4.0'

  YAML.safe_load(yaml, permitted_classes: [BigDecimal, Money, Money::Currency, Money::NullCurrency])
end
