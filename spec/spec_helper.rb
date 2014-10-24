$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'rails'
require 'active_record'
require 'money'

ActiveRecord::Base.establish_connection :adapter => "sqlite3", :database => ":memory:"

load File.join(File.dirname(__FILE__), "schema.rb")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|

end
