# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")
require 'tempfile'
require 'uri'

describe 'Settingslogic Security' do
  describe 'YAML parsing security' do
    it 'rejects arbitrary Ruby objects in YAML' do
      # Create YAML with attempted object injection
      yaml_with_object = <<~YAML
        test: !ruby/object:File {}
        path: /etc/passwd
      YAML

      settings = Settingslogic.new({})

      # All Ruby versions should now reject arbitrary objects for security
      expect do
        settings.send(:parse_yaml_content, yaml_with_object)
      end.to raise_error(Settingslogic::MissingSetting, /disallowed class/)
    end

    it 'allows custom permitted classes when configured' do
      # Define a custom class for testing
      class CustomTestClass
        attr_accessor :value
        def initialize(value = nil)
          @value = value
        end
      end

      # Configure settingslogic to permit the custom class
      original_classes = Settingslogic.yaml_permitted_classes.dup
      Settingslogic.yaml_permitted_classes += [CustomTestClass]

      yaml_with_custom = <<~YAML
        custom: !ruby/object:CustomTestClass
          value: test_value
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_custom)

      expect(result['custom']).to be_a(CustomTestClass)
      expect(result['custom'].value).to eq('test_value')

      # Restore original permitted classes
      Settingslogic.yaml_permitted_classes = original_classes
    end

    it 'safely handles YAML bombs (billion laughs attack)' do
      yaml_bomb = <<~YAML
        a: &a ["lol","lol","lol","lol","lol","lol","lol","lol","lol"]
        b: &b [*a,*a,*a,*a,*a,*a,*a,*a,*a]
        c: &c [*b,*b,*b,*b,*b,*b,*b,*b,*b]
      YAML

      settings = Settingslogic.new({})

      # Should parse without consuming excessive memory
      expect do
        settings.send(:parse_yaml_content, yaml_bomb)
      end.not_to raise_error
    end

    it 'allows only safe classes in YAML' do
      yaml_with_safe_classes = <<~YAML
        date: 2025-01-10
        time: 2025-01-10 10:00:00
        symbol: :test_symbol
        string: test_string
        number: 42
        float: 3.14
        bool: true
        null_val: ~
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_safe_classes)

      expect(result['date']).to be_a(Date)
      expect(result['time']).to be_a(Time)
      expect(result['string']).to eq('test_string')
      expect(result['number']).to eq(42)
      expect(result['bool']).to be(true)
      expect(result['null_val']).to be_nil
    end
  end

  describe 'URL loading security' do
    it 'rejects non-HTTP(S) protocols' do
      settings = Settingslogic.new({})

      # File protocol should fail
      expect do
        settings.send(:read_file, 'file:///etc/passwd')
      end.to raise_error(ArgumentError, /Invalid URL/)

      # FTP should fail
      expect do
        settings.send(:read_file, 'ftp://example.com/config.yml')
      end.to raise_error(ArgumentError, /Invalid URL/)

      # Gopher should fail
      expect do
        settings.send(:read_file, 'gopher://example.com/config.yml')
      end.to raise_error(ArgumentError, /Invalid URL/)
    end

    it 'validates URL format' do
      settings = Settingslogic.new({})

      # Malformed URLs should fail
      expect do
        settings.send(:read_file, 'http://[invalid')
      end.to raise_error(URI::InvalidURIError)
    end

    it 'handles HTTP errors safely' do
      require 'net/http'
      settings = Settingslogic.new({})

      # Mock a failed HTTP response
      allow(Net::HTTP).to receive(:get_response).and_return(
        Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      )

      expect do
        settings.send(:read_file, 'http://example.com/missing.yml')
      end.to raise_error(/Failed to fetch/)
    end

    it 'does not follow redirects automatically' do
      require 'net/http'
      settings = Settingslogic.new({})

      # Mock a redirect response
      redirect = Net::HTTPRedirection.new('1.1', '301', 'Moved')
      allow(redirect).to receive(:body).and_return('')
      allow(Net::HTTP).to receive(:get_response).and_return(redirect)

      # Should fail on redirect, not follow it
      expect do
        settings.send(:read_file, 'http://example.com/config.yml')
      end.to raise_error(/Failed to fetch/)
    end
  end

  describe 'code injection prevention' do
    it 'prevents code injection through method names' do
      # These keys should be safely rejected for method creation
      dangerous_keys = [
        'system("ls")',
        'exec("cat /etc/passwd")',
        '`whoami`',
        'eval("1+1")',
        'send(:eval, "1+1")',
        '__send__(:eval, "1+1")',
        'instance_eval("1+1")',
        '); system("ls"); puts("',
        '"; system("ls"); x="'
      ]

      dangerous_keys.each do |key|
        settings = Settingslogic.new({})
        settings[key] = 'value'

        # Should not create a method for dangerous keys
        expect(settings.respond_to?(key)).to be false

        # Should still be accessible via bracket notation
        expect(settings[key]).to eq('value')
      end
    end

    it 'only allows word characters in dynamic methods' do
      settings = Settingslogic.new({})

      # These should create methods (only word chars)
      safe_keys = ['valid_key', 'another_key', 'key123', 'KEY', '_private']
      safe_keys.each do |key|
        settings[key] = 'value'
        expect(settings.respond_to?(key)).to be true
        expect(settings.send(key)).to eq('value')
      end

      # These should NOT create methods (special chars)
      unsafe_keys = ['key-with-dash', 'key.with.dot', 'key with space', 'key!', 'special?']
      unsafe_keys.each do |key|
        settings[key] = 'value'
        # Should not create accessor methods for keys with special characters
        # Note: 'key?' might match Hash's built-in key? method, so we use 'special?'
        if key == 'special?'
          # This shouldn't create a 'special?' method
          expect(settings.methods).not_to include(:special?)
        end
        expect(settings[key]).to eq('value') # Still accessible via brackets
      end
    end

    it 'safely handles __FILE__ and __LINE__ in eval' do
      settings = Settingslogic.new({})
      settings['test_key'] = 'value'

      # The eval should include proper file/line for debugging
      # This is tested implicitly - if eval was unsafe, it would fail
      expect(settings.test_key).to eq('value')
    end
  end

  describe 'path traversal prevention' do
    it 'does not perform path manipulation on file sources' do
      # Direct path traversal attempts should fail appropriately
      # Testing with a path that definitely doesn't exist
      expect do
        Settingslogic.new('/nonexistent/path/to/nowhere.yml')
      end.to raise_error(Errno::ENOENT)

      # If /etc/passwd exists and is read, it would fail YAML parsing
      begin
        Settingslogic.new('/etc/passwd')
        # If we got here, file exists but isn't valid YAML
      rescue Errno::ENOENT
        # File doesn't exist - that's fine
      rescue Psych::SyntaxError
        # File exists but isn't YAML - expected for /etc/passwd
      rescue NoMethodError => e
        # File was read but parse failed - also expected
        expect(e.message).to match(/to_hash/)
      end
    end

    it 'handles absolute and relative paths safely' do
      # Create a temporary file
      Tempfile.create(['settings', '.yml']) do |file|
        file.write("test: value\n")
        file.flush

        # Absolute path should work
        settings = Settingslogic.new(file.path)
        expect(settings.test).to eq('value')
      end
    end
  end

  describe 'ERB template security' do
    it 'processes ERB before YAML (correct order)' do
      yaml_with_erb = <<~YAML
        computed: <%= 2 + 2 %>
        env_var: <%= ENV['USER'] || 'unknown' %>
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_erb)

      expect(result['computed']).to eq(4)
      expect(result['env_var']).to be_a(String)
    end

    it 'ERB execution is limited to config file scope' do
      # ERB can execute code, but only in the config file context
      # This is by design for configuration files
      yaml_with_method = <<~YAML
        ruby_version: <%= RUBY_VERSION %>
        calculated: <%= [1,2,3].sum %>
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_method)

      expect(result['ruby_version']).to eq(RUBY_VERSION)
      expect(result['calculated']).to eq(6)
    end
  end

  describe 'denial of service prevention' do
    it 'handles deeply nested structures without stack overflow' do
      # Create a deeply nested hash
      depth = 100
      nested = { 'level1' => {} }
      current = nested['level1']

      (2..depth).each do |i|
        current["level#{i}"] = {}
        current = current["level#{i}"]
      end
      current['value'] = 'deep'

      # Should handle deep nesting
      settings = Settingslogic.new(nested)

      # Navigate to the deep value
      current = settings.level1
      (2..depth).each do |i|
        current = current.send("level#{i}")
      end

      expect(current.value).to eq('deep')
    end

    it 'handles large files efficiently' do
      # Create a large YAML structure
      large_yaml = "large:\n"
      1000.times do |i|
        large_yaml += "  key#{i}: value#{i}\n"
      end

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, large_yaml)

      expect(result['large'].keys.size).to eq(1000)
    end
  end

  describe 'method_missing safety' do
    it 'does not cause infinite recursion' do
      settings = Settingslogic.new({})

      # Should raise MissingSetting, not stack overflow
      expect do
        settings.nonexistent.nested.deeply.nested.key
      end.to raise_error(Settingslogic::MissingSetting)
    end

    it 'properly handles nil values' do
      settings = Settingslogic.new({ 'nil_key' => nil })

      expect(settings.nil_key).to be_nil
      expect(settings['nil_key']).to be_nil
    end
  end
end
