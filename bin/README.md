# Settingslogic Development Tools

This directory contains development tools for the Settingslogic gem.

## analyze_coverage

A Ruby script that analyzes test coverage and identifies uncovered lines.

### Usage

```bash
# Run tests first to generate coverage data
bundle exec rspec

# Analyze coverage with detailed output
bin/analyze_coverage

# Show verbose output with context around uncovered lines
bin/analyze_coverage --verbose

# Show summary only
bin/analyze_coverage --summary

# Show help
bin/analyze_coverage --help
```

### Features

- Shows overall coverage percentage
- Lists uncovered lines by file
- Groups uncovered code by category:
  - Ruby version compatibility
  - URL loading
  - Error handling  
  - Other
- Provides recommendations for improving coverage
- Optional verbose mode shows code context

### Example Output

```
======================================================================
COVERAGE ANALYSIS REPORT
======================================================================

Overall Coverage: 90.32% (112/124 lines)

Uncovered Lines by File:
----------------------------------------------------------------------

📁 settingslogic.rb (12 uncovered lines)
   Path: /Users/.../lib/settingslogic.rb

   Line 189 : v.symbolize_keys
   Line 242 : elsif YAML.respond_to?(:safe_load)
   ...

======================================================================
SUMMARY
======================================================================

Ruby version compatibility: 4 lines (33.3% of uncovered code)
URL loading: 2 lines (16.7% of uncovered code)
Error handling: 4 lines (33.3% of uncovered code)
Other: 2 lines (16.7% of uncovered code)
```

### Requirements

- Ruby
- SimpleCov (included in development dependencies)
- Coverage data from running tests (`bundle exec rspec`)