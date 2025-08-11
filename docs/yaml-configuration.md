# YAML Configuration

## Basic YAML Structure

```yaml
# Simple key-value pairs
app_name: My Application
version: 1.0.0
debug: true

# Nested structures
database:
  adapter: postgresql
  host: localhost
  port: 5432
  
# Arrays
allowed_hosts:
  - localhost
  - example.com
  - "*.example.com"
```

## Using YAML Anchors and Aliases

YAML anchors (`&`) and aliases (`*`) let you reuse configuration:

```yaml
# Define an anchor with &
defaults: &defaults
  timeout: 30
  retries: 3
  ssl: true

development:
  <<: *defaults  # Merge the defaults
  ssl: false     # Override specific values
  
production:
  <<: *defaults
  timeout: 60    # Override timeout for production
```

## ERB Processing

Settingslogic processes ERB before parsing YAML:

```yaml
# Environment variables
database:
  host: <%= ENV['DB_HOST'] || 'localhost' %>
  password: <%= ENV['DB_PASSWORD'] %>

# Ruby code
app:
  year: <%= Date.today.year %>
  version: <%= File.read('VERSION').strip %>
  
# Conditionals
features:
  debug: <%= Rails.env.development? %>
  ssl: <%= ENV['FORCE_SSL'] == 'true' %>
```

## Environment-Specific Configuration

### Rails Pattern

```yaml
defaults: &defaults
  app_name: My App
  session_timeout: 3600

development:
  <<: *defaults
  debug: true
  host: localhost:3000
  
test:
  <<: *defaults
  debug: false
  host: test.local
  
production:
  <<: *defaults
  debug: false
  host: example.com
  session_timeout: 7200
```

### Custom Environments

```yaml
defaults: &defaults
  base_setting: value

development:
  <<: *defaults
  
staging:
  <<: *defaults
  
production:
  <<: *defaults
  
custom_env:
  <<: *defaults
```

## Security Considerations

### Safe YAML Content

✅ **Allowed by default:**

```yaml
# Primitive types
string: "Hello"
number: 42
float: 3.14
boolean: true
null_value: null

# Collections
array: [1, 2, 3]
hash: {key: value}

# Symbols
environment: :production

# Dates and times
created_at: 2024-01-01
updated_at: 2024-01-01 10:30:00
```

### Unsafe YAML Content

❌ **Not allowed (will raise errors):**

```yaml
# Ruby objects (unless explicitly permitted)
processor: !ruby/object:CustomProcessor
  
# Regular expressions (unless added to permitted_classes)
pattern: !ruby/regexp /[a-z]+/

# Procs/lambdas
callback: !ruby/proc |
  Proc.new { |x| x * 2 }
```

## Advanced YAML Features

### Multi-line Strings

```yaml
# Literal style (preserves newlines)
description: |
  This is a long description
  that spans multiple lines
  and preserves formatting.

# Folded style (removes newlines)
summary: >
  This is a long summary
  that will be folded into
  a single line with spaces.
```

### Complex Nesting

```yaml
services:
  redis:
    default: &redis_defaults
      host: localhost
      port: 6379
      db: 0
    
    cache:
      <<: *redis_defaults
      db: 1
      
    sessions:
      <<: *redis_defaults
      db: 2
      
  elasticsearch:
    hosts:
      - host: localhost
        port: 9200
      - host: localhost
        port: 9201
```

## Best Practices

### 1. Use Descriptive Keys

```yaml
# Good
email_settings:
  smtp_host: smtp.gmail.com
  smtp_port: 587
  
# Avoid
email:
  host: smtp.gmail.com
  port: 587
```

### 2. Group Related Settings

```yaml
# Good - grouped by feature
authentication:
  session_timeout: 3600
  max_attempts: 5
  lockout_duration: 900

# Avoid - flat structure
session_timeout: 3600
max_login_attempts: 5
lockout_duration: 900
```

### 3. Use Environment Variables for Secrets

```yaml
# Good
api_keys:
  stripe: <%= ENV['STRIPE_API_KEY'] %>
  aws: <%= ENV['AWS_SECRET_KEY'] %>

# Never commit secrets directly
api_keys:
  stripe: sk_live_abcd1234  # NEVER DO THIS!
```

### 4. Document Your Settings

```yaml
# Cache configuration
cache:
  # Enable/disable caching globally
  enabled: true
  
  # TTL in seconds (default: 1 hour)
  ttl: 3600
  
  # Maximum cache size in MB
  max_size: 100
```

### 5. Validate in Code

```ruby
class Settings < Settingslogic
  source "config/settings.yml"
  namespace Rails.env
  
  # Add validation
  def validate!
    raise "Database host required" unless database.host
    raise "Invalid port" unless (1..65535).include?(database.port)
  end
end

# Call validation on boot
Settings.validate!
```

## Troubleshooting

### Common Errors

1. **Psych::DisallowedClass**
   - Cause: YAML contains Ruby objects not in permitted_classes
   - Fix: Update YAML or add to permitted_classes

2. **NoMethodError**
   - Cause: Trying to access non-existent setting
   - Fix: Check YAML structure and namespace

3. **SyntaxError in ERB**
   - Cause: Invalid Ruby code in ERB tags
   - Fix: Check ERB syntax in YAML file

### Debugging Tips

```ruby
# Check loaded settings
puts Settings.to_h

# Verify namespace
puts Settings.namespace

# Check source file
puts Settings.source

# Reload and debug
Settings.reload!
```