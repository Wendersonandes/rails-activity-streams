---
name: rails-hotwire
description: Rails Hotwire Guide
globs: app/views/**/*.html.erb,app/javascript/controllers/**/*.js
alwaysApply: false
---

# Rails Hotwire Guide

## Core Philosophy
- Send HTML over the wire, not JSON - let the server do the rendering
- Achieve SPA-like speed without complex JavaScript frameworks
- Use progressive enhancement - functionality works without JavaScript
- Keep client-side logic minimal and server-side logic rich
- Embrace the simplicity of multi-page applications with the speed of SPAs

## Turbo Drive Principles
- Enable fast page navigation without full page reloads automatically
- Intercept all clicks and form submissions by default
- Maintain scroll position and focus between navigations
- Cache pages intelligently for instant back/forward navigation
- Preserve JavaScript state between page visits

## Turbo Drive Configuration
- Disable Turbo Drive selectively with `data-turbo="false"`
- Control navigation behavior with `data-turbo-action` attributes
- Use `data-turbo-permanent` to persist elements across navigations
- Configure cache behavior with meta tags
- Handle navigation events for custom behavior

## Turbo Frames Principles
- Decompose pages into independent segments that update separately
- Scope navigation to frame boundaries automatically
- Enable partial page updates without custom JavaScript
- Support lazy loading for performance optimization
- Maintain proper URL and history management

## Turbo Frames Best Practices
- Use meaningful frame IDs that describe their content
- Keep frames focused on a single concern
- Lazy load below-the-fold content with `loading="lazy"`
- Break out of frames with `data-turbo-frame="_top"` when needed
- Cache frame responses independently for better performance

## Turbo Streams Principles
- Update multiple page elements in a single response
- Support real-time updates via WebSockets or SSE
- Use semantic actions: append, prepend, replace, update, remove
- Target elements by ID for surgical updates
- Broadcast changes from models automatically

## Turbo Streams Implementation
- Return Turbo Stream responses from form submissions
- Use `turbo_stream` format in controllers
- Broadcast model changes with Action Cable
- Target multiple elements in one response
- Keep stream templates simple and focused

## Stimulus Philosophy
- Enhance HTML with just enough JavaScript behavior
- Connect JavaScript objects to DOM elements declaratively
- Use conventions to minimize configuration
- Keep controllers small and focused
- Leverage the power of mutation observers

## Stimulus Controller Principles
- Name controllers based on their behavior, not their content
- Keep controllers focused on a single responsibility
- Use data attributes for all configuration
- Prefer composition over inheritance
- Write controllers that can be reused across pages

## Stimulus Targets
- Define targets for elements the controller will manipulate
- Use semantic target names that describe their purpose
- Check for target existence before using them
- Use singular targets for single elements
- Use plural targets for collections of elements

## Stimulus Actions
- Declare all event handling in HTML with data attributes
- Use descriptive action names that explain the behavior
- Handle events at the appropriate level in the DOM
- Prevent default behavior explicitly when needed
- Keep action methods small and focused

## Stimulus Values
- Use values for controller configuration and state
- Define value types for automatic parsing
- React to value changes with callbacks
- Set sensible defaults for all values
- Keep values primitive and serializable

## Stimulus Classes
- Define CSS classes as data attributes for flexibility
- Use classes for styling state changes
- Keep class names semantic and reusable
- Allow classes to be configured per instance
- Document required CSS classes clearly

## Hotwire Integration Patterns
- Use Turbo Frames for partial page updates
- Use Turbo Streams for multi-element updates
- Use Stimulus for client-side interactivity
- Combine all three for rich, responsive interfaces
- Keep each tool focused on its strength

## Progressive Enhancement
- Build features that work without JavaScript first
- Enhance with Turbo for better navigation
- Add Stimulus for rich interactions
- Test with JavaScript disabled
- Provide meaningful fallbacks

## Performance Optimization
- Use Turbo Frames to update only what changes
- Lazy load expensive content
- Cache aggressively with proper cache keys
- Minimize Stimulus controller complexity
- Preload critical resources

## Testing Strategies
- Write system tests for user flows
- Test Turbo Frame interactions
- Test Turbo Stream responses
- Test Stimulus controllers in isolation
- Ensure graceful degradation

## Error Handling
- Handle Turbo visit errors gracefully
- Provide feedback for failed form submissions
- Show meaningful error messages
- Implement retry mechanisms for failed requests
- Log errors appropriately for debugging

## Mobile Considerations
- Ensure touch targets are appropriately sized
- Handle touch events properly in Stimulus
- Test on real devices, not just responsive mode
- Optimize for slower network connections
- Consider offline capabilities

## Security Practices
- Always verify permissions server-side
- Use CSRF tokens in all forms
- Sanitize any user-generated content
- Don't trust client-side validation
- Implement proper authentication checks

## Development Workflow
- Use Rails generators for Stimulus controllers
- Organize controllers by feature
- Keep JavaScript minimal and focused
- Test JavaScript behavior through system tests
- Document complex interactions

## Debugging Techniques
- Use Turbo debugging events in development
- Log Stimulus lifecycle methods when troubleshooting
- Inspect Turbo Frame sources in browser tools
- Monitor WebSocket connections for streams
- Use browser console for interactive debugging

## Best Practices
- Let the server handle complex logic
- Keep JavaScript simple and declarative
- Use semantic HTML as the foundation
- Follow Rails conventions consistently
- Write code that's a joy to maintain

Remember: Hotwire is about sending HTML over the wire. Keep your client-side code minimal and let Rails do what it does best - render HTML on the server.
