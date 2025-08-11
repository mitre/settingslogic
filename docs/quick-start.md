# Quick Start Guide

## Basic Setup

### 1. Create Your Configuration File

Create a YAML file for your settings. For Rails apps, use `config/application.yml`:

```yaml
# config/application.yml
defaults: &defaults
  app_name: My Application
  host: localhost
  port: 3000
  
  database:
    pool: 5
    timeout: 5000
  
  features:
    enable_caching: false
    enable_analytics: false

development:
  <<: *defaults
  host: localhost
  features:
    enable_caching: false

production:
  <<: *defaults
  host: example.com
  features:
    enable_caching: true
    enable_analytics: true
```

### 2. Create Your Settings Class

```ruby
# app/models/settings.rb (Rails)
# or anywhere in your load path

class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  load! # Optional: load settings immediately
end
```

### 3. Access Your Settings

```ruby
# Access top-level settings
Settings.app_name       # => "My Application"
Settings.host          # => "localhost" (in development)

# Access nested settings
Settings.database.pool  # => 5
Settings.features.enable_caching  # => false (in development)

# Check if a setting exists
Settings.has_key?(:host)  # => true
Settings.features?  # => true (convenience method)
```

## ERB Support

You can use ERB in your YAML files:

```yaml
defaults: &defaults
  copyright: © <%= Date.today.year %> My Company
  secret_key: <%= ENV['SECRET_KEY_BASE'] %>
  calculated: <%= 2 + 2 %>
```

## Multiple Configuration Files

You can load settings from multiple files:

```ruby
class AppSettings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end

class DatabaseSettings < Settingslogic
  source "#{Rails.root}/config/database_settings.yml"
  namespace Rails.env
end
```

## Dynamic Settings

Load settings based on environment variables:

```ruby
class Settings < Settingslogic
  source ENV['SETTINGS_FILE'] || "#{Rails.root}/config/application.yml"
  namespace ENV['SETTINGS_NAMESPACE'] || Rails.env
end
```

## Testing

In your tests, you can override settings:

```ruby
# spec/spec_helper.rb or test/test_helper.rb
Settings.reload!
Settings['features']['enable_analytics'] = false
```

## Common Patterns

### Feature Flags

```yaml
features:
  new_dashboard: <%= ENV['FEATURE_NEW_DASHBOARD'] == 'true' %>
  beta_features: false
```

```ruby
if Settings.features.new_dashboard
  # Show new dashboard
else
  # Show old dashboard
end
```

### Environment-Specific Hosts

```yaml
development:
  api_host: http://localhost:3001
  
staging:
  api_host: https://staging-api.example.com
  
production:
  api_host: https://api.example.com
```

### Database Configuration

```yaml
database:
  adapter: postgresql
  host: <%= ENV['DB_HOST'] || 'localhost' %>
  port: <%= ENV['DB_PORT'] || 5432 %>
  username: <%= ENV['DB_USER'] %>
  password: <%= ENV['DB_PASSWORD'] %>
  database: <%= ENV['DB_NAME'] || 'myapp_development' %>
```

## Next Steps

- [Migration Guide](migration.md) - Upgrading from v2.x
- [Security Settings](SECURITY.md) - Understanding YAML security
- [Advanced Features](advanced.md) - Advanced configuration options