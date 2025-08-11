# Migration from v2.x to v3.0

## Breaking Changes

Version 3.0.0 introduces critical security fixes that may break existing applications that rely on YAML's ability to instantiate arbitrary Ruby objects.

### Main Change: YAML.safe_load

The primary breaking change is the switch from `YAML.load` to `YAML.safe_load` for security reasons.

**Before (v2.x):**
```ruby
# This could instantiate any Ruby object
YAML.load(yaml_content)  # DANGEROUS!
```

**After (v3.0):**
```ruby
# Only allows safe, primitive types by default
YAML.safe_load(yaml_content, permitted_classes: [Symbol, Date, Time, DateTime, BigDecimal])
```

## Migration Options

### Option 1: Update Your YAML Files (Recommended)

Review your YAML configuration files and ensure they only use primitive types:

✅ **Safe types (work by default):**
- Strings, Numbers, Booleans, nil
- Arrays and Hashes
- Symbols (e.g., `:production`)
- Dates and Times
- BigDecimal numbers

❌ **Unsafe types (will cause errors):**
- Custom Ruby objects
- Procs/lambdas
- Regular expressions (unless added to permitted_classes)

### Option 2: Add Permitted Classes

If you need additional Ruby classes in your YAML:

```ruby
# Add to an initializer (Rails) or before loading settings
Settingslogic.yaml_permitted_classes += [Regexp, MyCustomClass]
```

### Option 3: Temporary Compatibility Mode (Deprecated)

⚠️ **Warning:** This option is deprecated and will be removed in v4.0.0

```ruby
# Temporarily restore old behavior (DANGEROUS - DO NOT USE IN PRODUCTION)
Settingslogic.use_yaml_unsafe_load = true
```

This will show a deprecation warning and should only be used during migration.

## Common Migration Issues

### Issue 1: Regular Expressions

**Problem:**
```yaml
# This will fail in v3.0
validation:
  email_regex: !ruby/regexp /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
```

**Solution 1: Store as string and convert in code**
```yaml
validation:
  email_pattern: '\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z'
```

```ruby
email_regex = Regexp.new(Settings.validation.email_pattern, Regexp::IGNORECASE)
```

**Solution 2: Add Regexp to permitted classes**
```ruby
Settingslogic.yaml_permitted_classes += [Regexp]
```

### Issue 2: Custom Classes

**Problem:**
```yaml
# This will fail in v3.0
payment:
  processor: !ruby/object:PaymentProcessor
    gateway: stripe
    mode: production
```

**Solution: Use a hash and instantiate in code**
```yaml
payment:
  processor:
    type: PaymentProcessor
    gateway: stripe
    mode: production
```

```ruby
processor = PaymentProcessor.new(
  gateway: Settings.payment.processor.gateway,
  mode: Settings.payment.processor.mode
)
```

### Issue 3: Date/Time Objects

**Problem:**
```yaml
# May fail depending on format
schedule:
  start_date: 2024-01-01 09:00:00
```

**Solution: Dates and times are already permitted**
```yaml
# These formats work automatically
schedule:
  start_date: 2024-01-01
  start_time: "09:00:00"
  start_datetime: 2024-01-01 09:00:00
```

## Testing Your Migration

1. **Update the gem:**
   ```bash
   bundle update mitre-settingslogic
   ```

2. **Test in development:**
   ```bash
   rails console
   > Settings.reload!
   ```

3. **Check for errors:**
   - Look for `Psych::DisallowedClass` errors
   - These indicate YAML content that needs to be updated

4. **Run your test suite:**
   ```bash
   bundle exec rspec
   ```

## Gradual Migration Strategy

For large applications:

1. **Phase 1:** Add deprecation warning monitoring
   ```ruby
   # In an initializer
   Settingslogic.use_yaml_unsafe_load = true  # Temporary
   
   # Log deprecation warnings
   ActiveSupport::Deprecation.behavior = [:log, :notify]
   ```

2. **Phase 2:** Identify and fix issues one by one
   - Review logs for YAML loading issues
   - Update YAML files incrementally
   - Add necessary permitted classes

3. **Phase 3:** Remove compatibility mode
   ```ruby
   # Remove this line
   # Settingslogic.use_yaml_unsafe_load = true
   ```

## Getting Help

If you encounter issues during migration:

1. Check the [Security documentation](SECURITY.md)
2. Review the [CHANGELOG](CHANGELOG.md)
3. Open an issue on [GitHub](https://github.com/mitre/settingslogic/issues)