# frozen_string_literal: true

# Setup code coverage
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
  add_group 'Library', 'lib'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec'
require 'settingslogic'
require 'settings'
require 'settings2'
require 'settings3'
require 'settings4'
require 'settings_empty'

# Needed to test Settings3
Object.send :define_method, 'collides' do
  'collision'
end

RSpec.configure do |config|
  # Standard RSpec configuration
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
