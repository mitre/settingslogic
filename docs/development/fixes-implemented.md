# Settingslogic - Fixes to Implement
## Date: January 9, 2025

### Priority 1: Critical Fixes (Must Have)

#### 1. Psych 4 / Ruby 3.1+ Compatibility
**Issue**: Ruby 3.1+ ships with Psych 4 which disables YAML aliases by default
**Error**: `Psych::AliasesNotEnabled: Aliases are not enabled`
**Sources**: 
- PR #86 on original repo
- minorun99/settingslogic fork
- etozzato/settingslogic fork

**Fix to implement**:
```ruby
# In lib/settingslogic.rb around line 105
# Replace:
hash = YAML.load(ERB.new(File.read(hash_or_file)).result).to_hash

# With:
def parse_yaml_content(file_content)
  erb_result = ERB.new(file_content).result
  if YAML.respond_to?(:unsafe_load)
    # Ruby 3.1+ with Psych 4
    YAML.unsafe_load(erb_result).to_hash
  else
    # Ruby 2.x/3.0 with Psych 3
    YAML.load(erb_result).to_hash
  end
rescue Psych::DisallowedClass => e
  # Alternative approach using safe_load with aliases
  YAML.safe_load(erb_result, aliases: true).to_hash
end
```

#### 2. Ruby 3.2 Keyword Arguments Warnings
**Issue**: Ruby 3.2 has stricter keyword argument handling
**Source**: minorun99/settingslogic fork

**Fix**: Update method signatures to use explicit keyword arguments where needed

### Priority 2: Compatibility Fixes

#### 3. Array#flatten Fix for RSpec
**Issue**: `Array#flatten` calls `to_ary` on elements, causing MissingSetting errors
**Source**: PR #36 on original repo
**Affects**: RSpec tests that include Settings objects in arrays

**Fix to implement**:
```ruby
# Add to Settingslogic class
def to_ary
  nil  # Prevents Array#flatten from trying to expand Settings objects
end
```

#### 4. stringify_keys Compatibility (Rails 4.2+)
**Issue**: `stringify_keys` returns whole config instead of just the keys
**Source**: Issue #85

**Fix**: Override stringify_keys method properly

#### 5. Fix eval Security Warnings
**Issue**: Using eval with string interpolation triggers security warnings
**Source**: etozzato fork improvements

**Fix to implement**:
```ruby
# Replace eval with instance_eval and proper line numbers
instance_eval "def #{key}; instance.send(:#{key}); end", __FILE__, __LINE__
```

### Priority 3: Quality Improvements

#### 6. Better Error Messages
**Issue**: Missing settings errors don't always show helpful context
**Fix**: Improve error messages to show full key path

#### 7. symbolize_keys Improvements
**Source**: etozzato fork
**Fix**: Use `each_with_object` instead of `inject` for clarity

#### 8. Code Style Updates
- Use frozen string literals
- Replace deprecated `has_key?` with `key?`
- Use safe navigation operator where appropriate
- Fix rubocop warnings

### Testing Requirements

Each fix needs tests for:
- Ruby 2.7, 3.0, 3.1, 3.2, 3.3
- Rails 5.2, 6.0, 6.1, 7.0, 7.1, 8.0
- YAML with and without aliases
- Settings with nested hashes
- Settings with arrays

### Files to Modify

1. **lib/settingslogic.rb**
   - Main library file
   - All compatibility fixes go here

2. **settingslogic.gemspec**
   - Update version to 3.0.0
   - Update maintainer info
   - Add development dependencies for testing
   - Specify Ruby version requirement

3. **Gemfile**
   - Modernize for development
   - Add rubocop, simplecov

4. **.github/workflows/ci.yml** (new file)
   - Test matrix for Ruby versions
   - Test matrix for Rails versions
   - Rubocop checks
   - Coverage reporting

5. **README.md** (rename from README.rdoc)
   - Convert to Markdown
   - Add MITRE fork information
   - Document Ruby 3 compatibility
   - Add badges for CI status

6. **spec/settingslogic_spec.rb**
   - Add tests for Psych 4 compatibility
   - Add tests for Ruby 3.x features
   - Add tests for all fixes

### Implementation Order

1. Create feature branch: `ruby-3-compatibility`
2. Implement Psych 4 fix (Priority 1)
3. Add Ruby 3.x tests
4. Implement other fixes
5. Update documentation
6. Add GitHub Actions
7. Test in Vulcan application
8. Create pull request
9. Tag release v3.0.0

### Verification Checklist

- [ ] Tests pass on Ruby 2.7
- [ ] Tests pass on Ruby 3.0
- [ ] Tests pass on Ruby 3.1
- [ ] Tests pass on Ruby 3.2
- [ ] Tests pass on Ruby 3.3
- [ ] YAML aliases work (`<<: *defaults`)
- [ ] No deprecation warnings
- [ ] Vulcan application works with the fork
- [ ] Rubocop passes
- [ ] Documentation updated

### Notes from Other Forks

**minorun99/settingslogic**:
- Has basic Psych 4 fix with try/catch approach
- Tested with Ruby 3.2

**etozzato/settingslogic**:
- Uses YAML.safe_load with aliases: true
- Better code style (frozen strings, etc.)
- Improved error handling

**Armatic/settingslogic** (Jan 2025):
- Recent fork, check for any new fixes

**Best practices to incorporate**:
- Use safe_load when possible
- Better line number tracking in evals
- Frozen string literals
- Modern Ruby idioms

---
*Document created: January 9, 2025*
*Purpose: Track all fixes needed for MITRE settingslogic fork*