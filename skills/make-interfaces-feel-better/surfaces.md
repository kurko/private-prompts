# Surfaces

Border radius, optical alignment, shadows, and image outlines.

## Concentric Border Radius

When nesting rounded elements, the outer radius must equal the inner radius plus the padding between them:

```
outerRadius = innerRadius + padding
```

This rule is most useful when nested surfaces are close together. If padding is larger than `24px`, treat the layers as separate surfaces and choose each radius independently instead of forcing strict concentric math.

### Example

```css
/* Good — concentric radii */
.card {
  border-radius: 20px; /* 12 + 8 */
  padding: 8px;
}
.card-inner {
  border-radius: 12px;
}

/* Bad — same radius on both */
.card {
  border-radius: 12px;
  padding: 8px;
}
.card-inner {
  border-radius: 12px;
}
```

### Tailwind Example

```tsx
// Good — outer radius accounts for padding
<div className="rounded-2xl p-2">       {/* 16px radius, 8px padding */}
  <div className="rounded-lg">          {/* 8px radius = 16 - 8 ✓ */}
    ...
  </div>
</div>

// Bad — same radius on both
<div className="rounded-xl p-2">
  <div className="rounded-xl">          {/* same radius, looks off */}
    ...
  </div>
</div>
```

Mismatched border radii on nested elements is one of the most common things that makes interfaces feel off. Always calculate concentrically.

## Optical Alignment

When geometric centering looks off, align optically instead.

### Buttons with Text + Icon

Use slightly less padding on the icon side to make the button feel balanced. A reliable rule of thumb is:
`icon-side padding = text-side padding - 2px`.

```css
/* Good — less padding on icon side */
.button-with-icon {
  padding-left: 16px;
  padding-right: 14px; /* icon side = text side - 2px */
}

/* Bad — equal padding looks like icon is pushed too far right */
.button-with-icon {
  padding: 0 16px;
}
```

```tsx
// Tailwind
<button className="pl-4 pr-3.5 flex items-center gap-2">
  <span>Continue</span>
  <ArrowRightIcon />
</button>
```

### Play Button Triangles

Play icons are triangular and their geometric center is not their visual center. Shift slightly right:

```css
/* Good — optically centered */
.play-button svg {
  margin-left: 2px; /* shift right to account for triangle shape */
}

/* Bad — geometrically centered but looks off */
.play-button svg {
  /* no adjustment */
}
```

### Asymmetric Icons (Stars, Arrows, Carets)

Some icons have uneven visual weight. The best fix is adjusting the SVG directly so no extra margin/padding is needed in the component code.

```tsx
// Best — fix in the SVG itself
// Adjust the viewBox or path to visually center the icon

// Fallback — adjust with margin
<span className="ml-px">
  <StarIcon />
</span>
```

## Shadows Instead of Borders

For **buttons, cards, and containers** that use a border for depth or elevation, prefer replacing it with a subtle `box-shadow`. Shadows adapt to any background since they use transparency; solid borders don't. This also helps when using images or multiple colors as backgrounds — solid border colors don't work well on backgrounds other than the ones they were designed for.

**Do not apply this to dividers** (`border-b`, `border-t`, side borders) or any border whose purpose is layout separation rather than element depth. Those should stay as borders.

### Shadow as Border (Light Mode)

The shadow is comprised of three layers. The first acts as a 1px border ring, the second adds subtle lift, and the third provides ambient depth:

```css
:root {
  --shadow-border:
    0px 0px 0px 1px rgba(0, 0, 0, 0.06),
    0px 1px 2px -1px rgba(0, 0, 0, 0.06),
    0px 2px 4px 0px rgba(0, 0, 0, 0.04);
  --shadow-border-hover:
    0px 0px 0px 1px rgba(0, 0, 0, 0.08),
    0px 1px 2px -1px rgba(0, 0, 0, 0.08),
    0px 2px 4px 0px rgba(0, 0, 0, 0.06);
}
```

### Shadow as Border (Dark Mode)

In dark mode, simplify to a single white ring — layered depth shadows aren't visible on dark backgrounds:

```css
/* Dark mode — adapt to whatever setup the project uses
   (prefers-color-scheme, class, data attribute, etc.) */
--shadow-border: 0 0 0 1px rgba(255, 255, 255, 0.08);
--shadow-border-hover: 0 0 0 1px rgba(255, 255, 255, 0.13);
```

### Usage with Hover Transition

Apply the variable and add `transition-[box-shadow]` for a smooth hover:

```css
.card {
  box-shadow: var(--shadow-border);
  transition-property: box-shadow;
  transition-duration: 150ms;
  transition-timing-function: ease-out;
}

.card:hover {
  box-shadow: var(--shadow-border-hover);
}
```

### When to Use Shadows vs. Borders

| Use shadows | Use borders |
| --- | --- |
| Cards, containers with depth | Dividers between list items |
| Buttons with bordered styles | Table cell boundaries |
| Elevated elements (dropdowns, modals) | Form input outlines (for accessibility) |
| Elements on varied backgrounds | Hairline separators in dense UI |
| Hover/focus states for lift effect | |

## Image Outlines

Add a subtle `1px` outline with low opacity to images. This creates consistent depth, especially in design systems where other elements use borders or shadows.

### Light Mode

```css
img {
  outline: 1px solid rgba(0, 0, 0, 0.1);
  outline-offset: -1px; /* inset so it doesn't add to layout */
}
```

### Dark Mode

```css
img {
  outline: 1px solid rgba(255, 255, 255, 0.1);
  outline-offset: -1px;
}
```

### Tailwind with Dark Mode

```tsx
<img
  className="outline outline-1 -outline-offset-1 outline-black/10 dark:outline-white/10"
  src={src}
  alt={alt}
/>
```

**Why outline instead of border?** `outline` doesn't affect layout (no added width/height), and `outline-offset: -1px` keeps it inset so images stay their intended size.

## Minimum Hit Area

Interactive elements should have a minimum hit area of 44×44px (WCAG) or at least 40×40px. If the visible element is smaller (e.g., a 20×20 checkbox), extend the hit area with a pseudo-element.

### CSS Example

```css
/* Small checkbox with expanded hit area */
.checkbox {
  position: relative;
  width: 20px;
  height: 20px;
}

.checkbox::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 40px;
  height: 40px;
}
```

### Tailwind Example

```tsx
<button className="relative size-5 after:absolute after:top-1/2 after:left-1/2 after:size-10 after:-translate-1/2">
  <CheckIcon />
</button>
```

### Collision Rule

If the extended hit area overlaps another interactive element, shrink the pseudo-element — but make it as large as possible without colliding. Two interactive elements should never have overlapping hit areas.

## Elevation Scale

Define a systematic shadow scale instead of picking ad-hoc shadow values. Higher elevation means larger blur, more vertical offset, and slightly lower opacity. The `--shadow-border` above is elevation level 0 (flush). These add levels 1 through 4.

### The Scale (Light Mode)

```css
:root {
  /* Level 0: flush — use --shadow-border above */

  /* Level 1: low — resting cards, form inputs */
  --shadow-sm:
    0px 1px 2px 0px rgba(0, 0, 0, 0.05),
    0px 1px 3px 0px rgba(0, 0, 0, 0.04);

  /* Level 2: medium — dropdowns, popovers, tooltips */
  --shadow-md:
    0px 2px 4px -1px rgba(0, 0, 0, 0.06),
    0px 4px 8px -1px rgba(0, 0, 0, 0.06);

  /* Level 3: high — modals, dialogs, drawers */
  --shadow-lg:
    0px 4px 8px -2px rgba(0, 0, 0, 0.08),
    0px 8px 24px -4px rgba(0, 0, 0, 0.08);

  /* Level 4: highest — toasts, command palettes */
  --shadow-xl:
    0px 8px 16px -4px rgba(0, 0, 0, 0.08),
    0px 16px 48px -8px rgba(0, 0, 0, 0.12);
}
```

Each level roughly doubles the blur and offset of the previous. Every shadow uses two layers — a tight "contact" shadow and a larger "ambient" shadow.

### Tailwind Equivalents

Tailwind ships with `shadow-sm` through `shadow-xl` that are close to these values. Use the custom vars if your project has a design system. Otherwise, Tailwind defaults are fine:

```tsx
<div className="shadow-sm">   {/* resting cards */}
<div className="shadow-md">   {/* dropdowns */}
<div className="shadow-lg">   {/* modals */}
<div className="shadow-xl">   {/* toasts */}
```

### When to Use Which Level

| Level | Shadow var | Use for | Tailwind |
|---|---|---|---|
| 0 | `--shadow-border` | Flush cards, bordered elements | ring |
| 1 | `--shadow-sm` | Resting cards, form inputs | `shadow-sm` |
| 2 | `--shadow-md` | Dropdowns, popovers, tooltips | `shadow-md` |
| 3 | `--shadow-lg` | Modals, dialogs, drawers | `shadow-lg` |
| 4 | `--shadow-xl` | Toasts, command palettes | `shadow-xl` |

**Rule:** Use elevation to signal interactivity. If it overlaps other content, it needs a higher shadow level than what it overlaps.

**Dark mode:** Shadows are nearly invisible on dark backgrounds. Compensate with slightly brighter border rings (the `--shadow-border` dark mode pattern above) rather than increasing shadow opacity.

## Icon Sizing and Stroke Consistency

Don't scale icons from their designed size. Icons designed at 24px look blurry or wrong at 20px or 32px. Match icon stroke weight to the font weight around them.

### Exact Values

| Context | Icon size | Stroke width | Tailwind |
|---|---|---|---|
| Inline with body text (14–16px) | 16px | 2px (filled preferred) | `size-4` |
| Inline with large text (18–20px) | 20px | 1.5px | `size-5` |
| Standalone buttons, navigation | 24px | 1.5px | `size-6` |
| Feature sections, hero areas | 32px+ | 1.5px (outlined ok) | `size-8` |

### Good vs. Bad

```css
/* Good — icon at designed size */
.nav-icon {
  width: 24px;
  height: 24px;
  stroke-width: 1.5px;
}

/* Bad — icon scaled to non-standard size (subpixel rendering issues) */
.nav-icon {
  width: 18px;
  height: 18px;
}
```

```tsx
// Good — use the icon's designed size
<UserIcon className="size-6" strokeWidth={1.5} />

// Bad — arbitrary size between designed sizes
<UserIcon className="size-[18px]" />
```

### Rules

- At small sizes (16px and below), prefer **filled/solid** icon variants — outlines become indistinct
- At large sizes (32px+), **outlined** icons work better — fills look heavy
- Match visual weight to font weight: light font (300–400) pairs with 1.5px stroke, semi-bold+ (600+) pairs with 2px stroke
- If using an icon library (Heroicons, Lucide), use the library's size variants instead of scaling with CSS

| Do | Don't |
|---|---|
| Use icons at designed sizes (16, 20, 24) | Scale a 24px icon to 18px |
| Match stroke weight to surrounding font weight | Use thin strokes next to bold text |
| Filled icons at 16px and below | Outlined icons at very small sizes |
| Outlined icons at 32px+ | Heavy filled icons in hero sections |
