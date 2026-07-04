---
name: rails-controllers
description: Use when creating or modifying Rails controllers, adding actions, setting up authorization, configuring routes, modeling state changes as resources, or handling Turbo responses
globs: app/controllers/**/*.rb
alwaysApply: false
---

# Rails Controllers Guide

## Core Philosophy
- Controllers handle HTTP requests and responses only
- Keep controllers thin and focused
- Business logic belongs in models or service objects
- Follow RESTful conventions strictly
- Design for clarity and maintainability

## Controller Design Principles
- One controller per resource
- Seven standard RESTful actions maximum
- Keep actions focused on single responsibilities
- Handle multiple response formats gracefully
- Maintain consistent patterns across controllers

## RESTful Actions
- Use only standard actions when possible: index, show, new, create, edit, update, destroy
- Add custom actions sparingly and thoughtfully
- Name custom actions with clear verbs
- Group related actions in the same controller
- Consider splitting into multiple resources instead of custom actions

## Before Actions
- Use before_action for common setup tasks
- Keep filter methods private
- Order filters from general to specific
- Document filter purposes when not obvious
- Avoid complex logic in filters

## Strong Parameters
- Always use strong parameters for user input
- Define parameter methods as private
- Be explicit about permitted attributes
- Handle nested attributes appropriately
- Document complex parameter structures

## Response Handling
- Support multiple formats (HTML, JSON, Turbo Stream)
- Use consistent status codes
- Provide meaningful error messages
- Handle missing records gracefully
- Implement proper content negotiation

## Error Handling
- Rescue specific exceptions at appropriate levels
- Provide user-friendly error messages
- Log errors with sufficient context
- Use proper HTTP status codes
- Handle errors consistently across controllers

## Authentication and Authorization
- Implement authentication in ApplicationController
- Check authorization in before_action callbacks
- Fail fast with unauthorized access
- Provide clear feedback for access denied
- Keep authorization logic simple and clear

## Controller Concerns
- Extract shared behavior into concerns
- Name concerns based on functionality
- Keep concerns focused and cohesive
- Document concern dependencies
- Test concerns in isolation

## Flash Messages
- Use flash for user notifications
- Keep messages clear and actionable
- Use consistent message keys
- Handle flash in layouts appropriately
- Consider flash.now for rendered responses

## Redirects vs Rendering
- Redirect after successful mutations
- Render on validation failures
- Preserve user input when rendering
- Use proper status codes
- Maintain RESTful patterns

## Parameter Handling
- Validate parameters early
- Handle missing parameters gracefully
- Transform parameters consistently
- Document parameter expectations
- Use parameter objects for complex inputs

## Response Formats
- Design API responses thoughtfully
- Keep JSON responses consistent
- Use Turbo Streams for partial updates
- Support format negotiation properly
- Document response structures

## Testing Controllers
- Test authorization and authentication
- Verify response formats and status codes
- Check parameter filtering
- Test error scenarios
- Keep controller tests focused on HTTP concerns

## Performance Considerations
- Implement pagination for index actions
- Use includes to prevent N+1 queries
- Cache expensive operations appropriately
- Limit response data to necessary fields
- Monitor controller action performance

## Security Best Practices
- Never trust user input
- Verify authorization for every action
- Use CSRF protection consistently
- Implement rate limiting where appropriate
- Audit controller access patterns

## API Design (When Needed)
- Version APIs from the start
- Use consistent response formats
- Implement proper error responses
- Document all endpoints thoroughly
- Consider API-only controllers

## Turbo Integration
- Return Turbo Stream responses for AJAX requests
- Use proper Turbo Frame targeting
- Handle Turbo Drive visits appropriately
- Implement graceful fallbacks
- Test Turbo interactions thoroughly

## Controller Inheritance
- Use ApplicationController for shared behavior
- Create base controllers for common patterns
- Keep inheritance hierarchies shallow
- Document inheritance purposes
- Avoid deep controller hierarchies

## Common Anti-Patterns
- Avoid business logic in controllers
- Don't query databases directly in views
- Prevent controllers from knowing model internals
- Skip complex conditionals in actions
- Don't duplicate code across controllers

## Refactoring Guidelines
- Extract complex logic to service objects
- Move view logic to helpers or decorators
- Consolidate duplicate code into concerns
- Split large controllers by resource
- Keep actions under 10 lines when possible

## Best Practices Summary
- Keep controllers thin and focused
- Follow RESTful conventions
- Handle errors gracefully
- Use strong parameters always
- Test HTTP concerns thoroughly

Remember: Controllers are just the translation layer between HTTP and your application. Keep them simple and let other layers handle complexity.
