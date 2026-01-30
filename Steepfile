# frozen_string_literal: true

target :lib do
  signature "sig"

  check "lib"
  ignore "lib/rubocop/**/*.rb" # RuboCop cops use metaprogramming DSL
  ignore "lib/money/railtie.rb" # Rails types
  ignore "lib/money/deprecations.rb" # Uses class_eval
  ignore "lib/money/rails/**/*.rb" # Rails-specific code
  ignore "lib/money_column/railtie.rb" # Rails types
  ignore "lib/money_column/active_record_hooks.rb" # Heavy metaprogramming with define_method

  library "bigdecimal"
  library "json"
  library "forwardable"
  library "yaml"

  configure_code_diagnostics(Steep::Diagnostic::Ruby.lenient)
end
