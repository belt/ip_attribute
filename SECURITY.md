# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

If you believe you have found a security vulnerability in IpAttribute, please report it privately via email to 153964+belt@users.noreply.github.com.

### What to Include in Your Report

When reporting a vulnerability, please include:

1. **Description**: Clear description of the vulnerability
2. **Impact**: Potential impact of the vulnerability
3. **Steps to Reproduce**: Detailed steps to reproduce the issue
4. **Affected Versions**: Which versions are affected
5. **Mitigation**: Any suggested fixes or workarounds
6. **Proof of Concept**: Code or commands demonstrating the issue (if applicable)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Assessment**: Within 7 days
- **Fix Development**: Depends on complexity
- **Public Disclosure**: After fix is released

## Security Considerations

### IP Address Handling

IpAttribute handles IP addresses, which can be sensitive in certain contexts:

1. **Input Validation**: All IP address inputs are validated
2. **Integer Conversion**: IPs are stored as integers for performance
3. **Subnet Queries**: Supports CIDR notation for subnet filtering

### Database Security

- Uses ActiveRecord parameterized queries
- No SQL injection vulnerabilities in query methods
- Proper type casting for all database operations

### Dependencies

All dependencies are regularly updated:
- ActiveRecord >= 7.2
- ActiveSupport >= 7.2

Run `bundle audit` to check for known vulnerabilities in dependencies.

## Best Practices for Users

### 1. Input Validation
```ruby
# Always validate user input
begin
  user_ip = params[:ip_address]
  session.client_ip = user_ip
rescue IpAttribute::Error => e
  # Handle invalid IP
end
```

### 2. Rate Limiting
Consider implementing rate limiting based on IP addresses:
```ruby
# Example using IpAttribute for rate limiting
recent_requests = Request.where_ip(:client_ip, ip_address)
                         .where("created_at > ?", 1.hour.ago)
                         .count
```

### 3. Logging
Avoid logging full IP addresses in production. Use:
```ruby
# Hash or mask IPs in logs
masked_ip = ip_address.to_s.gsub(/\d+\.\d+\.\d+\./, "xxx.xxx.xxx.")
```

### 4. Access Control
Implement proper access controls for IP-based features.

## Security Updates

Security updates will be released as patch versions. Subscribe to GitHub notifications to receive updates.

## Credits

We thank security researchers who responsibly disclose vulnerabilities. Contributors will be credited in security advisories unless they request anonymity.

## License

This security policy is based on the [GitHub Security Policy template](https://github.com/github/security-policy-template).
