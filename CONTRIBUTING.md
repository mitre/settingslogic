# Contributing to Settingslogic

Thank you for your interest in contributing to the MITRE fork of settingslogic! This fork provides Ruby 3.x and Rails 7.x+ compatibility for the classic settingslogic gem.

## 🚀 Quick Start

```bash
# Fork and clone
git clone https://github.com/mitre/settingslogic.git
cd settingslogic

# Install dependencies
bundle install

# Run tests
bundle exec rspec
```

## 🛠️ Development Setup

### Prerequisites

- Ruby 2.7+ (we test against 2.7, 3.0, 3.1, 3.2, 3.3, and 3.4)
- Bundler

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run tests with specific Ruby version
rbenv local 3.2.0  # or rvm use 3.2.0
bundle exec rspec

# Run linting
bundle exec rubocop
```

## 📝 Making Changes

1. **Fork the repository** on GitHub
2. **Create a feature branch** from `main`
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. **Make your changes**
   - Add tests for any new functionality
   - Ensure all tests pass
   - Follow existing code style
4. **Commit your changes**
   ```bash
   git commit -m "Add new feature"
   ```
5. **Push to your fork**
   ```bash
   git push origin feature/my-new-feature
   ```
6. **Create a Pull Request** on GitHub

## 🧪 Testing Requirements

All changes must:
- Include tests for new functionality
- Pass all existing tests
- Work with Ruby 2.7 through 3.4
- Maintain backwards compatibility where possible

### Testing YAML Aliases

Since the main purpose of this fork is Psych 4 compatibility, ensure YAML aliases work:

```ruby
# test.yml
defaults: &defaults
  host: localhost
  port: 3000

development:
  <<: *defaults
  database: dev_db
```

## 🎯 Focus Areas

We're particularly interested in:
- Ruby 3.x compatibility improvements
- Rails 7.x and 8.x compatibility
- Performance improvements
- Security enhancements
- Better error messages

## 📋 Code Style

- Use frozen string literals
- Follow Ruby community conventions
- Run `bundle exec rubocop` before committing
- Keep methods small and focused
- Document complex logic

## 🐛 Reporting Issues

When reporting issues, please include:
- Ruby version
- Rails version (if applicable)
- Minimal reproduction example
- Full error message and stack trace

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 📧 Contact

For questions about contributing, please open an issue on GitHub or contact the maintainers at lippold@gmail.com.

## 🙏 Acknowledgments

Thanks to Ben Johnson for creating the original settingslogic gem, and to all the fork maintainers who have kept it alive for the Ruby community.