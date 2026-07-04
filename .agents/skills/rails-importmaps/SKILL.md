---
name: rails-importmaps
description: Rails Import Maps Guide
globs: config/importmap.rb
alwaysApply: false
---

# Rails Import Maps Guide

## Core Philosophy
- Eliminate JavaScript build steps while maintaining modern development practices
- Send JavaScript modules directly to the browser without bundling or transpiling
- Reference external modules using standardized module specifiers
- Embrace simplicity and developer happiness - this is the Rails Way™

## Configuration Principles
- Define all JavaScript dependencies in `config/importmap.rb`
- Pin external libraries to specific versions for production stability
- Use semantic versioning when pinning dependencies
- Prefer CDN URLs for popular libraries to leverage browser caching
- Vendor critical dependencies that cannot tolerate CDN failures
- Always specify `preload: true` for essential modules

## File Organization
- Keep all JavaScript files in the `app/javascript` directory
- Use `controllers/` subdirectory exclusively for Stimulus controllers
- Create `components/` for reusable UI JavaScript modules
- Create `utilities/` for shared helper functions
- Follow Rails naming conventions consistently

## Naming Conventions for AI Agents
- Name Stimulus controllers with `*_controller.js` suffix
- Use descriptive nouns for component files (`modal.js`, `dropdown.js`)
- Use action-based names for utilities (`debounce.js`, `format_currency.js`)
- Maintain consistent naming patterns across the codebase
- Document module purpose at the top of each file

## Module Management
- Import modules using standard ESM syntax
- Avoid polluting the global namespace
- Use named exports for better code discoverability
- Keep modules focused on a single responsibility
- Export only what needs to be public

## Dependency Management
- Pin to exact versions in production for stability
- Use version ranges only in development
- Regularly audit and update dependencies
- Remove unused dependencies promptly
- Document why each dependency is needed

## Performance Optimization
- Use `preload: true` only for critical dependencies
- Implement lazy loading for features not needed on initial load
- Leverage browser caching by using CDN URLs
- Evaluate module size before adding dependencies
- Consider vendoring large libraries that change infrequently

## Security Best Practices
- Pin to specific versions to prevent supply chain attacks
- Include subresource integrity hashes for CDN resources
- Validate external scripts before including them
- Use Content Security Policy headers appropriately
- Regularly update dependencies for security patches

## Integration with Rails
- Import Turbo and Stimulus at the application root
- Register Stimulus controllers automatically
- Use import maps for all JavaScript dependencies
- Avoid mixing import maps with other bundling solutions
- Keep initialization code in `application.js`

## Testing Considerations
- Test JavaScript behavior through system tests
- Use Capybara for integration testing
- Test Stimulus controllers in isolation when complex
- Ensure all imports resolve correctly
- Verify lazy-loaded modules load properly

## Migration Strategy
- Remove Node.js dependencies incrementally
- Convert webpack/esbuild imports to import map pins
- Delete package.json and node_modules after migration
- Update deployment scripts to remove build steps
- Verify all functionality works without bundling

## Development Workflow
- Run `bin/importmap` to manage dependencies
- Use `pin` command to add new libraries
- Use `unpin` command to remove libraries
- Audit pins regularly for unused dependencies
- Keep import map file organized and commented

## Debugging Guidelines
- Check browser console for module loading errors
- Verify all pinned URLs are accessible
- Ensure import paths match exactly
- Use browser developer tools to inspect loaded modules
- Check for version conflicts between dependencies

## Best Practices
- Prefer simplicity over clever abstractions
- Write modules that work without transpilation
- Use modern JavaScript features supported by target browsers
- Keep import map configuration readable and well-organized
- Document any non-obvious pinning decisions
