# Settingslogic - MITRE Fork

[![CI](https://github.com/mitre/settingslogic/actions/workflows/ci.yml/badge.svg)](https://github.com/mitre/settingslogic/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/settingslogic.svg)](http://badge.fury.io/rb/settingslogic)

A simple and straightforward settings solution that uses an ERB enabled YAML file and a singleton design pattern. This is a MITRE-maintained fork with Ruby 3.x and Rails 7.x+ compatibility.

## 🎯 Why This Fork?

The original settingslogic gem hasn't been updated since 2012 but is still widely used. This fork provides:

- ✅ **Ruby 3.x compatibility** - Full support for Ruby 3.0, 3.1, 3.2, 3.3, and 3.4
- ✅ **Psych 4 support** - Handles YAML aliases correctly with Ruby 3.1+
- ✅ **Rails 7.x/8.x compatibility** - Works with modern Rails versions
- ✅ **Security updates** - Modern security practices and dependency updates
- ✅ **Maintained** - Active maintenance and support

## 📦 Installation

Add this to your Gemfile:

```ruby
# Use the MITRE fork for Ruby 3.x compatibility
gem 'settingslogic', github: 'mitre/settingslogic', branch: 'master'
```

Or if we publish to RubyGems:

```ruby
gem 'mitre-settingslogic'
```

## 🚀 Quick Start

### 1. Define your settings class

```ruby
# app/models/settings.rb (for Rails)
# or anywhere in your Ruby project
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end
```

### 2. Create your YAML configuration

```yaml
# config/application.yml
defaults: &defaults
  host: localhost
  port: 3000
  ssl: false
  
development:
  <<: *defaults
  database: myapp_development
  
production:
  <<: *defaults
  host: production.example.com
  port: 443
  ssl: true
  database: myapp_production
```

### 3. Use your settings

```ruby
Settings.host          # => "localhost" in development, "production.example.com" in production
Settings.port          # => 3000 in development, 443 in production
Settings.ssl?          # => false in development, true in production
Settings.database      # => "myapp_development" in development

# Nested settings
Settings.smtp.address  # => Access nested configuration
Settings['smtp']['address']  # => Hash-style access also works
```

## 🔧 Advanced Features

### Dynamic Settings

```ruby
# Settings with ERB
production:
  secret_key: <%= ENV['SECRET_KEY_BASE'] %>
  redis_url: <%= ENV['REDIS_URL'] || 'redis://localhost:6379' %>
```

### Multiple Configuration Files

```ruby
class DatabaseSettings < Settingslogic
  source "#{Rails.root}/config/database_settings.yml"
  namespace Rails.env
end

class FeatureFlags < Settingslogic
  source "#{Rails.root}/config/features.yml"
  namespace Rails.env
end
```

### Suppress Errors

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  suppress_errors true  # Returns nil instead of raising errors for missing keys
end
```

### Dynamic Access

```ruby
# Access nested keys with dot notation
Settings.get('database.pool.size')  # => 5
Settings.get('redis.cache.ttl')     # => 3600
```

## 🏗️ What's Fixed in This Fork

### Psych 4 / Ruby 3.1+ Compatibility

The main issue with the original gem is that Ruby 3.1+ ships with Psych 4, which disables YAML aliases by default. This fork handles that correctly:

```ruby
# This YAML with aliases now works correctly in Ruby 3.1+
defaults: &defaults
  timeout: 30
  retries: 3

production:
  <<: *defaults  # This alias expansion works!
  timeout: 60
```

### Other Improvements

- ✅ Fixed deprecated `has_key?` → `key?`
- ✅ Added `to_ary` method for RSpec compatibility
- ✅ Improved `symbolize_keys` for nested hashes
- ✅ Added `stringify_keys` for Rails compatibility
- ✅ Better error messages
- ✅ Security improvements for eval usage
- ✅ Frozen string literals
- ✅ Modern Ruby idioms

## 🧪 Compatibility

Tested and working with:

- **Ruby:** 2.7, 3.0, 3.1, 3.2, 3.3, 3.4
- **Rails:** 5.2, 6.0, 6.1, 7.0, 7.1, 8.0
- **Psych:** 3.x and 4.x

## 🔒 Security

### YAML Safe Loading (v3.0.0+)
- **Default behavior**: Uses `YAML.safe_load` to prevent arbitrary code execution
- **Permitted classes**: `Symbol, Date, Time, DateTime, BigDecimal`
- **Custom classes**: Add via `Settingslogic.yaml_permitted_classes += [MyClass]`
- **Migration path**: Temporary opt-out with `Settingslogic.use_yaml_unsafe_load = true` (deprecated, will be removed in v4.0.0)

### Other Security Features
- URL loading uses `Net::HTTP` instead of vulnerable `open-uri`
- All eval usage includes proper `__FILE__` and `__LINE__` tracking
- No arbitrary code execution vulnerabilities in default configuration

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see [LICENSE.md](LICENSE.md) for details.

## 🙏 Acknowledgments

- Original gem created by [Ben Johnson](https://github.com/binarylogic) (binarylogic)
- Community maintainers at [settingslogic/settingslogic](https://github.com/settingslogic/settingslogic)
- Key fixes incorporated from:
  - [minorun99/settingslogic](https://github.com/minorun99/settingslogic) - Ruby 3.2 compatibility
  - [etozzato/settingslogic](https://github.com/etozzato/settingslogic) - Psych 4 safe_load implementation
  - [bigcommerce/settingslogic](https://github.com/bigcommerce/settingslogic) - Various compatibility fixes
  - [tvw/settingslogic](https://github.com/tvw/settingslogic) - Ruby 3 support
  - And many others who kept this gem alive through their forks and PRs
- Special thanks to all who submitted PRs to the original repo, especially PR #86 for Psych 4 compatibility

## 📚 Documentation

- [Original Documentation](http://rdoc.info/github/binarylogic/settingslogic)
- [MITRE Fork Issues](https://github.com/mitre/settingslogic/issues)
- [MITRE Fork Repository](https://github.com/mitre/settingslogic)

## 🏢 About MITRE

This fork is maintained by [MITRE Corporation](https://www.mitre.org/) to support our Ruby applications, particularly [Vulcan](https://github.com/mitre/vulcan) and other security tools.

---

**Maintained with ❤️ by the MITRE Security Automation Framework Team**