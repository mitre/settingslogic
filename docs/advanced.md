# Advanced Features

## Custom Loading Behavior

### Suppress Errors

During development, you might want to suppress missing file errors:

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  suppress_errors true  # Don't raise errors if file is missing
end
```

### Load on Demand

By default, settings are loaded when first accessed. Force immediate loading:

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  load!  # Load immediately
end
```

### Custom Load Paths

```ruby
class Settings < Settingslogic
  # Try multiple locations
  possible_files = [
    "#{Rails.root}/config/application.yml",
    "#{Rails.root}/config/settings.yml",
    "/etc/myapp/settings.yml"
  ]
  
  source possible_files.find { |f| File.exist?(f) }
end
```

## Dynamic Configuration

### Environment-Based Loading

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/#{Rails.env}.yml"
end
```

### Conditional Namespaces

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  
  # Use different namespace based on conditions
  namespace ENV['DEPLOYED'] ? 'production' : Rails.env
end
```

### Multiple Namespace Levels

```yaml
# config/application.yml
production:
  us_east:
    host: us-east.example.com
  us_west:
    host: us-west.example.com
  eu:
    host: eu.example.com
```

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  
  # Access nested namespace
  def self.for_region(region)
    self[Rails.env][region]
  end
end

# Usage
Settings.for_region('us_east').host  # => "us-east.example.com"
```

## Method Missing Magic

Settingslogic uses `method_missing` to provide dynamic accessors:

```ruby
Settings.some_setting  # Calls method_missing
Settings.some_setting = "value"  # Also works for assignment
```

### Adding Custom Methods

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Add custom helper methods
  def self.redis_url
    "redis://#{redis.host}:#{redis.port}/#{redis.db}"
  end
  
  def self.database_url
    "#{database.adapter}://#{database.username}@#{database.host}/#{database.name}"
  end
end
```

## Inheritance and Composition

### Inheriting Settings

```ruby
class BaseSettings < Settingslogic
  source "#{Rails.root}/config/base.yml"
end

class AppSettings < BaseSettings
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end
```

### Composing Multiple Settings

```ruby
class Settings
  class << self
    def app
      @app ||= AppSettings.new
    end
    
    def database
      @database ||= DatabaseSettings.new
    end
    
    def redis
      @redis ||= RedisSettings.new
    end
  end
end

# Usage
Settings.app.name
Settings.database.host
Settings.redis.port
```

## Testing Helpers

### Stubbing Settings in Tests

```ruby
# spec/support/settings_helper.rb
module SettingsHelper
  def with_settings(overrides)
    original = Settings.to_h.deep_dup
    
    overrides.each do |key, value|
      Settings[key] = value
    end
    
    yield
  ensure
    Settings.reload!
    Settings.replace(original)
  end
end

# In your tests
it "uses custom timeout" do
  with_settings(timeout: 10) do
    expect(Settings.timeout).to eq(10)
  end
end
```

### Test-Specific Settings

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Allow overrides in test environment
  if Rails.env.test?
    def self.override!(hash)
      hash.each { |k, v| self[k] = v }
    end
    
    def self.reset!
      reload!
    end
  end
end
```

## Performance Optimization

### Caching Settings

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Cache expensive computations
  def self.processed_allowlist
    @processed_allowlist ||= allowlist.map(&:downcase).uniq
  end
  
  # Clear cache on reload
  def self.reload!
    @processed_allowlist = nil
    super
  end
end
```

### Lazy Loading

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Don't load until actually needed
  def self.optional_features
    @optional_features ||= begin
      if File.exist?("#{Rails.root}/config/features.yml")
        YAML.safe_load_file("#{Rails.root}/config/features.yml")
      else
        {}
      end
    end
  end
end
```

## Integration Patterns

### Rails Integration

```ruby
# config/initializers/settings.rb
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end

# Make available in views
ActionView::Base.send :include, SettingsHelper

module SettingsHelper
  def app_settings
    Settings
  end
end
```

### Sinatra Integration

```ruby
# app.rb
require 'sinatra/base'
require 'settingslogic'

class MyApp < Sinatra::Base
  class Settings < Settingslogic
    source File.join(File.dirname(__FILE__), 'config', 'settings.yml')
    namespace ENV['RACK_ENV'] || 'development'
  end
  
  helpers do
    def settings
      Settings
    end
  end
end
```

### Rake Task Integration

```ruby
# lib/tasks/settings.rake
namespace :settings do
  desc "Display current settings"
  task show: :environment do
    puts Settings.to_h.to_yaml
  end
  
  desc "Validate settings"
  task validate: :environment do
    Settings.reload!
    puts "✓ Settings are valid"
  rescue => e
    puts "✗ Settings error: #{e.message}"
    exit 1
  end
end
```

## Debugging

### Inspecting Settings

```ruby
# See all settings as a hash
Settings.to_h

# Pretty print settings
require 'pp'
pp Settings.to_h

# Get YAML representation
puts Settings.to_yaml

# Check specific paths
Settings.dig('database', 'host')
```

### Tracing Setting Access

```ruby
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Log all setting access in development
  if Rails.env.development?
    def self.method_missing(name, *args, &block)
      Rails.logger.debug "Settings access: #{name}"
      super
    end
  end
end
```

## Best Practices

1. **Keep settings immutable in production**
2. **Use descriptive key names**
3. **Group related settings together**
4. **Document complex settings with comments**
5. **Validate critical settings on boot**
6. **Use environment variables for secrets**
7. **Version control your default settings**
8. **Keep environment-specific overrides minimal**