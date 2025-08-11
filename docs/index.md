# MITRE Settingslogic

A simple and straightforward settings solution using YAML and a singleton pattern, maintained by MITRE for Ruby 3.x and Rails 7.x compatibility.

## Overview

Settingslogic is a simple configuration / settings solution that uses an ERB enabled YAML file. It has been great for our apps, maybe it will be for yours too. Settingslogic works with Rails, Sinatra, or any Ruby project.

!!! warning "Security Notice"
    Version 3.0.0 introduces **breaking changes** to address YAML deserialization security vulnerabilities. Please review the [Migration Guide](migration.md) before upgrading.

## Key Features

- **Simple** - Just a YAML file with ERB processing
- **Secure** - Uses `YAML.safe_load` by default (v3.0.0+)
- **Flexible** - Works with Rails, Sinatra, or plain Ruby
- **Singleton** - Settings are available globally
- **Nested** - Access nested settings with method calls
- **Environment-aware** - Different settings per environment

## Quick Example

```yaml
# config/application.yml
defaults: &defaults
  cool:
    saweet: nested settings
  neat_setting: 24
  awesome_setting: <%= "Did you know 5 + 5 = #{5 + 5}?" %>

development:
  <<: *defaults
  neat_setting: 800

production:
  <<: *defaults
```

```ruby
# In your Ruby code
class Application < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end

# Access settings
Application.cool.saweet  # => "nested settings"
Application.neat_setting # => 800 (in development)
```

## This Fork

This is MITRE's official fork of the settingslogic gem, created to provide:

- Ruby 3.x compatibility (Psych 4 support)
- Rails 7.x and 8.x compatibility
- Security fixes for YAML deserialization vulnerabilities
- Continued maintenance for MITRE projects

The original gem hasn't been updated since 2012 but is still widely used.

## Installation

Add to your Gemfile:

```ruby
gem 'mitre-settingslogic', '~> 3.0'
```

Or install directly:

```bash
gem install mitre-settingslogic
```

## Next Steps

- [Installation Guide](installation.md) - Detailed installation instructions
- [Quick Start](quick-start.md) - Get up and running quickly
- [Migration from v2.x](migration.md) - Upgrade from older versions
- [Security Settings](SECURITY.md) - Understanding the security changes