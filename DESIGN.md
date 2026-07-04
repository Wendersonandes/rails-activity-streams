# Design

## Theme

Light. Users access the platform during office hours in well-lit rooms — a dark interface would add friction and glare. The surface is a content canvas: the design recedes so the social feed, messages, and profiles carry the attention.

## Framework

TailwindCSS v4 via `tailwindcss-rails` gem. No custom `@theme` tokens — the project uses the default Tailwind v4 utility-first palette with OKLCH color space. All components are composed of utility classes inline in ERB views (no `@apply`, no CSS components). Tailwind is compiled JIT via `bin/rails tailwindcss:watch` and served through Propshaft as `app/assets/builds/tailwind.css`.

## Color Palette

Tailwind v4 default colors in OKLCH space — neutrals tint toward blue (250-260 hue), eliminating flat machine grays.

### Brand

| Token | Tailwind Class | Usage |
|---|---|---|
| Accent | `blue-600` | Primary buttons (`bg-blue-600`), links (`text-blue-600`), focus rings |
| Accent hover | `blue-700` | Button hover (`hover:bg-blue-700`), link hover (`hover:text-blue-700`) |
| Accent light | `blue-500` | Focus rings (`ring-blue-500`) |
| Accent surface | `blue-50` | Selected states, info banners (`bg-blue-50 border-blue-100`) |
| Accent text | `blue-800` | Text on accent surfaces |
| Accent dark | `blue-900` | Strong emphasis, icons |

### Neutrals

| Token | Tailwind Class | Usage |
|---|---|---|
| Background | `gray-50` | Page background |
| Surface | `white` | Cards, panels, modals |
| Subtle | `gray-100` | Hover states (`hover:bg-gray-50`), alternating rows, dividers |
| Border | `gray-200` / `gray-300` | Card borders (`border-gray-100`), input borders (`border-gray-300`) |
| Text secondary | `gray-400` / `gray-500` | Labels, captions, timestamps, placeholders |
| Text body | `gray-600` / `gray-700` | Paragraphs, descriptions |
| Text primary | `gray-800` / `gray-900` | Headings, emphasis |
| Text muted | `gray-400` | Disabled text, empty states |

### Semantic

| Token | Tailwind Class | Usage |
|---|---|---|
| Error | `red-600` / `red-700` | Destructive actions (`bg-red-600`), error text (`text-red-700`), error borders |
| Error surface | `red-50` / `red-100` | Error backgrounds (`bg-red-50`), alert banners |
| Error hover | `red-700` / `red-800` | Destructive button hover (`hover:bg-red-700`) |
| Success | `green-600` / `green-700` | Confirmation, success states |
| Success surface | `green-50` / `green-100` | Success backgrounds |
| Warning | `yellow-600` / `yellow-700` | Caution states |
| Warning surface | `yellow-50` | Warning backgrounds (`bg-yellow-50 border-yellow-200`) |

### Role colors

Used for admin/moderator/member badges and avatars in member lists.

| Role | Background | Text |
|---|---|---|
| Admin | `bg-blue-100` | `text-blue-600` |
| Moderator | `bg-green-100` | `text-green-600` |
| Member | `bg-gray-100` | `text-gray-500` |
| Pending | `bg-yellow-100` | `text-yellow-600` |

## Typography

### Scale

| Level | Tailwind Class | Size | Usage |
|---|---|---|---|
| xs | `text-xs` | 0.75rem | Badges, labels, meta |
| sm | `text-sm` | 0.875rem | Body, links, form labels, buttons |
| base | `text-base` | 1rem | Prose, descriptions |
| lg | `text-lg` | 1.125rem | Subtitles |
| xl | `text-xl` | 1.25rem | Card titles |
| 2xl | `text-2xl` | 1.5rem | Page headings |

### Weight

| Weight | Tailwind Class | Usage |
|---|---|---|
| Regular | `font-normal` | Body, descriptions |
| Medium | `font-medium` | Labels, links, metadata emphasis |
| Semibold | `font-semibold` | Card headings, buttons, nav items |
| Bold | `font-bold` | Page headings (`h1`), brand |

### Line height

| Context | Tailwind Class | Value |
|---|---|---|
| Body, prose | (default) | 1.5 |
| Headings | `leading-tight` | 1.25 |
| Tight UI | (default for sm) | 1.25–1.4 |

### Family

System native via Tailwind default `font-sans`: `ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"`.

## Spacing

Tailwind v4 default scale (1 unit = 0.25rem = 4px).

| Context | Tailwind Class | Value |
|---|---|---|
| Page padding | `px-5` | 1.25rem (20px) |
| Card padding | `p-4` / `p-6` | 1rem / 1.5rem |
| Section gap (vertical) | `mb-4` / `mb-6` / `space-y-4` | 1rem / 1.5rem |
| Form group spacing | `mb-4` | 1rem |
| Inline gap | `gap-2` / `gap-3` / `gap-4` | 0.5rem / 0.75rem / 1rem |
| Flex gap | `gap-4` / `gap-6` | 1rem / 1.5rem |

### Container

| Context | Tailwind Class |
|---|---|
| Content page (default) | `max-w-2xl mx-auto px-5` |
| Content + sidebar | `max-w-6xl mx-auto px-5` with `flex gap-6` |
| Form (narrow) | `max-w-lg mx-auto` |
| Sidebar | `w-72 flex-shrink-0 hidden lg:block` (sticky) |

## Elevation

One shadow level only:

| Context | Tailwind Class |
|---|---|
| Card | `shadow` — `0 1px 2px rgba(0,0,0,0.04)` (Tailwind v4 default) |
| Focus ring | `ring-2 ring-blue-500 ring-offset-0` or `focus:ring-2 focus:ring-blue-500` |
| Nav | `shadow` + `z-50` |
| No elevation | Flat surfaces use `border` instead of shadow |

No multi-level elevation. Use `border border-gray-100` for visual separation on flat surfaces.

## Radius

| Context | Tailwind Class | Value |
|---|---|---|
| Small (badges, tags) | `rounded` | 0.25rem (4px) |
| Medium (inputs, buttons, cards) | `rounded-lg` | 0.5rem (8px) |
| Full (avatars, pills) | `rounded-full` | 9999px |

## Motion

Tailwind v4 defaults — all transitions use `cubic-bezier(0.4, 0, 0.2, 1)`.

| Context | Tailwind Class |
|---|---|
| Hover/focus transitions | `transition` (default 150ms) or `transition-colors` |
| Reveals (if needed) | `duration-200` |
| Focus ring | `transition-shadow` on inputs |
| Respect preference | Tailwind v4 handles `prefers-reduced-motion` automatically |

## Components

### Input

```
w-full rounded-lg border border-gray-300 px-3 py-2 text-sm
placeholder:text-gray-400
focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500
transition-shadow
```

**States:**
- Default: `border-gray-300`
- Focus: `border-blue-500 ring-2 ring-blue-500`
- Error: `border-red-300 focus:ring-red-500`
- Disabled: `opacity-50 pointer-events-none`

**Select:** Same base as input, plus `appearance-none` if custom arrow needed.

**Textarea:** Same base as input, with `rows` attribute for height.

### Button

**Primary:**
```
bg-blue-600 text-white px-4 py-2 rounded-lg text-sm font-medium
hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-1
disabled:opacity-50 cursor-pointer
```

**Secondary:**
```
bg-white text-gray-700 px-4 py-2 rounded-lg text-sm font-medium
border border-gray-300 hover:bg-gray-50 cursor-pointer
```

**Danger:**
```
bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium
hover:bg-red-700 disabled:opacity-50 cursor-pointer
```

**Danger outline (leave/remove):**
```
text-sm text-red-600 hover:text-red-800 bg-transparent border border-red-300
px-3 py-1.5 rounded hover:bg-red-50 cursor-pointer
```

**Icon / borderless:**
```
bg-transparent border-0 cursor-pointer p-0
```

**Sizes:**
| Size | Classes |
|---|---|
| Default | `px-4 py-2 text-sm` |
| Small | `px-3 py-1.5 text-sm` |
| Extra small | `px-2 py-1 text-xs` |
| Full-width submit | `w-full py-3 text-sm` (auth forms, 48px height) |

### Card

```
bg-white rounded-lg shadow p-6 border border-gray-100
```

Group header variant:
```
bg-white rounded-lg shadow mb-6 border border-gray-100 overflow-hidden
```
— `overflow-hidden` clips the cover image to the card's top border radius.

### Nav

```
bg-white shadow fixed top-0 left-0 right-0 z-50
```
Inner container: `container mx-auto px-5 h-14` with `flex items-center justify-between`.

### Auth form

```
<div class="min-h-screen flex items-center justify-center bg-gray-50 px-5">
  <div class="w-full max-w-sm">
    <div class="text-center mb-8">
      <!-- logo + brand -->
    </div>
    <div class="bg-white/95 rounded-xl shadow-sm border border-blue-950/5 p-8">
      <h1 class="text-2xl font-bold text-gray-900 mb-2"><!-- title --></h1>
      <p class="text-sm text-gray-500 mb-6"><!-- subtitle --></p>
      <!-- form fields -->
      <button type="submit" class="w-full bg-blue-600 text-white py-3 rounded-lg ...">
      <!-- links -->
    </div>
  </div>
</div>
```

**Form field pattern:**
```
<div class="mb-4">
  <label class="block text-sm font-medium text-gray-700 mb-1">Label</label>
  <input class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm ...">
</div>
```

### Avatar

Display component used across profiles, groups, and member lists.

```
<!-- With image -->
<%= image_tag actor.avatar.variant(:thumb), class: "w-{size} h-{size} rounded-full object-cover" %>

<!-- Fallback initial -->
<div class="w-{size} h-{size} bg-{color}-100 rounded-full flex items-center justify-center
            text-{color}-600 text-{weight} font-bold">
  <%= name.first.upcase %>
</div>
```

**Sizes:**
| Context | Size | Class |
|---|---|---|
| Profile page | 64px | `w-16 h-16` |
| Sidebar | 28px | `w-7 h-7` |
| Member list | 40px | `w-10 h-10` |
| Top contributors | 32px | `w-8 h-8` |

**Group avatar** uses `rounded-lg` (square-ish) instead of `rounded-full`.

### Cover image

```
<%= image_tag actor.cover_image.variant(:thumb), class: "w-full h-40 object-cover" %>
```
Displayed at the top of profile/group cards inside an `overflow-hidden` container.

### Activity card

```
<div class="bg-white rounded-lg shadow p-4 mb-4 border border-gray-100">
  <div class="flex items-start gap-3">
    <div class="flex-1">
      <div class="flex items-center gap-2 text-sm text-gray-500 mb-2">
        <span class="font-semibold text-gray-900">Author name</span>
        <span>·</span>
        <span>timestamp</span>
      </div>
      <div class="text-gray-800"><!-- content --></div>
      <div class="flex items-center gap-4 mt-3 text-sm text-gray-500">
        <!-- actions: like, comment -->
      </div>
    </div>
  </div>
</div>
```

### Tabs

```
<div class="flex border-b border-gray-200 mb-4">
  <span class="px-4 py-2 text-sm font-medium border-b-2 border-blue-600 text-blue-600">
    Active tab
  </span>
  <a class="px-4 py-2 text-sm font-medium border-b-2 border-transparent text-gray-500 hover:text-gray-700">
    Inactive tab
  </a>
</div>
```

### Sidebar

```
<aside class="w-72 flex-shrink-0 hidden lg:block">
  <div class="bg-white rounded-lg shadow border border-gray-100 p-4 sticky top-20">
    <!-- content -->
  </div>
</aside>
```

### Member row (sidebar / list)

```
<%= link_to public_path_for(actor), class: "flex items-center gap-2 py-1.5 px-2 -mx-2 rounded-lg hover:bg-gray-50" do %>
  <!-- avatar: w-7 h-7 -->
  <span class="flex-1 text-sm text-gray-900 truncate"><%= actor.name %></span>
  <!-- optional role badge -->
<% end %>
```

## Layout Patterns

### Single column (default content pages)

```
<div class="max-w-2xl mx-auto px-5">
  <!-- content -->
</div>
```

Used on: actor profile, user account, contacts list, standalone forms.

### Two column (content + sidebar)

```
<div class="max-w-6xl mx-auto px-5">
  <div class="flex gap-6">
    <div class="flex-1 min-w-0">
      <!-- main content -->
    </div>
    <aside class="w-72 flex-shrink-0 hidden lg:block">
      <div class="sticky top-20">
        <!-- sidebar -->
      </div>
    </aside>
  </div>
</div>
```

Used on: group show page (when member). The sidebar is hidden on mobile (`hidden lg:block`).

### Nav offset

All pages below the fixed nav use `mt-14` or `pt-14` on the outermost container. The current convention is implicit — `px-5` on the content wrapper combined with the body's natural flow after the fixed `h-14` nav. The `mt-20` class on the top-level div ensures content clears the fixed nav bar.

## Tailwind Configuration

The project uses TailwindCSS v4 with **zero custom tokens** — every utility class is a v4 default. The entry point is:

```css
/* app/assets/tailwind/application.css */
@import "tailwindcss";
```

If custom design tokens are needed (e.g., stricter brand colors, custom font stacks), add an `@theme` block:

```css
@import "tailwindcss";

@theme {
  --color-brand: oklch(0.62 0.20 255);
  --color-brand-hover: oklch(0.53 0.21 255);
}
```

This would generate classes like `bg-brand`, `text-brand-hover`. New tokens must be actually used in views for Tailwind's JIT compiler to emit them.
