# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  desc 'Run RuboCop'
  task :rubocop do
    puts 'RuboCop not available. Install it with: gem install rubocop'
  end
end

# Security audit task
desc 'Run security audit on dependencies'
task :audit do
  begin
    require 'bundler/audit/cli'
    Bundler::Audit::CLI.start(['check', '--update'])
  rescue LoadError
    puts 'bundler-audit not available. Install it with: gem install bundler-audit'
    puts 'Run: gem install bundler-audit'
  end
end

desc 'Run all checks (specs, rubocop, audit)'
task check: [:spec, :rubocop, :audit]

# Console for testing
desc 'Open IRB console with settingslogic loaded'
task :console do
  require 'irb'
  require_relative 'lib/settingslogic'
  ARGV.clear
  IRB.start
end

# Default task
task default: [:spec]

# Release preparation
desc 'Prepare for release (run all checks)'
task prepare_release: [:spec, :rubocop, :audit] do
  puts "\n✅ All checks passed! Ready to release."
  puts "\nNext steps:"
  puts "1. Update version in lib/settingslogic/version.rb"
  puts "2. Update CHANGELOG.md"
  puts "3. Commit changes"
  puts "4. Run: bundle exec rake release"
end