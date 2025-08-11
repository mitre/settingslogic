# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-01-11

### 🔒 Security (BREAKING CHANGES)

- **Critical**: Replace `YAML.unsafe_load` with `YAML.safe_load` to prevent arbitrary code execution
- Default permitted YAML classes: `Symbol, Date, Time, DateTime, BigDecimal`
- Replace vulnerable `open-uri` with `Net::HTTP` for URL loading
- Add protocol validation to block dangerous URI schemes (file://, ftp://, etc.)

### ✨ Features

- Add Ruby 3.x compatibility (3.0, 3.1, 3.2, 3.3, 3.4)
- Add Rails 7.x and 8.x compatibility
- Add Psych 4 support with YAML alias handling
- Add configurable permitted classes via `Settingslogic.yaml_permitted_classes`
- Add migration path with deprecated `Settingslogic.use_yaml_unsafe_load` flag
- Add helpful error messages with migration instructions

### 🐛 Fixes

- Fix RSpec Array#flatten issues with `to_ary` method
- Fix deprecated `has_key?` usage (now `key?`)
- Fix eval security with proper `__FILE__` and `__LINE__` tracking
- Fix Ruby 3.4 compatibility with explicit bigdecimal dependency
- Fix CI issues with Ruby 2.7 + Rails 6.1 zeitwerk conflict

### 📦 Infrastructure

- Add comprehensive test suite (94.63% coverage)
- Add RuboCop linting with rubocop-rspec and rubocop-performance
- Add GitHub Actions CI for all Ruby/Rails combinations
- Add automated release tooling with version management
- Add security testing suite (19 security-specific tests)

### 📚 Documentation

- Add comprehensive README with migration guide
- Add SECURITY.md with vulnerability reporting process
- Add ROADMAP.md for future development plans
- Add CONTRIBUTING.md for contribution guidelines
- Update all documentation for v3.0.0

### ⚠️ Breaking Changes

- YAML files can no longer instantiate arbitrary Ruby objects by default
- To allow custom classes: `Settingslogic.yaml_permitted_classes += [MyClass]`
- Temporary opt-out available: `Settingslogic.use_yaml_unsafe_load = true` (deprecated)

### 📝 Notes

This is a major security release addressing CVE-2022-32224-like vulnerabilities. All users should upgrade and review their YAML files for compatibility with safe_load restrictions.

## [2.0.9] - 2012-10-19

Last release of the original gem by Ben Johnson (binarylogic).

---

Maintained by MITRE Corporation
Primary maintainer: Aaron Lippold <lippold@gmail.com>