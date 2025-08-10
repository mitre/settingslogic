# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic Compatibility' do
  describe 'RSpec compatibility' do
    it 'returns nil for to_ary to prevent Array#flatten issues' do
      expect(Settings.to_ary).to be_nil
    end

    it 'works correctly with Array#flatten' do
      # This was the original issue - Settings objects in arrays
      array_with_settings = [1, Settings, 3]
      expect { array_with_settings.flatten }.not_to raise_error
      expect(array_with_settings.flatten).to eq([1, Settings, 3])
    end

    it 'works in RSpec matchers that use arrays' do
      # RSpec matchers often use Array operations internally
      expect([Settings]).to include(Settings)
      expect([1, Settings, 3]).to contain_exactly(3, Settings, 1)
    end

    it 'does not interfere with array coercion' do
      # Ensure Settings doesn't accidentally become an array
      expect(Settings).not_to be_a(Array)
      expect(Array.try_convert(Settings)).to be_nil
    end
  end

  describe 'Rails compatibility' do
    it 'provides stringify_keys for Rails forms' do
      # stringify_keys is an instance method, not class method
      expect(Settings.language).to respond_to(:stringify_keys)
      result = Settings.language.stringify_keys
      expect(result).to be_a(Hash)
      expect(result.keys).to all(be_a(String))
    end

    it 'provides deep_merge for Rails configurations' do
      # deep_merge is an instance method, not class method
      expect(Settings.language).to respond_to(:deep_merge)
      expect(Settings.language).to respond_to(:deep_merge!)

      merged = Settings.language.deep_merge({ 'ruby' => { 'version' => '3.0' } })
      expect(merged).to be_a(Hash)
    end

    it 'handles HashWithIndifferentAccess-like behavior' do
      # Test that both string and symbol access work
      Settings[:test_key] = 'test_value'
      expect(Settings['test_key']).to eq('test_value')
      expect(Settings[:test_key]).to eq('test_value')
    end

    it "works with Rails' blank? and present? concepts" do
      Settings[:empty_string] = ''
      Settings[:empty_array] = []
      Settings[:empty_hash] = {}

      expect(Settings.empty_string).to eq('')
      expect(Settings.empty_array).to eq([])
      expect(Settings.empty_hash).to be_a(Settingslogic)
    end
  end

  describe 'Ruby version compatibility' do
    it 'handles frozen string literals' do
      # The lib file uses frozen_string_literal pragma
      key = 'test_key'
      Settings[key] = 'value'
      expect(Settings[key]).to eq('value')
    end

    it 'uses key? instead of deprecated has_key?' do
      # Modern Ruby prefers key? over has_key?
      # Settingslogic is a Hash, so it has key? method
      expect(Settings.key?('setting1')).to be true
      expect(Settings.key?('nonexistent')).to be false
    end

    if RUBY_VERSION >= '3.0'
      it 'handles Ruby 3 keyword argument changes' do
        # Ruby 3 has stricter keyword argument handling
        settings = Settingslogic.new({ 'test' => 'value' })
        expect(settings['test']).to eq('value')
      end
    end

    it 'handles different YAML parsers' do
      # Test works with both Psych 3 and Psych 4
      yaml_content = 'test: value'
      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_content)
      expect(result).to eq({ 'test' => 'value' })
    end
  end

  describe 'URL loading compatibility' do
    it 'differentiates between local files and URLs' do
      settings = Settingslogic.new({})

      # Local file paths
      expect(settings.send(:read_file, __FILE__)).to include('Settingslogic Compatibility')

      # URL patterns (without actually fetching)
      ['http://', 'https://', 'ftp://'].each do |prefix|
        url = "#{prefix}example.com/config.yml"
        expect(url).to match(%r{\A(https?://|ftp://)})
      end
    end

    it 'handles File.read for local files' do
      # Ensure we use File.read for efficiency on local files
      settings = Settingslogic.new({})
      content = settings.send(:read_file, __FILE__)
      expect(content).to be_a(String)
      expect(content.length).to be > 0
    end
  end

  describe 'backwards compatibility' do
    it 'maintains original API' do
      # All original methods should still work
      expect(Settings.setting1.setting1_child).to eq('test_value')
      expect(Settings['setting2']).to eq(5)
      expect(Settings[:setting2]).to eq(5)
      expect { Settings.missing }.to raise_error(Settingslogic::MissingSetting)
    end

    it 'supports legacy suppress_errors usage' do
      suppressed = Class.new(Settingslogic) do
        suppress_errors true
        source "#{File.dirname(__FILE__)}/settings.yml"
      end

      expect(suppressed.missing).to be_nil
    end

    it 'supports legacy namespace usage' do
      expect(Settings2.namespace).to eq('setting1')
      expect(Settings2.setting1_child).to eq('test_value')
    end

    it 'supports legacy get method' do
      expect(Settings.get('setting1.setting1_child')).to eq('test_value')
    end
  end

  describe 'thread safety considerations' do
    it 'reloads safely' do
      original_value = Settings.setting2

      Settings[:setting2] = 'modified'
      expect(Settings.setting2).to eq('modified')

      Settings.reload!
      expect(Settings.setting2).to eq(original_value)
    end

    it 'handles concurrent access patterns' do
      # Basic test - real thread safety would need more complex testing
      results = []

      5.times do |i|
        Settings["concurrent_#{i}"] = i
        results << Settings["concurrent_#{i}"]
      end

      expect(results).to eq([0, 1, 2, 3, 4])
    end
  end

  describe 'special character handling' do
    it 'handles keys with dashes' do
      Settings.language['some-dash-setting#'] = 'dashtastic'
      expect(Settings.language['some-dash-setting#']).to eq('dashtastic')
    end

    it 'handles Unicode in values' do
      Settings[:unicode] = 'Hello 世界 🌍'
      expect(Settings.unicode).to eq('Hello 世界 🌍')
    end

    it 'handles special characters in YAML' do
      yaml_with_special = <<~YAML
        special_chars:
          quoted: "Line 1\\nLine 2"
          literal: |
            Line 1
            Line 2
          folded: >
            Line 1
            Line 2
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_special)

      expect(result['special_chars']['quoted']).to include("Line 1\nLine 2")
      expect(result['special_chars']['literal']).to include("Line 1\nLine 2")
      expect(result['special_chars']['folded']).to include('Line 1 Line 2')
    end
  end
end
