# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# CI matrix: AR_VERSION=7.2 or AR_VERSION=8.1 (default: latest)
ar_version = ENV.fetch("AR_VERSION", nil)
if ar_version
  gem "activerecord", "~> #{ar_version}.0"
  gem "activesupport", "~> #{ar_version}.0"
end

group :development do
  # Modern debugger (Ruby 3.1+, replaces pry/byebug)
  gem "debug", ">= 1.11", require: false

  # Code quality (combined: reek + flay + flog)
  gem "rubycritic", "~> 4.9", require: false
  gem "ostruct", ">= 0.6", require: false  # rubycritic → virtus dep, removed from stdlib in Ruby 4.0

  # Code smell detection (standalone, also used by rubycritic)
  gem "reek", "~> 6.5", require: false
end

group :development, :test do
  # Testing
  gem "rspec", "~> 3.13"

  # Property-based / fuzz testing
  gem "rantly", "~> 3.0"

  # Linting (zero-config)
  gem "standard", "~> 1.54", require: false

  # Coverage
  gem "simplecov", "~> 0.22", require: false

  # Database (test)
  gem "sqlite3", "~> 2.9"

  # Security audit
  gem "bundler-audit", "~> 0.9", require: false
end
