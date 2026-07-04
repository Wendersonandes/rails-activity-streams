---
name: rails-styling
description: Rails Styling with TailwindCSS
globs: app/views/**/*.html.erb,app/assets/stylesheets/**/*.css
alwaysApply: false
---

# Rails Styling with TailwindCSS

## Core Philosophy
- Use utility-first CSS for rapid development
- Avoid writing custom CSS when utilities exist
- Keep styling consistent across the application
- Design mobile-first, enhance for desktop
- Let TailwindCSS handle the complexity

## TailwindCSS Principles
- Compose styles using utility classes
- Avoid premature abstraction into components
- Use consistent spacing and sizing scales
- Leverage TailwindCSS's design system
- Keep HTML as the source of truth for styling

## Configuration Strategy
- Extend default theme rather than replacing it
- Define custom colors sparingly
- Use CSS variables for dynamic theming
- Configure content paths correctly
- Keep configuration minimal

## Rails Integration
- Use Tailwind's standalone CLI approach
- Configure asset pipeline integration properly
- Set up proper purging for production
- Use Rails helpers with Tailwind classes
- Keep build process simple

## Utility-First Approach
- Start with utilities before extracting components
- Use modifier classes for responsive design
- Apply state modifiers directly in HTML
- Leverage arbitrary values when needed
- Keep utility usage consistent

## Component Patterns
- Extract components only when truly reusable
- Use `@apply` sparingly and deliberately
- Keep extracted components simple
- Document component patterns clearly
- Prefer composition over complex components

## Responsive Design
- Design mobile-first always
- Use breakpoint prefixes consistently
- Test at all breakpoint sizes
- Consider touch targets on mobile
- Optimize for common device sizes

## Color Management
- Use Tailwind's color palette
- Define semantic color names
- Maintain consistent color usage
- Support dark mode properly
- Test color accessibility

## Typography System
- Use Tailwind's typography scale
- Keep font sizes consistent
- Implement proper line heights
- Use appropriate font weights
- Consider readability always

## Spacing Guidelines
- Use Tailwind's spacing scale exclusively
- Keep spacing consistent throughout
- Apply spacing systematically
- Use negative margins carefully
- Document spacing decisions

## Form Styling
- Style forms consistently with utilities
- Use focus states for accessibility
- Implement proper error states
- Keep inputs touch-friendly
- Test form usability thoroughly

## Animation and Transitions
- Use Tailwind's transition utilities
- Keep animations subtle and purposeful
- Implement reduced motion support
- Test animation performance
- Avoid excessive animations

## Dark Mode Implementation
- Design with dark mode in mind
- Use Tailwind's dark mode utilities
- Test both modes thoroughly
- Ensure sufficient contrast
- Handle images appropriately

## Performance Optimization
- Configure PurgeCSS correctly
- Monitor CSS bundle size
- Use JIT mode for development
- Optimize for critical CSS
- Lazy load non-critical styles

## Accessibility Considerations
- Ensure sufficient color contrast
- Use focus-visible for keyboard navigation
- Test with screen readers
- Implement proper ARIA attributes
- Follow WCAG guidelines

## Rails View Integration
- Use Tailwind classes in Rails helpers
- Keep ERB templates readable
- Apply styles consistently
- Use partials for repeated patterns
- Document styling patterns

## Asset Pipeline Configuration
- Configure Tailwind with Propshaft
- Set up proper build commands
- Use Rails asset helpers
- Configure for production builds
- Keep configuration simple

## Development Workflow
- Use Tailwind CSS IntelliSense
- Configure editor for Tailwind
- Use browser DevTools effectively
- Test across browsers
- Keep styles maintainable

## Common Patterns
- Card layouts with shadows
- Responsive navigation menus
- Form layouts with proper spacing
- Modal dialogs with overlays
- Data tables with hover states

## Anti-Patterns to Avoid
- Don't recreate utility classes
- Avoid inline styles
- Don't over-extract components
- Skip complex CSS when utilities work
- Prevent specificity battles

## Debugging Techniques
- Use browser DevTools
- Check compiled CSS output
- Verify purging works correctly
- Test responsive breakpoints
- Monitor specificity issues

## Team Guidelines
- Document custom utilities
- Share component patterns
- Maintain style consistency
- Review styling in PRs
- Keep team aligned

## Migration Strategy
- Convert CSS gradually
- Use Tailwind alongside existing styles
- Replace custom CSS with utilities
- Test thoroughly during migration
- Document migration decisions

## Production Considerations
- Optimize CSS delivery
- Use CDN for assets
- Enable compression
- Monitor performance metrics
- Cache assets appropriately

## Best Practices Summary
- Let utilities do the work
- Keep HTML readable
- Design systematically
- Test across devices
- Maintain consistency

Remember: TailwindCSS provides a complete design system. Use it fully before writing custom CSS.
