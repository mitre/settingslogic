# Testing

## Testing Your Settings

### Basic Test Setup

```ruby
# spec/models/settings_spec.rb
require 'rails_helper'

RSpec.describe Settings do
  describe 'configuration' do
    it 'loads the settings file' do
      expect(Settings.app_name).not_to be_nil
    end
    
    it 'uses the correct environment' do
      expect(Settings.namespace).to eq(Rails.env)
    end
    
    it 'has required settings' do
      expect(Settings.database.host).not_to be_nil
      expect(Settings.database.port).to be_a(Integer)
    end
  end
end
```

### Testing with Different Settings

```ruby
RSpec.describe MyService do
  context 'with caching enabled' do
    before do
      allow(Settings.features).to receive(:caching).and_return(true)
    end
    
    it 'uses cache' do
      expect(Rails.cache).to receive(:fetch)
      MyService.new.perform
    end
  end
  
  context 'with caching disabled' do
    before do
      allow(Settings.features).to receive(:caching).and_return(false)
    end
    
    it 'skips cache' do
      expect(Rails.cache).not_to receive(:fetch)
      MyService.new.perform
    end
  end
end
```

## Test Helpers

### Settings Test Helper

Create a helper for managing settings in tests:

```ruby
# spec/support/settings_helper.rb
module SettingsHelper
  def with_modified_settings
    original_settings = Settings.to_h.deep_dup
    yield
  ensure
    Settings.reload!
  end
  
  def stub_settings(overrides)
    overrides.each do |keys, value|
      keys = keys.to_s.split('.') if keys.is_a?(Symbol)
      keys = [keys] unless keys.is_a?(Array)
      
      stub_nested_setting(Settings, keys, value)
    end
  end
  
  private
  
  def stub_nested_setting(obj, keys, value)
    if keys.length == 1
      allow(obj).to receive(keys.first).and_return(value)
    else
      nested = double
      allow(obj).to receive(keys.first).and_return(nested)
      stub_nested_setting(nested, keys[1..-1], value)
    end
  end
end

RSpec.configure do |config|
  config.include SettingsHelper
end
```

### Using the Helper

```ruby
RSpec.describe OrderService do
  it 'sends email when enabled' do
    stub_settings('email.enabled' => true, 'email.from' => 'test@example.com')
    
    expect(OrderMailer).to receive(:confirmation)
    OrderService.new.process_order
  end
  
  it 'skips email when disabled' do
    stub_settings('email.enabled' => false)
    
    expect(OrderMailer).not_to receive(:confirmation)
    OrderService.new.process_order
  end
end
```

## Testing settingslogic Itself

### Unit Tests

```ruby
# spec/unit/settingslogic_spec.rb
require 'spec_helper'
require 'settingslogic'

RSpec.describe Settingslogic do
  let(:settings_class) do
    Class.new(Settingslogic) do
      source({ 
        'name' => 'Test App',
        'nested' => { 'value' => 42 }
      })
    end
  end
  
  describe '#[]' do
    it 'accesses values by string key' do
      expect(settings_class['name']).to eq('Test App')
    end
    
    it 'accesses values by symbol key' do
      expect(settings_class[:name]).to eq('Test App')
    end
    
    it 'accesses nested values' do
      expect(settings_class['nested']['value']).to eq(42)
    end
  end
  
  describe '#method_missing' do
    it 'provides method access to settings' do
      expect(settings_class.name).to eq('Test App')
    end
    
    it 'provides method access to nested settings' do
      expect(settings_class.nested.value).to eq(42)
    end
    
    it 'returns nil for missing settings' do
      expect(settings_class.missing).to be_nil
    end
  end
end
```

### Testing YAML Loading

```ruby
RSpec.describe 'YAML loading' do
  let(:yaml_file) { Rails.root.join('spec', 'fixtures', 'test_settings.yml') }
  
  before do
    File.write(yaml_file, <<~YAML)
      test:
        app_name: Test Application
        features:
          api: true
          cache: false
    YAML
  end
  
  after do
    File.delete(yaml_file) if File.exist?(yaml_file)
  end
  
  it 'loads YAML file correctly' do
    settings = Class.new(Settingslogic) do
      source yaml_file.to_s
      namespace 'test'
    end
    
    expect(settings.app_name).to eq('Test Application')
    expect(settings.features.api).to be true
    expect(settings.features.cache).to be false
  end
end
```

### Testing Security Features

```ruby
RSpec.describe 'Security features' do
  context 'YAML.safe_load' do
    it 'rejects unsafe YAML by default' do
      unsafe_yaml = "exploit: !ruby/object:Kernel {}"
      
      expect {
        YAML.safe_load(unsafe_yaml, permitted_classes: Settingslogic.yaml_permitted_classes)
      }.to raise_error(Psych::DisallowedClass)
    end
    
    it 'allows permitted classes' do
      safe_yaml = "date: 2024-01-01\ntime: 2024-01-01 10:00:00"
      
      result = YAML.safe_load(safe_yaml, permitted_classes: Settingslogic.yaml_permitted_classes)
      expect(result['date']).to be_a(Date)
      expect(result['time']).to be_a(Time)
    end
  end
  
  context 'permitted_classes configuration' do
    it 'can add additional permitted classes' do
      original = Settingslogic.yaml_permitted_classes.dup
      
      Settingslogic.yaml_permitted_classes += [Regexp]
      expect(Settingslogic.yaml_permitted_classes).to include(Regexp)
      
      Settingslogic.yaml_permitted_classes = original
    end
  end
end
```

## Integration Tests

### Rails Integration Test

```ruby
# spec/integration/rails_settings_spec.rb
require 'rails_helper'

RSpec.describe 'Rails settings integration', type: :request do
  it 'uses settings in controllers' do
    get '/'
    expect(response.body).to include(Settings.app_name)
  end
  
  it 'settings persist across requests' do
    get '/'
    first_response = response.body
    
    get '/'
    second_response = response.body
    
    expect(first_response).to eq(second_response)
  end
end
```

### Testing Environment-Specific Settings

```ruby
RSpec.describe 'Environment settings' do
  it 'loads development settings in development' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
    
    settings = Class.new(Settingslogic) do
      source Rails.root.join('config', 'application.yml')
      namespace Rails.env
      reload!
    end
    
    expect(settings.debug).to be true
  end
  
  it 'loads production settings in production' do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    
    settings = Class.new(Settingslogic) do
      source Rails.root.join('config', 'application.yml')
      namespace Rails.env
      reload!
    end
    
    expect(settings.debug).to be false
  end
end
```

## Testing Best Practices

### 1. Isolate Settings in Tests

```ruby
RSpec.describe MyService do
  let(:service) { described_class.new }
  
  # Good - isolates the setting being tested
  it 'respects timeout setting' do
    allow(Settings).to receive(:timeout).and_return(5)
    
    expect(service.timeout).to eq(5)
  end
  
  # Avoid - changes global state
  it 'respects timeout setting' do
    Settings.timeout = 5  # Don't do this!
    
    expect(service.timeout).to eq(5)
  end
end
```

### 2. Test Settings Validation

```ruby
RSpec.describe Settings do
  describe '.validate!' do
    it 'raises error for missing required settings' do
      allow(Settings).to receive(:database).and_return(nil)
      
      expect { Settings.validate! }.to raise_error(/database required/)
    end
    
    it 'passes for valid settings' do
      expect { Settings.validate! }.not_to raise_error
    end
  end
end
```

### 3. Test ERB Processing

```ruby
RSpec.describe 'ERB in settings' do
  it 'processes ERB tags' do
    yaml_content = <<~YAML
      test:
        year: <%= Date.today.year %>
        calculated: <%= 5 + 5 %>
    YAML
    
    Tempfile.create(['settings', '.yml']) do |file|
      file.write(yaml_content)
      file.flush
      
      settings = Class.new(Settingslogic) do
        source file.path
        namespace 'test'
      end
      
      expect(settings.year).to eq(Date.today.year)
      expect(settings.calculated).to eq(10)
    end
  end
end
```

### 4. Test Error Handling

```ruby
RSpec.describe 'Error handling' do
  it 'raises error for missing file without suppress_errors' do
    expect {
      Class.new(Settingslogic) do
        source '/nonexistent/file.yml'
      end.load!
    }.to raise_error(Errno::ENOENT)
  end
  
  it 'returns empty settings with suppress_errors' do
    settings = Class.new(Settingslogic) do
      source '/nonexistent/file.yml'
      suppress_errors true
    end
    
    expect(settings.to_h).to eq({})
  end
end
```

## Continuous Integration

### GitHub Actions Example

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: '3.2'
        bundler-cache: true
    
    - name: Run tests
      run: |
        bundle exec rspec
    
    - name: Test settings loading
      run: |
        bundle exec rspec spec/models/settings_spec.rb
```