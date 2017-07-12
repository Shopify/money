require 'simplecov'
SimpleCov.minimum_coverage 100
SimpleCov.start do
  add_filter "/spec/"
end

if ENV['CI'] == 'true'
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'rails'
require 'active_record'
require 'money'
require 'pry'

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

load File.join(File.dirname(__FILE__), "schema.rb")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

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
