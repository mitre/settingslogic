# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic Data Conversion' do
  describe 'symbolize_keys' do
    it 'allows symbolize_keys' do
      Settings.reload!
      result = Settings.symbolize_keys
      expect(result).to be_a(Hash)
      expect(result.keys).to include(:setting1, :setting2, :language)
      expect(result[:setting1][:setting1_child]).to eq('test_value')
    end

    it 'allows symbolize_keys on nested hashes' do
      Settings.reload!
      result = Settings.language.symbolize_keys
      expect(result.keys).to include(:haskell, :smalltalk)
      expect(result[:haskell][:paradigm]).to eq('functional')
    end

    it 'converts all keys to symbols recursively' do
      Settings.reload!
      result = Settings.setting1.symbolize_keys
      expect(result[:setting1_child]).to eq('test_value')
      expect(result[:deep][:another]).to eq('my value')
      expect(result[:deep][:child][:value]).to eq(2)
    end

    it 'handles arrays properly in symbolize_keys' do
      Settings.reload!
      result = Settings.symbolize_keys
      expect(result[:array]).to be_an(Array)
      expect(result[:array].first[:name]).to eq('first')
    end

    it 'does not modify the original settings' do
      Settings.reload!
      original_keys = Settings.keys
      result = Settings.symbolize_keys

      expect(Settings.keys).to eq(original_keys)  # Original unchanged
      expect(result.keys).to all(be_a(Symbol))    # Result has symbols
    end
  end

  describe 'stringify_keys' do
    it 'converts all keys to strings' do
      Settings.reload!
      result = Settings.language.haskell.stringify_keys
      expect(result.class).to eq(Hash)
      expect(result).to eq({ 'paradigm' => 'functional' })
    end

    it 'works on nested hashes' do
      Settings.reload!
      result = Settings.language.stringify_keys
      expect(result).to eq({
                             'haskell' => { 'paradigm' => 'functional' },
                             'smalltalk' => { 'paradigm' => 'object oriented' }
                           })
    end

    it 'recursivelies stringify all keys' do
      Settings.reload!
      result = Settings.setting1.stringify_keys
      expect(result['setting1_child']).to eq('test_value')
      expect(result['deep']['another']).to eq('my value')
      expect(result['deep']['child']['value']).to eq(2)
    end

    it 'handles mixed key types' do
      # Add some symbol keys dynamically
      Settings[:symbol_key] = { symbol_child: 'value' }
      result = Settings.stringify_keys

      expect(result['symbol_key']).to be_a(Hash)
      expect(result['symbol_key']['symbol_child']).to eq('value')
    end

    it 'does not modify the original settings' do
      Settings.reload!
      original = Settings.language.to_hash
      result = Settings.language.stringify_keys

      expect(Settings.language.to_hash).to eq(original)
      expect(result.keys).to all(be_a(String))
    end
  end

  describe 'deep_merge' do
    it 'deeps merge settings' do
      Settings.reload!
      original = Settings.language.to_hash

      merged = Settings.language.deep_merge({
                                              'haskell' => { 'type_system' => 'static' },
                                              'ruby' => { 'paradigm' => 'object oriented' }
                                            })

      expect(merged['haskell']['paradigm']).to eq('functional')
      expect(merged['haskell']['type_system']).to eq('static')
      expect(merged['ruby']['paradigm']).to eq('object oriented')

      # Original should be unchanged
      expect(Settings.language['ruby']).to be_nil
      expect(Settings.language.to_hash).to eq(original)
    end

    it 'handles deeply nested merges' do
      Settings.reload!

      merged = Settings.setting1.deep_merge({
                                              'deep' => {
                                                'another' => 'overridden',
                                                'new_key' => 'new_value',
                                                'child' => {
                                                  'value' => 999,
                                                  'extra' => 'added'
                                                }
                                              }
                                            })

      expect(merged['deep']['another']).to eq('overridden')
      expect(merged['deep']['new_key']).to eq('new_value')
      expect(merged['deep']['child']['value']).to eq(999)
      expect(merged['deep']['child']['extra']).to eq('added')
    end

    it 'overrides non-hash values' do
      Settings.reload!

      merged = Settings.deep_merge({
                                     'setting2' => 999,
                                     'setting3' => 'string_now'
                                   })

      expect(merged['setting2']).to eq(999)
      expect(merged['setting3']).to eq('string_now')
    end

    it 'adds new keys' do
      Settings.reload!

      merged = Settings.deep_merge({
                                     'new_top_level' => {
                                       'nested' => 'value'
                                     }
                                   })

      expect(merged['new_top_level']['nested']).to eq('value')
      expect(merged['setting1']['setting1_child']).to eq('test_value')
    end
  end

  describe 'deep_merge!' do
    it 'deeps merge settings in place' do
      Settings.reload!
      Settings.language.deep_merge!({
                                      'haskell' => { 'type_system' => 'static' },
                                      'ruby' => { 'paradigm' => 'object oriented' }
                                    })

      expect(Settings.language['haskell']['paradigm']).to eq('functional')
      expect(Settings.language['haskell']['type_system']).to eq('static')
      expect(Settings.language['ruby']['paradigm']).to eq('object oriented')
    end

    it 'modifies the original object' do
      Settings.reload!
      original_object_id = Settings.language.object_id

      Settings.language.deep_merge!({
                                      'python' => { 'paradigm' => 'multi-paradigm' }
                                    })

      expect(Settings.language.object_id).to eq(original_object_id)
      expect(Settings.language['python']['paradigm']).to eq('multi-paradigm')
    end

    it 'handles complex nested structures' do
      Settings.reload!

      Settings.setting1.deep_merge!({
                                      'deep' => {
                                        'child' => {
                                          'new_sibling' => 'hello'
                                        }
                                      },
                                      'new_branch' => {
                                        'leaf' => 'world'
                                      }
                                    })

      expect(Settings.setting1.deep.child.value).to eq(2) # Original preserved
      expect(Settings.setting1.deep.child.new_sibling).to eq('hello') # New added
      expect(Settings.setting1.new_branch.leaf).to eq('world') # New branch added
    end
  end

  describe 'to_hash' do
    it 'returns a Hash instance' do
      result = Settings.to_hash
      expect(result).to be_a(Hash)
      expect(result.class.name).to eq('Hash')
    end

    it 'returns a new object' do
      result = Settings.to_hash
      expect(result.object_id).not_to eq(Settings.object_id)
    end

    it 'contains all the settings' do
      result = Settings.to_hash
      expect(result['setting1']['setting1_child']).to eq('test_value')
      expect(result['setting2']).to eq(5)
    end

    it 'handles nested Settingslogic objects' do
      result = Settings.setting1.to_hash
      expect(result).to be_a(Hash)
      expect(result['deep']['another']).to eq('my value')
    end
  end

  describe 'type conversions' do
    it 'preserves data types' do
      Settings[:integer_val] = 42
      Settings[:float_val] = 3.14
      Settings[:string_val] = 'text'
      Settings[:bool_true] = true
      Settings[:bool_false] = false
      Settings[:nil_val] = nil
      Settings[:array_val] = [1, 2, 3]
      Settings[:hash_val] = { 'key' => 'value' }

      expect(Settings.integer_val).to eq(42)
      expect(Settings.float_val).to eq(3.14)
      expect(Settings.string_val).to eq('text')
      expect(Settings.bool_true).to be(true)
      expect(Settings.bool_false).to be(false)
      expect(Settings.nil_val).to be_nil
      expect(Settings.array_val).to eq([1, 2, 3])
      expect(Settings.hash_val['key']).to eq('value')
    end
  end
end
