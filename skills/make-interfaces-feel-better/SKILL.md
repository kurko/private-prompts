---
name: make-interfaces-feel-better
description: Design engineering principles for making interfaces feel polished. Use when building UI components, reviewing frontend code, implementing animations, hover states, shadows, borders, typography, micro-interactions, enter/exit animations, or any visual detail work. Triggers on UI polish, design details, "make it feel better", "feels off", stagger animations, border radius, optical alignment, font smoothing, tabular numbers, image outlines, box shadows, color hierarchy, text color, spacing scale, letter spacing, tracking, elevation, icon sizing, icon stroke.
---

# Details that make interfaces feel better

Great interfaces rarely come from a single thing. It's usually a collection of small details that compound into a great experience. Apply these principles when building or reviewing UI code.

## Quick Reference

| Category | When to Use |
| --- | --- |
| [Typography](typography.md) | Text wrapping, font smoothing, tabular numbers |
| [Surfaces](surfaces.md) | Border radius, optical alignment, shadows, image outlines, hit areas |
| [Animations](animations.md) | Interruptible animations, enter/exit transitions, icon animations, scale on press |
| [Color](color.md) | Text hierarchy, colored backgrounds, background tinting |
| [Spacing](spacing.md) | Spacing scale, whitespace, card/section padding |
| [Performance](performance.md) | Transition specificity, `will-change` usage |

## Core Principles

### 1. Concentric Border Radius

Outer radius = inner radius + padding. Mismatched radii on nested elements is the most common thing that makes interfaces feel off.

### 2. Optical Over Geometric Alignment

When geometric centering looks off, align optically. Buttons with icons, play triangles, and asymmetric icons all need manual adjustment.

### 3. Shadows Over Borders

Layer multiple transparent `box-shadow` values for natural depth. Shadows adapt to any background; solid borders don't.

### 4. Interruptible Animations

Use CSS transitions for interactive state changes — they can be interrupted mid-animation. Reserve keyframes for staged sequences that run once.

### 5. Split and Stagger Enter Animations

Don't animate a single container. Break content into semantic chunks and stagger each with ~100ms delay.

### 6. Subtle Exit Animations

Use a small fixed `translateY` instead of full height. Exits should be softer than enters.

### 7. Contextual Icon Animations

Animate icons with `opacity`, `scale`, and `blur` instead of toggling visibility. Use exactly these values: scale from `0.25` to `1`, opacity from `0` to `1`, blur from `4px` to `0px`. If the project has `motion` or `framer-motion` in `package.json`, use `transition: { type: "spring", duration: 0.3, bounce: 0 }` — bounce must always be `0`. If no motion library is installed, keep both icons in the DOM (one absolute-positioned) and cross-fade with CSS transitions using `cubic-bezier(0.2, 0, 0, 1)` — this gives both enter and exit animations without any dependency.

### 8. Font Smoothing

Apply `-webkit-font-smoothing: antialiased` to the root layout on macOS for crisper text.

### 9. Tabular Numbers

Use `font-variant-numeric: tabular-nums` for any dynamically updating numbers to prevent layout shift.

### 10. Text Wrapping

Use `text-wrap: balance` on headings. Use `text-wrap: pretty` for body text to avoid orphans.

### 11. Image Outlines

Add a subtle `1px` outline with low opacity to images for consistent depth.

### 12. Scale on Press

A subtle `scale(0.96)` on click gives buttons tactile feedback. Always use `0.96`. Never use a value smaller than `0.95` — anything below feels exaggerated. Add a `static` prop to disable it when motion would be distracting.

### 13. Skip Animation on Page Load

Use `initial={false}` on `AnimatePresence` to prevent enter animations on first render. Verify it doesn't break intentional entrance animations.

### 14. Never Use `transition: all`

Always specify exact properties: `transition-property: scale, opacity`. Tailwind's `transition-transform` covers `transform, translate, scale, rotate`.

### 15. Use `will-change` Sparingly

Only for `transform`, `opacity`, `filter` — properties the GPU can composite. Never use `will-change: all`. Only add when you notice first-frame stutter.

### 16. Minimum Hit Area

Interactive elements need at least 40×40px hit area. Extend with a pseudo-element if the visible element is smaller. Never let hit areas of two elements overlap.

### 17. Text Color Hierarchy

Use 3 levels of text color (primary `text-gray-900`, secondary `text-gray-500`, tertiary `text-gray-400`) to create visual hierarchy. De-emphasize secondary info instead of over-emphasizing primary info. Never use pure black for text.

### 18. Text on Colored Backgrounds

On dark colored backgrounds, use white with reduced opacity (`text-white/85`) instead of a specific grey. On light tinted backgrounds, use the darkest shade of the same hue (`text-blue-900` on `bg-blue-50`).

### 19. Spacing Scale

Use a constrained 4px-based spacing scale. If you're reaching for Tailwind's bracket syntax `[Xpx]` for spacing, snap to the nearest scale value instead.

### 20. Letter Spacing

Tighten letter-spacing on headings 32px+ (`-0.025em` to `-0.04em`). Widen on uppercase text (`0.05em` to `0.1em`). Never use `text-transform: uppercase` without adding `letter-spacing`.

### 21. Elevation Scale

Define shadow levels (sm, md, lg, xl) with increasing blur and offset. Use elevation to signal interactivity — if it overlaps other content, it needs a higher shadow than what it overlaps.

### 22. Icon Sizing

Use icons at their designed size (16, 20, 24px). Match icon stroke weight to surrounding font weight. Prefer filled variants at 16px and below, outlined at 32px+.

## Common Mistakes

| Mistake | Fix |
| --- | --- |
| Same border radius on parent and child | Calculate `outerRadius = innerRadius + padding` |
| Icons look off-center | Adjust optically with padding or fix SVG directly |
| Hard borders between sections | Use layered `box-shadow` with transparency |
| Jarring enter/exit animations | Split, stagger, and keep exits subtle |
| Numbers cause layout shift | Apply `tabular-nums` |
| Heavy text on macOS | Apply `antialiased` to root |
| Animation plays on page load | Add `initial={false}` to `AnimatePresence` |
| `transition: all` on elements | Specify exact properties |
| First-frame animation stutter | Add `will-change: transform` (sparingly) |
| Tiny hit areas on small controls | Extend with pseudo-element to 40×40px |
| Pure black text (`#000`) | Use `text-gray-900` / `hsl(0 0% 9%)` |
| Grey text on colored background | Use `text-white/85` or same-hue darker shade |
| Arbitrary spacing values (`gap-[15px]`) | Snap to 4px scale (`gap-4`) |
| No letter-spacing on large headings | Add `tracking-tight` at 32px+ |
| No letter-spacing on uppercase text | Always pair `uppercase` with `tracking-wide` |
| Same shadow on cards and modals | Use systematic elevation scale (sm through xl) |
| Scaling icons to non-standard sizes | Use designed sizes (16, 20, 24px) |

## Review Checklist

- [ ] Nested rounded elements use concentric border radius
- [ ] Icons are optically centered, not just geometrically
- [ ] Shadows used instead of borders where appropriate
- [ ] Enter animations are split and staggered
- [ ] Exit animations are subtle
- [ ] Dynamic numbers use tabular-nums
- [ ] Font smoothing is applied
- [ ] Headings use text-wrap: balance
- [ ] Images have subtle outlines
- [ ] Buttons use scale on press where appropriate
- [ ] AnimatePresence uses `initial={false}` for default-state elements
- [ ] No `transition: all` — only specific properties
- [ ] `will-change` only on transform/opacity/filter, never `all`
- [ ] Interactive elements have at least 40×40px hit area
- [ ] Text uses 3-level color hierarchy (primary, secondary, tertiary)
- [ ] No pure black text — darkest is gray-900
- [ ] Text on colored backgrounds uses opacity or same-hue shading
- [ ] All spacing values come from the 4px scale
- [ ] Headings 32px+ have tightened letter-spacing
- [ ] Uppercase text has widened letter-spacing
- [ ] Shadows follow the elevation scale (sm/md/lg/xl)
- [ ] Icons are at their designed size, not arbitrarily scaled
- [ ] Icon stroke weight matches surrounding font weight

## Reference Files

- [typography.md](typography.md) — Text wrapping, font smoothing, tabular numbers, letter spacing
- [color.md](color.md) — Text hierarchy, colored backgrounds, background tinting
- [spacing.md](spacing.md) — Spacing scale, whitespace, card/section padding
- [surfaces.md](surfaces.md) — Border radius, optical alignment, shadows, image outlines, elevation, icon sizing
- [animations.md](animations.md) — Interruptible animations, enter/exit transitions, icon animations, scale on press
- [performance.md](performance.md) — Transition specificity, `will-change` usage
