# Security Policy

## Reporting Security Issues

The MITRE team takes security seriously. If you discover a security vulnerability in the settingslogic fork, please report it responsibly.

### Contact Information

- **Email**: [saf-security@mitre.org](mailto:saf-security@mitre.org)
- **GitHub**: Use the [Security tab](https://github.com/mitre/settingslogic/security) to report vulnerabilities privately
- **Direct Contact**: lippold@gmail.com for urgent issues

### What to Include

When reporting security issues, please provide:

1. **Description** of the vulnerability
2. **Steps to reproduce** the issue
3. **Affected versions** (Ruby version, settingslogic version)
4. **Potential impact** assessment
5. **Suggested fix** (if you have one)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial Assessment**: Within 1 week
- **Fix Timeline**: Depends on severity
  - Critical: Within 1 week
  - High: Within 2 weeks
  - Medium: Within 1 month
  - Low: Next release

## Security Considerations

### YAML Loading (v3.0.0+)

This gem uses YAML for configuration files with secure defaults:

- **Default**: Uses `YAML.safe_load` to prevent arbitrary code execution
- **Permitted classes**: `Symbol, Date, Time, DateTime, BigDecimal`
- **Customizable**: Add your own classes via `Settingslogic.yaml_permitted_classes`
- **YAML aliases**: Fully supported with `aliases: true` parameter

**⚠️ Important**: Configuration files should be:
- Stored in secure locations
- Not user-uploadable
- Protected with appropriate file permissions

### ERB Processing

Configuration files support ERB templates. This means:
- Environment variables can be embedded
- Ruby code can be executed during configuration loading

**Best Practices**:
```yaml
# Good - using environment variables
production:
  secret_key: <%= ENV['SECRET_KEY_BASE'] %>
  
# Avoid - executing arbitrary code
production:
  value: <%= `whoami` %>  # Don't do this!
```

### File Access

The gem can load configuration from:
- Local files (recommended)
- HTTP/HTTPS URLs (use with caution)

For production environments, always use local files with proper permissions.

## Supported Versions

| Version | Ruby Versions | Supported          |
| ------- | ------------- | ------------------ |
| 3.0.x   | 2.7 - 3.4     | :white_check_mark: |
| 2.0.x   | 1.9 - 2.6     | :x:                |

## Security Enhancements in v3.0.0

### Critical Security Fixes
- **YAML deserialization security**: Replaced `YAML.unsafe_load` with `YAML.safe_load` to prevent arbitrary object instantiation (addresses CVE-2022-32224 pattern)
- **Removed open-uri vulnerability**: Replaced `open-uri` with `Net::HTTP` to prevent SSRF attacks
- **Protocol validation**: Explicitly blocks dangerous protocols (file://, ftp://, gopher://, etc.)
- **Safe YAML loading**: Default permitted classes: Symbol, Date, Time, DateTime, BigDecimal
- **Input sanitization**: Dynamic method names validated with `/^\w+$/` to prevent code injection

### Security Features
- **No automatic redirects**: HTTP client doesn't follow redirects automatically
- **Controlled deserialization**: Prevents arbitrary object instantiation in YAML
- **Proper error handling**: Security errors fail safely without exposing internals
- **Comprehensive testing**: 18 security-specific test cases added

### Known Security Issues

#### Original Gem (2.0.9)
- **CVE-2020-8287 (related)**: Uses vulnerable `open-uri` for URL loading
- No Psych 4 support (Ruby 3.1+ compatibility issues)
- Uses deprecated `YAML.load` without restrictions
- No security updates since 2012

#### This Fork (3.0.0+)
- All known security issues have been addressed
- Regular security audits via bundler-audit
- Active maintenance by MITRE SAF team
- Comprehensive security test coverage (94.63%)

## Disclosure Policy

We follow responsible disclosure:

1. Security issues are fixed in private
2. Patches are released with security advisories
3. Credit is given to reporters (unless they prefer anonymity)

## Additional Resources

- [MITRE CVE Database](https://cve.mitre.org/)
- [Ruby Security Advisories](https://www.ruby-lang.org/en/security/)
- [Rails Security Guide](https://guides.rubyonrails.org/security.html)