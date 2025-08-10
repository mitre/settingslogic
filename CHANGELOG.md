# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-01-09

### Security
- Updated all development dependencies to latest secure versions
- Added bundler-audit for continuous security monitoring
- Verified no known CVEs in dependencies (as of 2025-01-09)
- rake 13.3.0 (well above CVE-2020-8130 vulnerable version 12.3.3)
- All dependencies audited and updated

### Added
- Full Ruby 3.x compatibility (3.0, 3.1, 3.2, 3.3, 3.4)
- Psych 4 support for Ruby 3.1+ (fixes YAML alias handling)
- Rails 7.x and 8.x compatibility
- `stringify_keys` method for Rails compatibility
- `deep_merge` and `deep_merge!` methods
- `to_ary` method to fix RSpec Array#flatten issues
- Improved error messages for YAML alias issues
- GitHub Actions CI for testing across Ruby versions
- Comprehensive security documentation
- MITRE standard project files (CODE_OF_CONDUCT, CONTRIBUTING, etc.)
- Better file reading with proper `File.read` for local files

### Changed
- Version bumped to 3.0.0 (major version due to Ruby version requirement change)
- Minimum Ruby version is now 2.7
- Updated deprecated `has_key?` to `key?`
- Improved `symbolize_keys` implementation using `each_with_object`
- Enhanced eval security with `__FILE__` and `__LINE__` tracking
- Modernized code style with frozen string literals
- YAML loading now uses `unsafe_load` for Ruby 3.1+ (trusted config files)

### Fixed
- YAML aliases (`<<: *defaults`) now work correctly in Ruby 3.1+
- RSpec compatibility issues with Settings objects in arrays
- Security warnings from eval usage
- Deprecated method warnings
- Open-uri deprecation warnings for Ruby 3.0+

### Security
- Improved YAML loading with appropriate safety checks
- Better handling of untrusted input
- Security documentation and best practices

## [2.0.9] - 2012-02-08

### Note
This was the last release of the original gem by Ben Johnson. See the original repository for historical changes: https://github.com/binarylogic/settingslogic

---

## Migration Guide

### From 2.0.9 to 3.0.0

If you're upgrading from the original settingslogic gem:

1. **Ruby Version**: Ensure you're using Ruby 2.7 or later
2. **Gemfile**: Update to use the MITRE fork:
   ```ruby
   gem 'settingslogic', github: 'mitre/settingslogic', branch: 'master'
   ```
3. **YAML Aliases**: Your existing YAML files with aliases will now work correctly
4. **No Code Changes**: The API remains backward compatible

### Known Issues

- None at this time. Please report issues at: https://github.com/mitre/settingslogic/issues