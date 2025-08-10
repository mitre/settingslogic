# Coverage Analysis - Missing 9.68%
## Current Coverage: 90.32% (112/124 lines)
## Uncovered: 12 lines

### Uncovered Lines Analysis

#### 1. **Line 189: Nested symbolize_keys recursion** 
```ruby
v.symbolize_keys  # When value itself responds to symbolize_keys
```
- **Why uncovered**: Only triggers when a nested value has its own `symbolize_keys` method (not a Settingslogic object)
- **Impact**: Low - edge case for custom objects
- **To cover**: Would need mock objects with symbolize_keys method

#### 2. **Lines 242-252: Ruby 2.x/3.0 YAML fallback paths**
```ruby
elsif YAML.respond_to?(:safe_load)  # Line 242
  # Ruby 3.0 path
  YAML.safe_load(erb_result, aliases: true, permitted_classes: [Symbol, Date, Time]).to_hash  # Line 245
rescue ArgumentError  # Line 246
  # Older Ruby without aliases parameter
  YAML.load(erb_result).to_hash  # Line 248
else
  # Ruby 2.x fallback
  YAML.load(erb_result).to_hash  # Line 252
```
- **Why uncovered**: We're testing on Ruby 3.1.6 which uses `YAML.unsafe_load` (line 241)
- **Impact**: Low - these are fallbacks for older Ruby versions
- **To cover**: Would need to test on Ruby 2.7 or 3.0, or mock YAML methods

#### 3. **Lines 256-259: Psych error handling**
```ruby
if defined?(Psych::VERSION) && Psych::VERSION >= '4.0.0'  # Line 256
  raise MissingSetting, "YAML file contains aliases but they are disabled..."  # Line 257
else
  raise e  # Line 259
```
- **Why uncovered**: This error path only triggers on specific Psych errors that our unsafe_load handles
- **Impact**: Low - edge case error handling
- **To cover**: Would need to trigger Psych::DisallowedClass or Psych::BadAlias errors

#### 4. **Lines 268-271: URL loading code**
```ruby
if defined?(URI) && URI.respond_to?(:open)  # Line 268
  URI.open(source).read  # Line 269
else
  open(source).read  # Line 271 - deprecated open-uri fallback
```
- **Why uncovered**: We only test URL pattern detection, not actual URL fetching
- **Impact**: Medium - URL loading is a documented feature
- **To cover**: Would need to mock URI.open or use webmock gem

### Summary by Category

1. **Ruby Version Compatibility (6 lines)**: Lines 242, 245-248, 252
   - Fallback paths for Ruby 2.x and 3.0
   - Not needed on Ruby 3.1+

2. **URL Loading (4 lines)**: Lines 268-271  
   - Remote configuration file loading
   - Would need HTTP mocking to test

3. **Edge Case Error Handling (2 lines)**: Lines 256-257, 259
   - Specific Psych error scenarios
   - Difficult to trigger naturally

### Recommendations

**Priority to reach 95%+:**
1. Add URL loading tests with WebMock gem (4 lines)
2. Mock YAML methods to test version fallbacks (6 lines)

**Not worth covering:**
- Edge case error paths that would require complex mocking
- The deprecated `open()` fallback (line 271)

### Code to Add for 95% Coverage

```ruby
# spec/yaml_handling_spec.rb additions

describe "URL loading" do
  require 'webmock/rspec'
  
  it "should load configuration from URL" do
    stub_request(:get, "https://example.com/config.yml")
      .to_return(body: "setting: value")
    
    settings = Settingslogic.new("https://example.com/config.yml")
    expect(settings['setting']).to eq('value')
  end
end

describe "Ruby version fallbacks" do
  it "should use safe_load on Ruby 3.0" do
    allow(YAML).to receive(:respond_to?).with(:unsafe_load).and_return(false)
    allow(YAML).to receive(:respond_to?).with(:safe_load).and_return(true)
    allow(YAML).to receive(:safe_load).and_return({'test' => 'value'})
    
    settings = Settingslogic.new({})
    result = settings.send(:parse_yaml_content, "test: value")
    expect(result).to eq({'test' => 'value'})
  end
end
```