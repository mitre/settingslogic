# Basic Usage

## Creating a Settings Class

The simplest way to use Settingslogic is to create a class that inherits from it:

```ruby
class Settings < Settingslogic
  source "config/settings.yml"
end
```

## Loading Settings

### From a File

```ruby
class Settings < Settingslogic
  source "/path/to/settings.yml"
end
```

### From a Hash

```ruby
class Settings < Settingslogic
  source({
    host: "localhost",
    port: 3000,
    features: {
      caching: true
    }
  })
end
```

### With Environment Namespace

```ruby
class Settings < Settingslogic
  source "config/settings.yml"
  namespace ENV['APP_ENV'] || 'development'
end
```

## Accessing Settings

### Dot Notation

```ruby
Settings.app_name           # => "My App"
Settings.database.host      # => "localhost"
Settings.features.caching   # => true
```

### Hash Access

```ruby
Settings['app_name']           # => "My App"
Settings['database']['host']   # => "localhost"
Settings[:app_name]            # => "My App" (symbols work too)
```

### Checking for Keys

```ruby
Settings.has_key?(:app_name)   # => true
Settings.app_name?              # => true (convenience method)
Settings.missing_key?           # => false
```

## Default Values

### In YAML

```yaml
defaults: &defaults
  host: localhost
  port: 3000

development:
  <<: *defaults
  port: 3001  # Override default

production:
  <<: *defaults
  host: example.com
```

### In Code

```ruby
# Use || for defaults
host = Settings.host || 'localhost'

# Use fetch with default
port = Settings.fetch(:port, 3000)
```

## Reloading Settings

```ruby
# Reload settings from file
Settings.reload!

# Useful in development or when files change
Rails.application.config.to_prepare do
  Settings.reload!
end
```

## Multiple Settings Files

```ruby
class AppSettings < Settingslogic
  source "config/app.yml"
  namespace Rails.env
end

class EmailSettings < Settingslogic
  source "config/email.yml"
  namespace Rails.env
end

# Usage
AppSettings.name      # From app.yml
EmailSettings.host    # From email.yml
```

## Settings in Different Environments

```yaml
# config/settings.yml
development:
  debug: true
  cache: false
  
test:
  debug: false
  cache: false
  
production:
  debug: false
  cache: true
```

```ruby
class Settings < Settingslogic
  source "config/settings.yml"
  namespace Rails.env  # Automatically selects the right section
end
```

## Using with Rails

### In Initializers

```ruby
# config/initializers/settings.rb
class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  
  # Optional: suppress errors in test/development
  suppress_errors Rails.env.development? || Rails.env.test?
end
```

### In Controllers

```ruby
class ApplicationController < ActionController::Base
  helper_method :app_settings
  
  def app_settings
    @app_settings ||= Settings
  end
end
```

### In Views

```erb
<%= Settings.app_name %>
<%= Settings.contact.email %>
```

## Using with Sinatra

```ruby
require 'sinatra'
require 'settingslogic'

class Settings < Settingslogic
  source "config/settings.yml"
  namespace ENV['RACK_ENV'] || 'development'
end

get '/' do
  "Welcome to #{Settings.app_name}"
end
```

## Common Patterns

### Feature Toggles

```yaml
features:
  new_ui: true
  beta_features: false
  maintenance_mode: false
```

```ruby
if Settings.features.new_ui
  render 'new_layout'
else
  render 'old_layout'
end
```

### API Configuration

```yaml
apis:
  stripe:
    key: <%= ENV['STRIPE_KEY'] %>
    secret: <%= ENV['STRIPE_SECRET'] %>
  aws:
    region: us-east-1
    access_key: <%= ENV['AWS_ACCESS_KEY'] %>
```

```ruby
Stripe.api_key = Settings.apis.stripe.key
AWS.config(region: Settings.apis.aws.region)
```