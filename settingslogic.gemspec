# frozen_string_literal: true

require_relative 'lib/settingslogic/version'

Gem::Specification.new do |spec|
  spec.name        = "settingslogic"
  spec.version     = Settingslogic::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.authors     = ["Ben Johnson", "MITRE Corporation"]
  spec.email       = ["lippold@gmail.com"]
  spec.homepage    = "https://github.com/mitre/settingslogic"
  spec.summary     = "A simple settings solution using YAML and a singleton pattern"
  spec.description = "A simple and straightforward settings solution that uses an ERB enabled YAML file and a singleton design pattern. This is a MITRE-maintained fork with Ruby 3.x and Rails 7.x compatibility."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri"      => spec.homepage,
    "source_code_uri"   => spec.homepage,
    "changelog_uri"     => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri"   => "#{spec.homepage}/issues",
    "documentation_uri" => "https://www.rubydoc.info/gems/settingslogic"
  }

  # Development Dependencies - All verified for security
  spec.add_development_dependency 'rake', '~> 13.2'          # CVE-2020-8130 fixed in 12.3.3+
  spec.add_development_dependency 'rspec', '~> 3.13'         # Latest stable
  spec.add_development_dependency 'rubocop', '~> 1.65'       # Latest 1.x stable
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'  # Major version upgrade available
  spec.add_development_dependency 'simplecov', '~> 0.22'     # Current stable
  spec.add_development_dependency 'bundler-audit', '~> 0.9' # Security auditing

  # Files
  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[README.md LICENSE CHANGELOG.md]
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]
end