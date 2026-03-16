# Typography

Typography rendering details that make interfaces feel better.

## Text Wrapping

### text-wrap: balance

Distributes text evenly across lines, preventing orphaned words on headings and short text blocks. **Only works on blocks of 6 lines or fewer** (Chromium) or 10 lines or fewer (Firefox) — the balancing algorithm is computationally expensive, so browsers limit it to short text.

```css
/* Good — even line lengths on short text */
h1, h2, h3 {
  text-wrap: balance;
}
```

```css
/* Bad — default wrapping leaves orphans */
h1 {
  /* no text-wrap rule → "Read our
     blog" instead of balanced lines */
}
```

```css
/* Bad — balance on long paragraphs (silently ignored, wastes intent) */
.article-body p {
  text-wrap: balance;
}
```

**Tailwind:** `text-balance`

### text-wrap: pretty

Optimizes the last line to avoid orphans using a slower algorithm that favors better typography over performance. Unlike `balance`, it works on longer text — use this for body copy where you want to minimize orphans without the 6-line limit.

```css
p {
  text-wrap: pretty;
}
```

### When to Use Which

| Scenario | Use |
| --- | --- |
| Headings, titles, short text (≤6 lines) | `text-wrap: balance` |
| Body paragraphs, descriptions | `text-wrap: pretty` |
| Code blocks, pre-formatted text | Neither — leave default |

## Font Smoothing (macOS)

On macOS, text renders heavier than intended by default. Apply antialiased smoothing to the root layout so all text renders crisper and thinner.

```css
/* CSS */
html {
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
```

```tsx
// Tailwind — apply to root layout
<html className="antialiased">
```

### Good vs. Bad

```css
/* Good — applied once at the root */
html {
  -webkit-font-smoothing: antialiased;
}

/* Bad — applied per-element, inconsistent */
.heading {
  -webkit-font-smoothing: antialiased;
}
.body {
  /* no smoothing → heavier than heading */
}
```

**Note:** This only affects macOS rendering. Other platforms ignore these properties, so it's safe to apply universally.

## Tabular Numbers

When numbers update dynamically (counters, prices, timers, table columns), use tabular-nums to make all digits equal width. This prevents layout shift as values change.

```css
/* CSS */
.counter {
  font-variant-numeric: tabular-nums;
}
```

```tsx
// Tailwind
<span className="tabular-nums">{count}</span>
```

### When to Use

| Use tabular-nums | Don't use tabular-nums |
| --- | --- |
| Counters and timers | Static display numbers |
| Prices that update | Decorative large numbers |
| Table columns with numbers | Phone numbers, zip codes |
| Animated number transitions | Version numbers (v2.1.0) |
| Scoreboards, dashboards | |

### Caveat

Some fonts (like Inter) change the visual appearance of numerals with this property — specifically, the digit `1` becomes wider and centered. This is expected behavior and usually desirable for alignment, but verify it looks right in your specific font.

```css
/* With Inter font:
   Default:  1234  → proportional, "1" is narrow
   Tabular:  1234  → all digits equal width, "1" centered */
```

## Letter Spacing

Default letter-spacing is wrong at the extremes. Large headings need tighter tracking. Small uppercase text needs wider tracking. Ignoring this makes text feel amateurish.

### Exact Values

| Text type | Letter spacing | CSS | Tailwind |
|---|---|---|---|
| Large headings (32px+) | Tight | `letter-spacing: -0.025em` | `tracking-tight` |
| XL headings (48px+) | Tighter | `letter-spacing: -0.04em` | `tracking-[-0.04em]` |
| Body text | Default | `letter-spacing: normal` | (none needed) |
| Small uppercase labels | Wide | `letter-spacing: 0.05em` | `tracking-wide` |
| Tiny uppercase (badges) | Wider | `letter-spacing: 0.1em` | `tracking-widest` |

### Good vs. Bad

```css
/* Good — tightened large heading */
.page-title {
  font-size: 48px;
  font-weight: 700;
  letter-spacing: -0.04em;
}

/* Good — widened uppercase label */
.badge {
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Bad — default letter-spacing on large heading (too airy) */
.page-title {
  font-size: 48px;
  font-weight: 700;
}

/* Bad — default letter-spacing on ALL CAPS (letters feel cramped) */
.badge {
  font-size: 11px;
  text-transform: uppercase;
}
```

```tsx
// Good — Tailwind
<h1 className="text-5xl font-bold tracking-[-0.04em]">Page Title</h1>
<span className="text-xs font-semibold uppercase tracking-wide">New</span>

// Bad — no tracking adjustment
<h1 className="text-5xl font-bold">Page Title</h1>
<span className="text-xs font-semibold uppercase">New</span>
```

**Rule:** Never use `text-transform: uppercase` without also adding `letter-spacing`. The two always go together. At font sizes above 32px, always tighten letter-spacing.

### When to Adjust

| Adjust letter-spacing | Don't adjust |
|---|---|
| Headings 32px+ (tighten) | Body text at default sizes |
| All `text-transform: uppercase` (widen) | Monospaced / code text |
| Hero text, display type (tighten) | Text inside inputs |
| Small labels and badges (widen) | Already-adjusted typefaces (some display fonts ship with built-in tight tracking) |
