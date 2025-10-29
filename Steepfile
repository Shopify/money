# frozen_string_literal: true

target :lib do
  signature "sig"

  check "lib"
  ignore "lib/rubocop/**/*.rb"  # RuboCop cops require RuboCop types
  ignore "lib/money/railtie.rb"  # Rails railtie requires Rails types
  ignore "lib/money/rails/**/*.rb"  # Rails integrations require Rails types
  ignore "lib/money_column/railtie.rb"  # Rails railtie requires Rails types

  library "bigdecimal"
  library "json"
  library "forwardable"
  library "yaml"
end
