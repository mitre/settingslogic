# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic Error Handling' do
  describe 'missing settings' do
    it 'raises a helpful error message for missing top-level keys' do
      e = nil
      begin
        Settings.missing
      rescue StandardError => e
        expect(e).to be_a(Settingslogic::MissingSetting)
      end
      expect(e).not_to be_nil
      expect(e.message).to match(/Missing setting 'missing' in/)
    end

    it 'raises a helpful error message for missing nested keys' do
      e = nil
      begin
        Settings.language.missing
      rescue StandardError => e
        expect(e).to be_a(Settingslogic::MissingSetting)
      end
      expect(e).not_to be_nil
      expect(e.message).to match(/Missing setting 'missing' in 'language' section/)
    end

    it 'raises error for deeply nested missing keys' do
      expect do
        Settings.setting1.deep.nonexistent.value
      end.to raise_error(Settingslogic::MissingSetting, /Missing setting 'nonexistent'/)
    end

    it 'returns nil for missing keys when using bracket notation' do
      expect(Settings['nonexistent']).to be_nil
      expect(Settings[:nonexistent]).to be_nil
      expect(Settings.language['nonexistent']).to be_nil
    end
  end

  describe 'error suppression' do
    let(:suppressed_class) do
      # Create a test class with suppressed errors
      Class.new(Settingslogic) do
        suppress_errors true
        source "#{File.dirname(__FILE__)}/settings.yml"
      end
    end

    it 'allows suppressing errors' do
      expect(suppressed_class.nonexistent).to be_nil
      expect(suppressed_class.language.nonexistent).to be_nil
      expect(suppressed_class.setting1.deep.nonexistent).to be_nil
    end

    it 'stills return valid values when errors are suppressed' do
      expect(suppressed_class.setting2).to eq(5)
      expect(suppressed_class.setting1.setting1_child).to eq('test_value')
    end

    it 'allows checking suppress_errors setting' do
      expect(Settings.suppress_errors).to be_falsy
      expect(suppressed_class.suppress_errors).to be_truthy
    end
  end

  describe 'nil source handling' do
    it 'raises an error on a nil source argument' do
      expect do
        Class.new(Settingslogic).new(nil)
      end.to raise_error(Errno::ENOENT, /No file specified as Settingslogic source/)
    end

    it 'raises an error when source is not set' do
      no_source_class = Class.new(Settingslogic)
      expect do
        no_source_class.setting1
      end.to raise_error(Errno::ENOENT, /No file specified as Settingslogic source/)
    end
  end

  describe 'invalid file handling' do
    it 'raises error for non-existent files' do
      expect do
        Settingslogic.new('/this/file/does/not/exist.yml')
      end.to raise_error(Errno::ENOENT)
    end

    it 'handles invalid YAML syntax' do
      # Create a temporary file with invalid YAML
      invalid_yaml_path = "/tmp/invalid_settings_#{Process.pid}.yml"
      File.write(invalid_yaml_path, 'this: is: not: valid: yaml:')

      expect do
        Settingslogic.new(invalid_yaml_path)
      end.to raise_error(Psych::SyntaxError)

      FileUtils.rm_f(invalid_yaml_path)
    end
  end

  describe 'namespace errors' do
    it 'raises error for missing namespace' do
      expect do
        Class.new(Settingslogic) do
          source "#{File.dirname(__FILE__)}/settings.yml"
          namespace 'nonexistent_namespace'
        end.setting1
      end.to raise_error(Settingslogic::MissingSetting, /Missing setting 'nonexistent_namespace'/)
    end
  end

  describe 'Psych 4 specific errors' do
    it 'handles Psych::DisallowedClass gracefully' do
      settings = Settingslogic.new({})

      # File is NOT in our permitted classes, so this should be rejected
      yaml_with_object = 'test: !ruby/object:File {}'

      # The parse_yaml_content method should handle this by converting to MissingSetting
      # We expect it to raise MissingSetting with helpful error message, not raw Psych::DisallowedClass
      expect do
        settings.send(:parse_yaml_content, yaml_with_object)
      end.to raise_error(Settingslogic::MissingSetting) do |error|
        expect(error.message).to include('disallowed class')
        expect(error.message).to include('To fix this, you have two options:')
      end
    end

    it 'provides helpful error for YAML aliases when disabled' do
      if defined?(Psych::VERSION) && Psych::VERSION >= '4.0.0'
        # In Psych 4+, our implementation should handle aliases correctly
        yaml_with_aliases = <<~YAML
          defaults: &defaults
            key: value
          production:
            <<: *defaults
        YAML

        settings = Settingslogic.new({})
        expect do
          settings.send(:parse_yaml_content, yaml_with_aliases)
        end.not_to raise_error
      end
    end
  end

  describe 'method_missing behavior' do
    it 'onlies raise errors for method-like keys' do
      expect do
        Settings.valid_method_name
      end.to raise_error(Settingslogic::MissingSetting)

      # Keys with special characters should return nil via brackets
      expect(Settings['key-with-dashes']).to be_nil
      expect(Settings['key.with.dots']).to be_nil
    end
  end

  describe 'error message quality' do
    it 'includes the section context in error messages' do
      expect do
        Settings.language.ruby
      end.to raise_error(Settingslogic::MissingSetting, /Missing setting 'ruby' in/)
    end

    it 'shows the correct file in top-level errors' do
      expect do
        Settings.totally_missing
      end.to raise_error(Settingslogic::MissingSetting, /in.*settings\.yml/)
    end
  end
end
