# frozen_string_literal: true
require_relative 'money/version'
require_relative 'money/parser/fuzzy'
require_relative 'money/helpers'
require_relative 'money/currency'
require_relative 'money/null_currency'
require_relative 'money/allocator'
require_relative 'money/splitter'
require_relative 'money/config'
require_relative 'money/money'
require_relative 'money/errors'
require_relative 'money/deprecations'
require_relative 'money/parser/accounting'
require_relative 'money/parser/locale_aware'
require_relative 'money/parser/simple'
require_relative 'money/core_extensions'
require_relative 'money_column' if defined?(ActiveRecord)
require_relative 'money/railtie' if defined?(Rails::Railtie)

require_relative 'rubocop/cop/money' if defined?(RuboCop)
