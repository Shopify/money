$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails'
require 'active_record'
require 'money'

require 'simplecov'
if ENV['CIRCLE_ARTIFACTS']
  SimpleCov.coverage_dir(File.join(ENV['CIRCLE_ARTIFACTS'], "coverage"))
end
SimpleCov.start
require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

load File.join(File.dirname(__FILE__), "schema.rb")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end
