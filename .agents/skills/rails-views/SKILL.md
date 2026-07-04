---
name: rails-views
description: Rails Views and Helpers Guide
globs: app/views/**/*.html.erb,app/helpers/**/*.rb
alwaysApply: false
---

# Rails Views and Helpers Guide

## Core Philosophy
- Keep views simple and logic-free
- Use helpers for presentation logic only
- Leverage Rails' built-in view helpers
- Follow semantic HTML principles
- Optimize for readability and maintainability

## View Architecture Principles
- Separate presentation from business logic completely
- Use partials for reusable view components
- Keep views focused on displaying data
- Implement proper HTML semantics
- Design for progressive enhancement

## Helper Organization
- Keep helpers focused on specific presentation tasks
- Group related helpers in dedicated modules
- Use ApplicationHelper for truly global helpers
- Document complex helper methods
- Test helpers with various input scenarios

## Rails Helper Usage
- Prefer Rails helpers over raw HTML
- Use semantic Rails form helpers
- Leverage Rails' built-in formatting helpers
- Implement proper escaping for security
- Follow Rails conventions for helper naming

## Partial Best Practices
- Name partials with leading underscore
- Keep partials small and focused
- Pass locals explicitly for clarity
- Avoid instance variables in partials
- Document partial requirements

## Form Design Principles
- Use `form_with` for all forms
- Implement proper form accessibility
- Add appropriate ARIA labels
- Use Rails form builders consistently
- Handle errors at the field level

## Asset Management
- Use Rails asset helpers for all assets
- Implement proper image alt texts
- Leverage asset fingerprinting
- Configure CDN for production assets
- Optimize images before serving

## Internationalization
- Extract all text to locale files
- Use Rails I18n helpers consistently
- Design views for text expansion
- Handle pluralization properly
- Test with multiple locales

## Performance Optimization
- Use fragment caching for expensive views
- Implement Russian doll caching
- Avoid N+1 queries in views
- Lazy load below-fold content
- Profile view rendering times

## JavaScript Integration
- Use `data` attributes for JavaScript hooks
- Avoid inline JavaScript in views
- Implement CSP-compliant practices
- Use Stimulus for behavior
- Keep JavaScript unobtrusive

## Security Practices
- Always escape user-generated content
- Use Rails sanitize helpers appropriately
- Implement Content Security Policy
- Avoid raw HTML output
- Validate all user inputs

## Responsive Design
- Design mobile-first
- Use semantic HTML elements
- Test on actual devices
- Implement proper touch targets
- Consider performance on mobile

## Accessibility Guidelines
- Use semantic HTML elements
- Provide proper ARIA labels
- Ensure keyboard navigation works
- Test with screen readers
- Meet WCAG 2.1 AA standards

## Testing View Code
- Test complex helpers thoroughly
- Use system tests for user flows
- Verify accessibility in tests
- Test error states explicitly
- Check responsive behavior

## View Component Patterns
- Consider ViewComponent for complex UI
- Keep components focused and reusable
- Test components in isolation
- Document component interfaces
- Use slots for flexible content

## Email Views
- Design for email client limitations
- Use inline styles for emails
- Test across email clients
- Provide text alternatives
- Keep email templates simple

## Error Pages
- Design custom error pages
- Keep error pages self-contained
- Provide helpful error messages
- Include support contact info
- Test error pages thoroughly

## Layout Best Practices
- Keep layouts DRY
- Use yield for content areas
- Implement proper meta tags
- Configure CSP headers
- Design consistent navigation

## Flash Messages
- Display flash messages prominently
- Auto-dismiss success messages
- Keep error messages visible
- Use semantic colors
- Test flash message display

## Pagination Patterns
- Implement accessible pagination
- Use Rails pagination helpers
- Consider infinite scroll carefully
- Show current page clearly
- Handle edge cases properly

## Search Interface Design
- Implement live search thoughtfully
- Provide search feedback
- Handle no results gracefully
- Consider search accessibility
- Optimize search performance

## Data Presentation
- Format data consistently
- Use Rails number helpers
- Display dates in user timezone
- Handle empty states gracefully
- Provide data export options

## Mobile Optimization
- Optimize for touch interfaces
- Consider bandwidth limitations
- Implement offline capabilities
- Test on slow connections
- Use responsive images

## Development Workflow
- Use Rails view generators wisely
- Keep views under version control
- Document view dependencies
- Review views for performance
- Maintain view style guide

## Common Anti-Patterns
- Avoid business logic in views
- Don't query database from views
- Prevent complex conditionals
- Skip inline styles
- Refuse to duplicate view code

## Best Practices Summary
- Keep views simple and semantic
- Use Rails helpers consistently
- Test views thoroughly
- Optimize for performance
- Design for accessibility

Remember: Views should only present data. Keep logic in models and controllers, and use helpers for presentation formatting.
