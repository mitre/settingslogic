# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic Dynamic Settings' do
  describe 'runtime modifications' do
    it 'raises error for missing settings then allows setting them' do
      e = nil
      begin
        Settings.language.erlang
      rescue StandardError => e
        expect(e).to be_a(Settingslogic::MissingSetting)
      end
      expect(e).not_to be_nil
      expect(e.message).to match(/Missing setting 'erlang' in 'language' section/)

      expect(Settings.language['erlang']).to be_nil
      Settings.language['erlang'] = 5
      expect(Settings.language['erlang']).to eq(5)

      Settings.language['erlang'] = { 'paradigm' => 'functional' }
      expect(Settings.language.erlang.paradigm).to eq('functional')
      expect(Settings.respond_to?(:erlang)).to be false
    end

    it 'handles symbol and string key assignment with reload' do
      Settings.reload!
      expect(Settings.language['erlang']).to be_nil

      Settings.language[:erlang] ||= 5
      expect(Settings.language[:erlang]).to eq(5)

      Settings.language[:erlang] = {}
      Settings.language[:erlang][:paradigm] = 'functional'
      expect(Settings.language.erlang.paradigm).to eq('functional')

      Settings[:toplevel] = '42'
      expect(Settings.toplevel).to eq('42')
    end

    it 'allows adding new top-level keys' do
      Settings[:new_key] = 'new_value'
      expect(Settings.new_key).to eq('new_value')
      expect(Settings[:new_key]).to eq('new_value')

      Settings.reload!
      expect(Settings[:new_key]).to be_nil
    end

    it 'allows adding nested hashes' do
      Settings[:nested_new] = {
        'level1' => {
          'level2' => 'deep_value'
        }
      }

      expect(Settings.nested_new.level1.level2).to eq('deep_value')
      expect(Settings[:nested_new]['level1']['level2']).to eq('deep_value')
    end

    it 'allows modifying existing settings' do
      original_value = Settings.setting2
      Settings[:setting2] = 999
      expect(Settings.setting2).to eq(999)

      Settings.reload!
      expect(Settings.setting2).to eq(original_value)
    end

    it 'handles symbol and string keys interchangeably' do
      Settings[:sym_key] = 'symbol_value'
      expect(Settings['sym_key']).to eq('symbol_value')

      Settings['str_key'] = 'string_value'
      expect(Settings[:str_key]).to eq('string_value')
    end

    it 'creates accessor methods for dynamic settings' do
      Settings[:dynamic_method] = 'dynamic_value'
      expect(Settings.dynamic_method).to eq('dynamic_value')

      # After reload, the accessor method should be gone
      Settings.reload!
      expect { Settings.dynamic_method }.to raise_error(Settingslogic::MissingSetting)
    end

    it 'handles ||= operator correctly' do
      # Test with non-existent key
      Settings[:new_default] ||= 'default_value'
      expect(Settings[:new_default]).to eq('default_value')

      # Should not override existing value
      Settings[:new_default] ||= 'other_value'
      expect(Settings[:new_default]).to eq('default_value')

      # Test with nil value
      Settings[:nil_key] = nil
      Settings[:nil_key] ||= 'not_nil'
      expect(Settings[:nil_key]).to eq('not_nil')

      # Test with false value
      Settings[:false_key] = false
      Settings[:false_key] ||= true
      expect(Settings[:false_key]).to be(true) # Because false is falsy
    end

    it 'handles nested dynamic settings' do
      Settings[:parent] = {}
      Settings[:parent][:child] = {}
      Settings[:parent][:child][:grandchild] = 'nested_value'

      expect(Settings.parent.child.grandchild).to eq('nested_value')
    end
  end

  describe 'reload functionality' do
    it 'reloads settings from source' do
      original = Settings.setting2
      Settings[:setting2] = 'modified'
      expect(Settings.setting2).to eq('modified')

      Settings.reload!
      expect(Settings.setting2).to eq(original)
    end

    it 'clears dynamic settings on reload' do
      Settings[:temporary] = 'temp_value'
      expect(Settings.temporary).to eq('temp_value')

      Settings.reload!
      expect { Settings.temporary }.to raise_error(Settingslogic::MissingSetting)
    end

    it 'returns true when calling load!' do
      expect(Settings.load!).to be(true)
    end
  end

  describe 'bracket notation' do
    it 'supports reading via brackets' do
      expect(Settings['setting2']).to eq(5)
      expect(Settings[:setting2]).to eq(5)
    end

    it 'supports writing via brackets' do
      Settings['new_bracket'] = 'bracket_value'
      expect(Settings.new_bracket).to eq('bracket_value')

      Settings[:new_symbol_bracket] = 'symbol_bracket_value'
      expect(Settings.new_symbol_bracket).to eq('symbol_bracket_value')
    end

    it 'handles nested bracket access' do
      expect(Settings['setting1']['setting1_child']).to eq('test_value')
      # Symbol access on nested settings returns nil, string access works
      expect(Settings['setting1']['setting1_child']).to eq('test_value')
    end
  end

  describe 'collision handling with dynamic settings' do
    it 'handles collisions when setting values' do
      Settings3[:nested] = 'modified'
      expect(Settings3.nested).to eq('modified')

      Settings3[:nested] = { 'new' => 'structure' }
      expect(Settings3.nested.new).to eq('structure')
    end
  end
end
