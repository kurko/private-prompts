# Spacing

Constrained spacing scales and whitespace principles.

## Use a Spacing Scale

Never use arbitrary spacing values. Use a constrained scale based on a 4px unit. Every spacing value in the UI should come from this scale.

### The Scale

| Value | Tailwind | Use for |
|---|---|---|
| 2px | `0.5` | Optical adjustments only |
| 4px | `1` | Tight inline gaps (icon + label) |
| 8px | `2` | Related elements within a group |
| 12px | `3` | Default padding in compact UI |
| 16px | `4` | Default padding, gaps between items |
| 24px | `6` | Section padding, card padding |
| 32px | `8` | Between distinct groups |
| 48px | `12` | Major section breaks |
| 64px | `16` | Page-level spacing |
| 96px | `24` | Hero sections, landing pages |

### Good vs. Bad

```css
/* Good — values from the scale */
.card { padding: 24px; }
.card-content { gap: 16px; }

/* Bad — arbitrary values */
.card { padding: 22px; }
.card-content { gap: 15px; }
```

```tsx
// Good — scale values
<div className="p-6 space-y-4">

// Bad — arbitrary bracket values for spacing
<div className="p-[22px] space-y-[15px]">
```

**Rule:** If you're reaching for Tailwind's bracket syntax `[Xpx]` for spacing, that's a signal the value isn't on the scale. Snap to the nearest scale value instead. The only exception is optical adjustments where `0.5` (2px) or `px` (1px) are needed.

## Generous Whitespace

When in doubt, add more space. Generous whitespace makes interfaces feel premium. Cramped spacing makes them feel cheap.

**Rule:** Start with more space than you think you need, then remove until it feels right. It's easier to identify "too much space" than "too little."

### Recommended Spacing

| Element | Minimum | Recommended | Premium feel |
|---|---|---|---|
| Card padding | `p-4` (16px) | `p-6` (24px) | `p-8` (32px) |
| Section gap | `gap-6` (24px) | `gap-8` (32px) | `gap-12` (48px) |
| Form field gap | `gap-3` (12px) | `gap-4` (16px) | `gap-6` (24px) |
| Page margin (mobile) | `px-4` (16px) | `px-5` (20px) | `px-6` (24px) |
| Page margin (desktop) | `px-6` (24px) | `px-8` (32px) | `px-12` (48px) |
| Between groups | `gap-6` (24px) | `gap-8` (32px) | `gap-16` (64px) |

### Good vs. Bad

```tsx
// Good — generous, breathing room
<div className="p-6 space-y-8">
  <section className="space-y-4">...</section>
  <section className="space-y-4">...</section>
</div>

// Bad — cramped, everything feels squeezed
<div className="p-3 space-y-2">
  <section className="space-y-1">...</section>
  <section className="space-y-1">...</section>
</div>
```
