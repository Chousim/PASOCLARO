---
name: PasoClaro
colors:
  surface: '#fbf8fc'
  surface-dim: '#dcd9dd'
  surface-bright: '#fbf8fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2f7'
  surface-container: '#f0edf1'
  surface-container-high: '#eae7eb'
  surface-container-highest: '#e4e1e6'
  on-surface: '#1b1b1e'
  on-surface-variant: '#3f4946'
  inverse-surface: '#303033'
  inverse-on-surface: '#f3f0f4'
  outline: '#6f7975'
  outline-variant: '#bfc9c4'
  surface-tint: '#24695b'
  primary: '#004439'
  on-primary: '#ffffff'
  primary-container: '#135d4f'
  on-primary-container: '#90d3c1'
  inverse-primary: '#90d4c2'
  secondary: '#57605f'
  on-secondary: '#ffffff'
  secondary-container: '#d6dfdd'
  on-secondary-container: '#5a6361'
  tertiary: '#612c20'
  on-tertiary: '#ffffff'
  tertiary-container: '#7d4235'
  on-tertiary-container: '#ffb4a3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#acf0dd'
  primary-fixed-dim: '#90d4c2'
  on-primary-fixed: '#00201a'
  on-primary-fixed-variant: '#005143'
  secondary-fixed: '#dbe4e2'
  secondary-fixed-dim: '#bfc8c7'
  on-secondary-fixed: '#151d1c'
  on-secondary-fixed-variant: '#404847'
  tertiary-fixed: '#ffdad3'
  tertiary-fixed-dim: '#ffb4a4'
  on-tertiary-fixed: '#380d05'
  on-tertiary-fixed-variant: '#6f372a'
  background: '#fbf8fc'
  on-background: '#1b1b1e'
  surface-variant: '#e4e1e6'
typography:
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.025em
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  title-lg:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-medium:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  label-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 20px
  label-meta:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-status:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a light, sunlit civic clarity for a mobile-first accessible civic companion app. Designed for residents navigating municipal services, public benefits, and civic procedures, the interface prioritizes calm legibility, dignity, and effortless comprehension over decorative flair.

The aesthetic blends **Minimalism** with **Corporate / Modern** precision: generous whitespace, crisp structural boundaries, and high-contrast typography create an approachable yet authoritative experience. Every interaction is grounded in WCAG AAA accessibility—large touch targets, clear visual hierarchy, and unmistakable active states—so users of all abilities can complete tasks with confidence.

- **Visual Tone:** Sunlit, grounded, and transparent. No emojis, no pure black (`#000000`), and no purple or neon glows.
- **Iconography:** Clean monochrome line icons with a consistent `2px` stroke weight.

## Colors

The palette is anchored in warm, sunlit neutrals and a deep botanical civic green, engineered to meet WCAG AAA contrast ratios without harsh pure black.

- **Canvas & Surfaces:**
  - **Canvas Alabaster (`#FAFAFA`):** Primary application background.
  - **Pure Paper Surface (`#FFFFFF`):** Elevated card and container surface, paired with a `1px` Whisper Border (`#E4E4E7`).
  - **Soft Stone Surface (`#F4F4F5`):** Secondary surface for recessed containers, input wells, and subtle grouping.
- **Primary Accent:**
  - **Agave Jade (`#135D4F`):** Reserved for primary CTA buttons, active selection rings, and microphone icon fills.
  - **Agave Mist (`#ECF5F3`):** Soft tinted surface for selected cards and active option states.
- **Typography & Borders:**
  - **Charcoal Ink (`#18181B`):** Primary text color, providing crisp readability against light surfaces without pure black.
  - **Slate Charcoal (`#3F3F46`) & Graphite Secondary (`#52525B`):** Secondary and supporting text hierarchy.
  - **Whisper Border (`#E4E4E7`):** Hairline `1px` structural borders for cards and dividers.

## Typography

The typographic system pairs geometric clarity with relaxed, accessible reading rhythms. All headings are left-aligned with tight tracking, while body copy maintains a minimum `16px` size and generous line height for effortless scanning.

- **Headings (`Outfit`):** SemiBold (`600`) and Bold (`700`) weights with tight negative letter-spacing (`-0.01em` to `-0.025em`) establish clear hierarchy without visual clutter.
- **Body Copy (`Geist`):** Regular (`400`) and Medium (`500`) weights at `16px` and `18px` with relaxed line heights (`1.5x` to `1.625x`) ensure comfortable reading on mobile screens.
- **Status & Metadata (`JetBrains Mono`):** Used exclusively for timestamps, case numbers, step indicators, and status badges to distinguish system metadata from narrative content.

## Layout & Spacing

This design system uses a **mobile-first fluid grid** that adapts cleanly across viewports while preserving generous breathing room and predictable touch targets.

- **Mobile (`< 640px`):** Single-column or 4-column fluid grid with `1.25rem` (`20px`) outer canvas margins and `1rem` (`16px`) gutters. Content stacks vertically with `1rem` to `1.5rem` vertical rhythm between cards.
- **Tablet (`640px – 1024px`):** 8-column fluid grid with `1.5rem` (`24px`) margins and `1rem` (`16px`) gutters. Related cards may pair into 2-column rows.
- **Desktop (`> 1024px`):** Centered 12-column fluid grid capped at a comfortable reading width (`720px` for focused civic flows, `1120px` for dashboard overviews) with `2rem` (`32px`) margins.

## Elevation & Depth

Depth is conveyed through **low-contrast outlines** paired with subtle **ambient shadows**, keeping the interface grounded and paper-like rather than floating.

- **Primary Cards:** Pure Paper Surface (`#FFFFFF`) resting on Canvas Alabaster (`#FAFAFA`), defined by a crisp `1px` Whisper Border (`#E4E4E7`) and a soft, diffused ambient shadow (`0 4px 16px -2px rgba(24, 24, 27, 0.05)`).
- **Recessed Surfaces:** Soft Stone Surface (`#F4F4F5`) sits flat against the canvas with no shadow to denote secondary or grouped regions.
- **Active & Selected States:** Selected cards transition to an Agave Mist (`#ECF5F3`) fill with a `2px` Agave Jade (`#135D4F`) selection ring, replacing shadow elevation with clear chromatic focus.

## Shapes

The shape language is approachable and tactile, balancing soft, welcoming containers with structured interactive controls.

- **Cards & Containers:** `24px` (`1.5rem`) border radius (`rounded-xl`) for all primary cards, modal sheets, and grouped panels.
- **Buttons & Interactive Controls:** `16px` (`1rem`) border radius (`rounded-lg`) for tactile flat buttons, input fields, and selectable list rows.
- **Metadata & Badges:** `8px` (`0.5rem`) border radius for compact status chips and `JetBrains Mono` metadata tags.

## Components

All components are built for WCAG AAA accessibility, featuring high-contrast states, unmistakable focus rings, and generous touch targets.

- **Buttons:** Tactile flat buttons with a minimum height of `52px` and `16px` border radius. Primary CTAs use Agave Jade (`#135D4F`) fill with Pure Paper (`#FFFFFF`) `Geist` Medium text. Secondary buttons use Soft Stone (`#F4F4F5`) fill with Charcoal Ink (`#18181B`) text and a `1px` Whisper Border (`#E4E4E7`).
- **Cards:** Pure Paper Surface (`#FFFFFF`), `24px` border radius, `1px` Whisper Border (`#E4E4E7`), and `1.5rem` (`24px`) internal padding. Selected cards use Agave Mist (`#ECF5F3`) fill with a `2px` Agave Jade (`#135D4F`) border.
- **Input Fields:** Minimum `52px` height, `16px` border radius, Soft Stone (`#F4F4F5`) or Pure Paper (`#FFFFFF`) background with a `1px` Whisper Border (`#E4E4E7`). Active focus displays a `2px` Agave Jade (`#135D4F`) ring.
- **Chips & Status Badges:** Compact pills using `JetBrains Mono` (`12px`–`13px`) for case status, deadlines, or step counts. Active chips use Agave Mist (`#ECF5F3`) with Agave Jade (`#135D4F`) text.
- **Lists & Selection Rows:** Full-width rows with minimum `56px` height, `16px` internal padding, and `2px` monochrome line icons.
- **Checkboxes & Radio Buttons:** `24px × 24px` hit-area targets (wrapped in a `48px` minimum touch container) with `2px` borders; checked states fill with Agave Jade (`#135D4F`) and a crisp white indicator.
- **Voice / Microphone Action:** A dedicated `52px+` tactile button or floating action trigger featuring a `2px` stroke microphone icon filled with Agave Jade (`#135D4F`) when active.