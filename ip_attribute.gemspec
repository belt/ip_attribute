# frozen_string_literal: true

require_relative "lib/ip_attribute/version"

Gem::Specification.new do |spec|
  spec.name = "ip_attribute"
  spec.version = IpAttribute::VERSION
  spec.authors = ["Paul Belt"]
  spec.email = ["153964+belt@users.noreply.github.com"]

  spec.summary = "ActiveRecord IP address attributes stored as integers."
  spec.description = <<~DESC
    Auto-converts ActiveRecord columns ending in _ip between human-readable
    IP strings and integer storage. Supports IPv4 and IPv6. Includes a
    standalone converter and opt-in refinements.
  DESC
  spec.homepage = "https://github.com/belt/ip_attribute"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.4.9"
  spec.required_rubygems_version = ">= 3.6"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/belt/ip_attribute",
    "changelog_uri" => "https://github.com/belt/ip_attribute/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "https://github.com/belt/ip_attribute/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir["lib/**/*.rb", "lib/**/*.erb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.2"
  spec.add_dependency "activesupport", ">= 7.2"
end
