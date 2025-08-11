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
  require 'bundler/audit/cli'
  Bundler::Audit::CLI.start(['check', '--update'])
rescue LoadError
  puts 'bundler-audit not available. Install it with: gem install bundler-audit'
  puts 'Run: gem install bundler-audit'
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

# Version management helpers
require 'fileutils'

def version_file
  'lib/settingslogic/version.rb'
end

def current_version
  require_relative version_file
  Settingslogic::VERSION
end

def update_version(new_version)
  content = File.read(version_file)
  content.gsub!(/VERSION = ["'][\d.]+["']/, "VERSION = '#{new_version}'")
  File.write(version_file, content)
  puts "Updated version to #{new_version}"
  
  # Update Gemfile.lock to match new version
  puts "Updating Gemfile.lock..."
  system('bundle install')
end

def update_changelog(version, type)
  changelog = 'CHANGELOG.md'

  # Check if git-cliff is available
  has_git_cliff = system('which git-cliff > /dev/null 2>&1')

  if has_git_cliff
    # Use git-cliff to generate changelog
    puts 'Generating changelog with git-cliff...'
    system("git-cliff --tag v#{version} --output #{changelog}")
    puts "✅ Generated CHANGELOG.md with git-cliff for version #{version}"
  else
    # Fallback to manual changelog update
    date = Time.now.strftime('%Y-%m-%d')

    # Read existing changelog
    content = File.read(changelog)

    # Prepare new entry based on type
    new_entry = case type
                when :patch
                  "## [#{version}] - #{date}\n\n### Fixed\n- Bug fixes and minor improvements\n\n"
                when :minor
                  "## [#{version}] - #{date}\n\n### Added\n- New features\n\n### Changed\n- Improvements\n\n"
                when :major
                  "## [#{version}] - #{date}\n\n### Breaking Changes\n- Breaking changes\n\n" \
                  "### Added\n- New features\n\n"
                else
                  "## [#{version}] - #{date}\n\n### Changed\n- Updates\n\n"
                end

    # Insert after the header
    content.sub!(/^(# Changelog.*?\n\n)/m, "\\1#{new_entry}")
    File.write(changelog, content)
    puts "✅ Updated CHANGELOG.md manually for version #{version}"
    puts '💡 Install git-cliff for automatic changelog generation: brew install git-cliff'
  end
end

def git_status_clean?
  `git status --porcelain`.empty?
end

def on_main_branch?
  `git rev-parse --abbrev-ref HEAD`.strip == 'main'
end

# Changelog task
desc 'Generate CHANGELOG.md using git-cliff'
task :changelog do
  if system('which git-cliff > /dev/null 2>&1')
    puts 'Generating CHANGELOG.md with git-cliff...'
    system('git-cliff --output CHANGELOG.md')
    puts '✅ CHANGELOG.md generated successfully'
  else
    puts '❌ git-cliff not installed. Install with: brew install git-cliff'
    exit 1
  end
end

# Version tasks
namespace :version do
  desc 'Show current version'
  task :show do
    puts "Current version: #{current_version}"
  end

  desc 'Bump patch version (e.g., 3.0.0 -> 3.0.1)'
  task :patch do
    parts = current_version.split('.')
    new_version = "#{parts[0]}.#{parts[1]}.#{parts[2].to_i + 1}"
    update_version(new_version)
    update_changelog(new_version, :patch)
  end

  desc 'Bump minor version (e.g., 3.0.0 -> 3.1.0)'
  task :minor do
    parts = current_version.split('.')
    new_version = "#{parts[0]}.#{parts[1].to_i + 1}.0"
    update_version(new_version)
    update_changelog(new_version, :minor)
  end

  desc 'Bump major version (e.g., 3.0.0 -> 4.0.0)'
  task :major do
    parts = current_version.split('.')
    new_version = "#{parts[0].to_i + 1}.0.0"
    update_version(new_version)
    update_changelog(new_version, :major)
  end
end

# Release tasks
namespace :release do
  desc 'Prepare patch release'
  task patch: ['version:patch', :check] do
    prepare_release_commit
  end

  desc 'Prepare minor release'
  task minor: ['version:minor', :check] do
    prepare_release_commit
  end

  desc 'Prepare major release'
  task major: ['version:major', :check] do
    prepare_release_commit
  end

  desc 'Create and push release tag'
  task :tag do
    abort 'ERROR: Must be on main branch to create a release tag' unless on_main_branch?

    abort 'ERROR: Working directory not clean. Commit changes first.' unless git_status_clean?

    version = current_version
    tag = "v#{version}"

    puts "\n📦 Creating release tag #{tag}..."

    # Create annotated tag
    sh "git tag -a #{tag} -m 'Release version #{version}'"

    puts "\n📤 Pushing tag to origin..."
    sh "git push origin #{tag}"

    puts "\n✅ Release tag #{tag} created and pushed!"
    puts "\n🚀 GitHub Actions will now:"
    puts '  1. Run all tests'
    puts '  2. Create GitHub Release'
    puts '  3. Publish gem to RubyGems'
    puts "\nMonitor progress at: https://github.com/mitre/settingslogic/actions"
  end
end

def prepare_release_commit
  version = current_version

  # Check git status
  puts 'WARNING: Not on main branch' unless on_main_branch?

  # Stage changes
  sh "git add #{version_file} CHANGELOG.md"

  # Show what will be committed
  puts "\n📝 Changes to be committed:"
  sh 'git diff --cached --stat'

  puts "\n💡 To complete the release:"
  puts '  1. Review and update CHANGELOG.md if needed'
  puts "  2. Commit: git commit -m 'Bump version to #{version}"
  puts ''
  puts "     Authored by: Aaron Lippold<lippold@gmail.com>'"
  puts '  3. Push: git push origin main'
  puts '  4. Create tag: bundle exec rake release:tag'
end

# Quick release commands (combines everything)
desc 'Quick patch release (bump, test, commit, tag, push)'
task 'release:quick:patch' do
  Rake::Task['release:patch'].invoke

  if git_status_clean?
    puts 'No changes to commit'
  else
    version = current_version
    sh %(git commit -m "Bump version to #{version}\n\nAuthored by: Aaron Lippold<lippold@gmail.com>")
    sh 'git push origin main'
  end

  Rake::Task['release:tag'].invoke
end

desc 'Quick minor release (bump, test, commit, tag, push)'
task 'release:quick:minor' do
  Rake::Task['release:minor'].invoke

  if git_status_clean?
    puts 'No changes to commit'
  else
    version = current_version
    sh %(git commit -m "Bump version to #{version}\n\nAuthored by: Aaron Lippold<lippold@gmail.com>")
    sh 'git push origin main'
  end

  Rake::Task['release:tag'].invoke
end

desc 'Quick major release (bump, test, commit, tag, push)'
task 'release:quick:major' do
  Rake::Task['release:major'].invoke

  if git_status_clean?
    puts 'No changes to commit'
  else
    version = current_version
    sh %(git commit -m "Bump version to #{version}\n\nAuthored by: Aaron Lippold<lippold@gmail.com>")
    sh 'git push origin main'
  end

  Rake::Task['release:tag'].invoke
end

# Helpful info task
desc 'Show release process help'
task 'release:help' do
  puts <<~HELP

    SETTINGSLOGIC RELEASE PROCESS
    ==============================

    Standard Release (interactive):
    -------------------------------
    1. bundle exec rake release:patch   # or :minor, :major
    2. Review CHANGELOG.md and make edits
    3. git commit -m "Bump version to X.Y.Z
    #{"   "}
       Authored by: Aaron Lippold<lippold@gmail.com>"
    4. git push origin main
    5. bundle exec rake release:tag

    Quick Release (automated):
    -------------------------
    bundle exec rake release:quick:patch   # Everything in one command
    bundle exec rake release:quick:minor
    bundle exec rake release:quick:major

    Version Commands:
    ----------------
    bundle exec rake version:show    # Show current version
    bundle exec rake version:patch   # Bump patch version
    bundle exec rake version:minor   # Bump minor version#{"  "}
    bundle exec rake version:major   # Bump major version

    Other Commands:
    --------------
    bundle exec rake check           # Run all tests/checks
    bundle exec rake spec            # Run tests only
    bundle exec rake rubocop         # Run linter only
    bundle exec rake audit           # Run security audit only

  HELP
end

# Add help to default rake -T output
desc 'Show release help'
task help: 'release:help'
