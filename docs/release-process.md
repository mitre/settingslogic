# Release Process

## Overview

This document describes the release process for mitre-settingslogic gem.

## Automated Release Process

Releases are automated via GitHub Actions when a tag is pushed.

### Quick Release Commands

For patch releases (bug fixes):
```bash
bundle exec rake release:quick:patch
```

For minor releases (new features):
```bash
bundle exec rake release:quick:minor
```

For major releases (breaking changes):
```bash
bundle exec rake release:quick:major
```

These commands will:
1. Bump the version
2. Update CHANGELOG.md
3. Run tests
4. Commit changes
5. Create and push a git tag
6. Trigger automated gem publication

## Manual Release Process

### 1. Update Version

Edit `lib/settingslogic/version.rb`:
```ruby
module Settingslogic
  VERSION = "3.0.1"  # Update this
end
```

Or use rake tasks:
```bash
bundle exec rake version:patch  # 3.0.0 -> 3.0.1
bundle exec rake version:minor  # 3.0.0 -> 3.1.0
bundle exec rake version:major  # 3.0.0 -> 4.0.0
```

### 2. Update CHANGELOG

Update `CHANGELOG.md` with release notes:
```markdown
## [3.0.1] - 2024-01-11

### Fixed
- Documentation updates
- License specification corrected to Apache-2.0

### Changed
- Renamed default branch from master to main
```

### 3. Run Tests

Ensure all tests pass:
```bash
bundle exec rspec
bundle exec rubocop
bundle exec rake audit
```

### 4. Commit Changes

```bash
git add -A
git commit -m "Bump version to 3.0.1

Authored by: Aaron Lippold<lippold@gmail.com>"
git push origin main
```

### 5. Create Release Tag

```bash
bundle exec rake release:tag
```

Or manually:
```bash
git tag -a v3.0.1 -m "Release version 3.0.1"
git push origin v3.0.1
```

### 6. GitHub Actions

The push of the tag triggers the `.github/workflows/release.yml` workflow which:
1. Runs all tests
2. Creates a GitHub Release
3. Publishes the gem to RubyGems via OIDC

## Release Checklist

Before releasing:

- [ ] All tests pass locally
- [ ] RuboCop shows no violations
- [ ] Security audit passes (`bundle exec rake audit`)
- [ ] CHANGELOG.md is updated
- [ ] Version number is bumped appropriately
- [ ] Documentation is up to date
- [ ] CI/CD pipeline is green

## Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0) - Incompatible API changes
- **MINOR** version (0.X.0) - Backwards-compatible functionality additions
- **PATCH** version (0.0.X) - Backwards-compatible bug fixes

### Examples:

- Security fix that changes behavior: MAJOR
- Adding new configuration options: MINOR
- Fixing a bug: PATCH
- Documentation updates: PATCH

## OIDC Trusted Publishing

This gem uses OIDC trusted publishing for secure, token-less releases to RubyGems.

### Setup (Already Complete)

1. Gem is registered on RubyGems as `mitre-settingslogic`
2. OIDC trusted publisher configured for `mitre/settingslogic` repository
3. GitHub Actions workflow uses `rubygems/configure-rubygems-credentials@v1.0.0`

### How It Works

1. Push a tag starting with `v` (e.g., `v3.0.1`)
2. GitHub Actions workflow runs
3. OIDC token is exchanged for temporary RubyGems credentials
4. Gem is built and pushed automatically

No API keys or secrets are stored in the repository.

## Troubleshooting

### Release Workflow Fails

1. Check GitHub Actions logs
2. Ensure tag format is correct (`v` prefix)
3. Verify OIDC publisher configuration on RubyGems

### Gem Push Permission Denied

- Ensure you're listed as an owner on RubyGems
- Check that gem name matches: `mitre-settingslogic`

### Tests Fail on Release

- Fix the failing tests
- Delete the tag: `git tag -d v3.0.1 && git push origin :v3.0.1`
- Start the release process again

## Post-Release

After a successful release:

1. Verify gem on RubyGems: https://rubygems.org/gems/mitre-settingslogic
2. Test installation: `gem install mitre-settingslogic`
3. Update any dependent projects
4. Announce release if it contains important changes

## Emergency Yank

If a broken version is released:

```bash
gem yank mitre-settingslogic -v 3.0.1
```

Then release a fixed version immediately.