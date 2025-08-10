# Gem Publishing Process

This document describes the process for publishing the settingslogic gem to RubyGems.

## Prerequisites

### 1. RubyGems Account
- Create account at https://rubygems.org
- Enable MFA for security
- Obtain API key from https://rubygems.org/profile/api_keys

### 2. GitHub Repository Setup
- Fork is at: https://github.com/mitre/settingslogic
- Ensure main branch is protected
- Configure GitHub Actions secrets

### 3. GitHub Actions Secrets
Add these secrets to the repository:
- `RUBYGEMS_API_KEY` - Your RubyGems API key (required for publishing)

## Release Process

### 1. Pre-Release Checklist

```bash
# Ensure you're on main and up to date
git checkout main
git pull origin main
git status  # Should show no changes

# Run all tests
bundle exec rspec

# Check coverage (should be 90%+)
bin/analyze_coverage

# Run security audit
bundle exec bundle-audit check --update

# Run Rubocop
bundle exec rubocop

# Verify version in lib/settingslogic/version.rb
cat lib/settingslogic/version.rb
```

### 2. Automated Release Process (Recommended)

#### Quick Release Commands

For most releases, use the automated quick release commands:

```bash
# Patch release (bug fixes) - e.g., 3.0.0 -> 3.0.1
bundle exec rake release:quick:patch

# Minor release (new features) - e.g., 3.0.0 -> 3.1.0
bundle exec rake release:quick:minor

# Major release (breaking changes) - e.g., 3.0.0 -> 4.0.0
bundle exec rake release:quick:major
```

These commands automatically:
- Bump version in `lib/settingslogic/version.rb`
- Update `CHANGELOG.md` with template
- Run all tests and checks
- Commit changes with proper attribution
- Push to main branch
- Create and push release tag
- Trigger GitHub Actions for gem publication

### 3. Interactive Release Process

For more control over the release:

```bash
# Step 1: Prepare release (bumps version, updates changelog, runs tests)
bundle exec rake release:patch   # or release:minor, release:major

# Step 2: Review and edit CHANGELOG.md
# The rake task creates a template entry - customize it with actual changes

# Step 3: Commit changes
git commit -m "Bump version to 3.0.1

- Fixed specific bug X
- Improved performance of Y
- Updated documentation for Z

Authored by: Aaron Lippold<lippold@gmail.com>"

# Step 4: Push to main
git push origin main

# Step 5: Create and push release tag
bundle exec rake release:tag
```

### 4. Manual Version Management

If you need to manually control versions:

```bash
# Show current version
bundle exec rake version:show

# Bump versions (updates version.rb and CHANGELOG.md)
bundle exec rake version:patch   # 3.0.0 -> 3.0.1
bundle exec rake version:minor   # 3.0.0 -> 3.1.0  
bundle exec rake version:major   # 3.0.0 -> 4.0.0

# Then manually commit and tag
```

Version numbering follows semantic versioning:
- **Patch** (3.0.x): Bug fixes, minor updates
- **Minor** (3.x.0): New features, backwards compatible
- **Major** (x.0.0): Breaking changes

### 6. GitHub Actions Automation

When you push a tag starting with `v`, GitHub Actions will:
1. Run all tests
2. Run security audit
3. Run Rubocop
4. Create GitHub Release
5. Build gem
6. Publish to RubyGems

Monitor progress at:
- https://github.com/mitre/settingslogic/actions

## Manual Publishing (if needed)

If GitHub Actions fails, you can publish manually:

```bash
# Build the gem
gem build settingslogic.gemspec

# Verify the gem
gem spec settingslogic-3.0.1.gem

# Push to RubyGems
gem push settingslogic-3.0.1.gem
```

## Setting Up GitHub Actions

Create `.github/workflows/release.yml`:

```yaml
name: Release Gem

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write
  id-token: write  # For trusted publishing

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.3'
          bundler-cache: true
          
      - name: Run tests
        run: bundle exec rspec
        
      - name: Security audit
        run: |
          gem install bundler-audit
          bundler-audit check --update
          
      - name: Rubocop
        run: bundle exec rubocop
        
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          draft: false
          prerelease: false
          
      - name: Configure RubyGems
        uses: rubygems/configure-rubygems-credentials@v1.0.0
          
      - name: Build and publish gem
        run: |
          gem build settingslogic.gemspec
          gem push settingslogic-*.gem
```

## Post-Release

After successful release:

1. **Verify on RubyGems**: https://rubygems.org/gems/settingslogic
2. **Check GitHub Release**: https://github.com/mitre/settingslogic/releases
3. **Test installation**:
   ```bash
   gem install settingslogic
   ```
4. **Update Vulcan** to use new version

## Troubleshooting

### Common Issues

- **"Working directory not clean"** → Commit or stash changes first
- **"Permission denied pushing gem"** → Check RUBYGEMS_API_KEY secret
- **"Version already exists"** → Increment version number
- **Tests failing** → Fix issues before releasing

### RubyGems API Key

To get your API key:
1. Log in to https://rubygems.org
2. Go to https://rubygems.org/profile/api_keys
3. Create new API key with "Push rubygems" scope
4. Add as GitHub secret: `RUBYGEMS_API_KEY`

## Gem Naming

Since this is a fork, consider publishing as:
- `mitre-settingslogic` - Clear indication it's MITRE's fork
- `settingslogic` - Only if we get permission/ownership transfer

Current gemspec should use:
```ruby
spec.name = "mitre-settingslogic"
```

## Testing the Release Process

Before first real release:
1. Create a test tag like `v3.0.0-test1`
2. Let workflow run (it will fail at publish without API key)
3. Verify all other steps work
4. Delete test tag and release

## References

- [RubyGems Publishing Guide](https://guides.rubygems.org/publishing/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Actions for Ruby](https://github.com/ruby/setup-ruby)
- [Trusted Publishing](https://docs.rubygems.org/trusted-publishing/)