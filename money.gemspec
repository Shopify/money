# -*- encoding: utf-8 -*-
# frozen_string_literal: true
require_relative "lib/money/version"

Gem::Specification.new do |s|
  s.name = "shopify-money"
  s.version = Money::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Shopify Inc"]
  s.email = "gems@shopify.com"
  s.description = "Manage money in Shopify with a class that wont lose pennies during division!"
  s.homepage = "https://github.com/Shopify/money"
  s.licenses = "MIT"
  s.summary = "Shopify's money gem"

  s.metadata['allowed_push_host'] = "https://rubygems.org"

  s.add_development_dependency("bundler")
  s.add_development_dependency("simplecov", ">= 0")
  s.add_development_dependency("rails", "~> 6.0")
  s.add_development_dependency("rspec", "~> 3.2")
  s.add_development_dependency("database_cleaner", "~> 1.6")
  s.add_development_dependency("sqlite3")

  s.required_ruby_version = '>= 2.6'

  s.files = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]
end
