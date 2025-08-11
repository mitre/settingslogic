# Settingslogic Roadmap

## Version 3.0.0 (Current Release)
- ✅ Ruby 3.x compatibility through Ruby 3.4+
- ✅ Rails 7.x and 8.x compatibility
- ✅ Security: Replaced `YAML.unsafe_load` with `YAML.safe_load`
- ✅ Configurable permitted classes via `Settingslogic.yaml_permitted_classes`
- ✅ Migration path with deprecated `use_yaml_unsafe_load` flag
- ✅ 94%+ test coverage with reorganized specs

## Version 3.x (Maintenance)
- ✅ Rename master branch to main (completed in v3.0.1)
- Test gem autopublishing workflow
- Bug fixes as needed
- Maintain compatibility with new Ruby/Rails releases
- No new features planned - focus on stability

## Version 4.0.0 (Future - Aligned with Vulcan Rewrite)
### Breaking Changes
- Drop Ruby 2.7 support (already EOL as of March 2023)
- Remove deprecated `use_yaml_unsafe_load` flag
- Minimum Ruby version: 3.0+ (or higher based on adoption)

### Development Improvements
- Integrate `bump` gem for simplified version management
  - Replace custom Rakefile version bumping with industry-standard tool
  - Automatic handling of VERSION file, gemspec, and Gemfile.lock
  - Simplify release process with `bump patch --tag --commit`
  - Reference: https://github.com/gregorym/bump

### Goals
- Simplify codebase by removing legacy compatibility code
- Maintain as a simple, focused settings gem
- Ensure compatibility with Ruby 3.4+ for the long term
- Streamline development workflow with standard tools

## Maintenance Philosophy
This is a MITRE-maintained fork created specifically for Vulcan and other MITRE projects. We recognize that many in the Ruby community are moving to other configuration solutions, but settingslogic remains valuable for existing projects.

Our focus:
- Security and stability over features
- Maintaining compatibility for existing users
- Clear migration paths when changes are needed
- No unnecessary complexity

## Note
Given the gem's maturity and decreasing usage in new projects, we don't anticipate significant feature development. This fork exists primarily to ensure MITRE projects using settingslogic can safely upgrade to modern Ruby and Rails versions.