# Installation

## Requirements

- Ruby 2.7 or higher
- Bundler

## Installing the Gem

### Via Gemfile (Recommended)

Add this line to your application's Gemfile:

```ruby
gem 'mitre-settingslogic', '~> 3.0'
```

Then execute:

```bash
bundle install
```

### Direct Installation

```bash
gem install mitre-settingslogic
```

### From GitHub

To use the latest development version:

```ruby
gem 'mitre-settingslogic', github: 'mitre/settingslogic', branch: 'main'
```

## Rails Integration

For Rails applications, settingslogic will automatically integrate when added to your Gemfile.

1. Create a configuration file at `config/application.yml`
2. Create a settings class that inherits from Settingslogic
3. Access your settings throughout your application

See the [Quick Start Guide](quick-start.md) for detailed examples.

## Non-Rails Projects

Settingslogic works great with any Ruby project:

- Sinatra applications
- Ruby scripts
- Command-line tools
- Background job processors

Simply require the gem and create your settings class:

```ruby
require 'settingslogic'

class Settings < Settingslogic
  source "/path/to/config.yml"
end
```