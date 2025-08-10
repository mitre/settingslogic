# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

describe 'Settingslogic Core Functionality' do
  describe 'basic settings access' do
    it 'accesses simple settings' do
      expect(Settings.setting2).to eq(5)
    end

    it 'accesses nested settings' do
      expect(Settings.setting1.setting1_child).to eq('test_value')
    end

    it 'accesses settings in nested arrays' do
      expect(Settings.array.first.name).to eq('first')
    end

    it 'accesses deep nested settings' do
      expect(Settings.setting1.deep.another).to eq('my value')
    end

    it 'accesses extra deep nested settings' do
      expect(Settings.setting1.deep.child.value).to eq(2)
    end

    it 'distinguishes nested keys' do
      expect(Settings.language.haskell.paradigm).to eq('functional')
      expect(Settings.language.smalltalk.paradigm).to eq('object oriented')
    end

    it 'handles settings with nil value' do
      Settings['flag'] = nil
      expect(Settings.flag).to be_nil
    end

    it 'handles settings with false value' do
      Settings['flag'] = false
      expect(Settings.flag).to be(false)
    end
  end

  describe 'namespacing' do
    it 'namespaces settings' do
      expect(Settings2.setting1_child).to eq('test_value')
      expect(Settings2.deep.another).to eq('my value')
    end

    it 'returns the namespace' do
      expect(Settings.namespace).to be_nil
      expect(Settings2.namespace).to eq('setting1')
    end
  end

  describe 'erb support' do
    it 'enables erb' do
      expect(Settings.setting3).to eq(25)
    end
  end

  describe 'hash access' do
    it 'is a hash subclass' do
      # Settings is a class that inherits from Settingslogic which inherits from Hash
      expect(Settings.ancestors).to include(Hash)
    end

    it 'returns a new instance of a Hash object' do
      expect(Settings.to_hash).to be_a(Hash)
      expect(Settings.to_hash.class.name).to eq('Hash')
      expect(Settings.to_hash.object_id).not_to eq(Settings.object_id)
    end
  end

  describe 'module name handling' do
    it 'responds with Module.name' do
      # Settings.yml has 'name: test' so Settings.name returns 'test'
      expect(Settings.name).to eq('test')
    end

    it 'has the parent class always respond with Module.name' do
      expect(Settings2.name).to eq('Settings2')
    end

    it 'allows a name setting to be overriden' do
      expect(Settings4.name).to eq('test')
    end
  end

  describe 'instance usage' do
    it 'supports instance usage as well' do
      settings = Settingslogic.new(Settings.source)
      expect(settings.setting1.setting1_child).to eq('test_value')
    end
  end

  describe 'dot notation access' do
    it 'is able to get() a key with dot.notation' do
      expect(Settings.get('setting1.setting1_child')).to eq('test_value')
      expect(Settings.get('setting1.deep.another')).to eq('my value')
      expect(Settings.get('setting1.deep.child.value')).to eq(2)
    end
  end

  describe 'collision handling' do
    it 'does not collide with global methods' do
      expect(Settings3.nested.collides.does).to eq('not either')
      Settings3[:nested] = 'fooey'
      expect(Settings3[:nested]).to eq('fooey')
      expect(Settings3.nested).to eq('fooey')
      expect(Settings3.collides.does).to eq('not')
    end
  end

  describe 'oddly-named settings' do
    it 'handles oddly-named settings' do
      Settings.language['some-dash-setting#'] = 'dashtastic'
      expect(Settings.language['some-dash-setting#']).to eq('dashtastic')
    end
  end
end
