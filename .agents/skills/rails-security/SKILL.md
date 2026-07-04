---
name: rails-security
description: Rails Security Guide
globs: **/*.rb
alwaysApply: false
---

# Rails Security Guide

## Core Philosophy
- Security is not optional, it's fundamental
- Follow the principle of least privilege
- Never trust user input
- Defense in depth - multiple layers of security
- Stay updated with security best practices

## Authentication Principles
- Use Rails built-in authentication generator
- Implement secure password requirements
- Use has_secure_password for password handling
- Implement session timeouts
- Support multi-factor authentication when needed

## Authorization Strategy
- Authenticate every request
- Authorize every action
- Fail closed - deny by default
- Check permissions at multiple levels
- Log authorization failures

## Strong Parameters
- Always use strong parameters
- Whitelist allowed attributes explicitly
- Never permit entire parameter hashes
- Handle nested attributes carefully
- Document permitted parameters

## SQL Injection Prevention
- Use parameterized queries always
- Avoid string interpolation in queries
- Use Active Record query interface
- Sanitize user input when necessary
- Review raw SQL carefully

## Cross-Site Scripting (XSS)
- Escape output by default
- Use Rails sanitize helpers appropriately
- Be careful with raw and html_safe
- Implement Content Security Policy
- Validate and sanitize user input

## Cross-Site Request Forgery (CSRF)
- Enable CSRF protection globally
- Include tokens in all forms
- Verify tokens on state-changing requests
- Handle AJAX requests properly
- Document any CSRF exceptions

## Session Security
- Use secure session storage
- Implement session expiration
- Regenerate session IDs after login
- Clear sessions on logout
- Monitor for session hijacking

## Password Management
- Enforce strong password policies
- Never store passwords in plain text
- Use bcrypt for password hashing
- Implement password reset securely
- Support password managers

## API Security
- Use token-based authentication
- Implement rate limiting
- Version APIs from the start
- Use HTTPS exclusively
- Validate API input thoroughly

## File Upload Security
- Validate file types and sizes
- Scan uploads for malware
- Store files outside web root
- Use random filenames
- Implement access controls

## Secrets Management
- Use Rails credentials for secrets
- Never commit secrets to version control
- Rotate credentials regularly
- Use different credentials per environment
- Document credential requirements

## HTTPS and Transport Security
- Force SSL in production
- Use secure cookies
- Implement HSTS headers
- Validate SSL certificates
- Monitor certificate expiration

## Security Headers
- Implement Content Security Policy
- Use X-Frame-Options
- Set X-Content-Type-Options
- Enable X-XSS-Protection
- Configure Referrer-Policy

## Input Validation
- Validate on multiple levels
- Use Active Record validations
- Implement format validations
- Check business logic constraints
- Sanitize for output context

## Error Handling
- Don't expose sensitive information
- Log security events appropriately
- Use generic error messages
- Monitor for attack patterns
- Implement proper 404/500 pages

## Dependency Security
- Keep dependencies updated
- Monitor for vulnerabilities
- Use bundle audit regularly
- Review new dependencies
- Remove unused dependencies

## Rate Limiting
- Implement request throttling
- Limit authentication attempts
- Protect expensive operations
- Use progressive delays
- Monitor for abuse patterns

## Logging and Monitoring
- Log security-relevant events
- Avoid logging sensitive data
- Monitor for suspicious patterns
- Set up security alerts
- Review logs regularly

## Data Protection
- Encrypt sensitive data at rest
- Use encryption in transit
- Implement data retention policies
- Support data deletion requests
- Audit data access

## Third-Party Integrations
- Validate webhook signatures
- Use OAuth appropriately
- Limit API permissions
- Monitor third-party access
- Document integration security

## Security Testing
- Include security in test suite
- Test authorization thoroughly
- Verify input validation
- Check for common vulnerabilities
- Use security scanning tools

## Incident Response
- Have a response plan ready
- Document security contacts
- Practice incident procedures
- Monitor for breaches
- Learn from incidents

## Compliance Considerations
- Understand regulatory requirements
- Implement necessary controls
- Document security measures
- Conduct regular audits
- Stay informed on changes

## Development Practices
- Review code for security issues
- Use security linters
- Train team on security
- Follow secure coding standards
- Make security part of culture

## Common Vulnerabilities
- Mass assignment vulnerabilities
- Insecure direct object references
- Missing authorization checks
- Weak authentication methods
- Insufficient logging

## Security Checklist
- [ ] Authentication implemented properly
- [ ] Authorization checked everywhere
- [ ] Input validated and sanitized
- [ ] Output escaped appropriately
- [ ] HTTPS enforced in production
- [ ] Secrets managed securely
- [ ] Dependencies kept updated
- [ ] Security headers configured
- [ ] Logging implemented properly
- [ ] Error handling reveals no secrets

## Best Practices Summary
- Never trust user input
- Implement defense in depth
- Keep dependencies updated
- Log security events
- Stay informed on threats

Remember: Security is everyone's responsibility. Build it in from the start, not as an afterthought.
