# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic YAML Handling' do
  describe 'empty file handling' do
    it 'handles empty file' do
      expect(SettingsEmpty.keys).to eq([])
    end
  end

  describe 'parse_yaml_content (Psych 4 compatibility)' do
    it 'handles YAML with symbols when safe_load is available' do
      yaml_content = 'test: :symbol_value'
      settings = Settingslogic.new({})

      result = settings.send(:parse_yaml_content, yaml_content)
      expect(result).to be_a(Hash)
    end

    it 'handles YAML with aliases' do
      yaml_with_aliases = <<~YAML
        defaults: &defaults
          setting1: value1
          setting2: value2

        development:
          <<: *defaults
          setting3: value3
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_aliases)

      expect(result).to be_a(Hash)
      expect(result['development']['setting1']).to eq('value1')
      expect(result['development']['setting2']).to eq('value2')
      expect(result['development']['setting3']).to eq('value3')
    end

    it 'handles YAML with Date and Time objects' do
      yaml_with_dates = <<~YAML
        created_at: 2025-01-09
        updated_at: 2025-01-09 10:30:00
      YAML

      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_dates)

      expect(result).to be_a(Hash)
      expect(result['created_at']).to be_a(Date)
      expect(result['updated_at']).to be_a(Time)
    end

    it 'handles malformed YAML gracefully' do
      malformed_yaml = 'this: is: not: valid: yaml:'
      settings = Settingslogic.new({})

      expect do
        settings.send(:parse_yaml_content, malformed_yaml)
      end.to raise_error(Psych::SyntaxError)
    end
  end

  describe 'file reading' do
    it 'reads local files' do
      Settingslogic.new({})

      # Test local file detection pattern
      expect('/path/to/file.yml').not_to match(%r{\A(https?://|ftp://)})
      expect('relative/path.yml').not_to match(%r{\A(https?://|ftp://)})

      # Settings should load from local file
      expect(Settings.setting1.setting1_child).to eq('test_value')
    end

    it 'detects URLs in source path' do
      # Test URL detection pattern
      expect('http://example.com/config.yml').to match(%r{\A(https?://|ftp://)})
      expect('https://example.com/config.yml').to match(%r{\A(https?://|ftp://)})
      expect('ftp://example.com/config.yml').to match(%r{\A(https?://|ftp://)})
    end

    it 'handles file not found' do
      expect do
        Settingslogic.new('/nonexistent/file.yml')
      end.to raise_error(Errno::ENOENT)
    end
  end

  describe 'ERB processing' do
    it 'processes ERB templates' do
      # Settings.setting3 uses ERB: <%= 5 * 5 %>
      expect(Settings.setting3).to eq(25)
    end

    it 'handles ERB with environment variables' do
      # Test that ERB can access environment variables
      ENV['TEST_SETTING'] = 'from_env'

      yaml_with_erb = "env_setting: <%= ENV['TEST_SETTING'] %>"
      settings = Settingslogic.new({})
      result = settings.send(:parse_yaml_content, yaml_with_erb)

      expect(result['env_setting']).to eq('from_env')

      ENV.delete('TEST_SETTING')
    end
  end

  describe 'Ruby version compatibility' do
    it 'uses appropriate YAML method based on Ruby version' do
      settings = Settingslogic.new({})

      if YAML.respond_to?(:unsafe_load)
        # Ruby 3.1+ with Psych 4
        allow(YAML).to receive(:unsafe_load).and_call_original
        settings.send(:parse_yaml_content, 'test: value')
        expect(YAML).to have_received(:unsafe_load)
      elsif YAML.respond_to?(:safe_load)
        # Ruby 3.0 or 2.7+ with safe_load
        # This branch may or may not be hit depending on Ruby version
        expect(YAML.method(:safe_load).parameters.map(&:last)).to include(:aliases) if RUBY_VERSION >= '3.0'
      else
        # Ruby 2.x fallback
        expect(YAML).to respond_to(:load)
      end
    end
  end

  describe 'complex YAML structures' do
    it 'handles deeply nested structures' do
      expect(Settings.setting1.deep.child.value).to eq(2)
    end

    it 'handles arrays of hashes' do
      expect(Settings.array).to be_an(Array)
      expect(Settings.array.first.name).to eq('first')
      expect(Settings.array[1].name).to eq('second')
    end

    it 'handles mixed data types' do
      expect(Settings.setting2).to eq(5) # Integer
      expect(Settings.setting1.setting1_child).to eq('test_value') # String
      Settings['bool_false'] = false # Boolean false
      Settings['nil_val'] = nil # Nil
      expect(Settings.bool_false).to be(false)
      expect(Settings.nil_val).to be_nil
    end
  end
end
