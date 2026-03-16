# Color

Color hierarchy, text on colored backgrounds, and systematic palettes.

## Text Color Hierarchy

Not all text is equal. Use exactly 3 levels of emphasis through color — never rely on font size alone to do the work that color should do. De-emphasize secondary information instead of over-emphasizing primary information. If everything is bold, nothing is bold.

### The 3 Levels

| Level | Use for | CSS | Tailwind (light) | Tailwind (dark) |
|---|---|---|---|---|
| Primary | Headings, labels, key info | `color: hsl(0 0% 9%)` | `text-gray-900` | `text-gray-100` |
| Secondary | Descriptions, supporting text | `color: hsl(0 0% 38%)` | `text-gray-500` | `text-gray-400` |
| Tertiary | Timestamps, metadata, captions | `color: hsl(0 0% 55%)` | `text-gray-400` | `text-gray-500` |

### Good vs. Bad

```css
/* Good — hierarchy through color */
.card-title { color: hsl(0 0% 9%); }
.card-description { color: hsl(0 0% 38%); }
.card-meta { color: hsl(0 0% 55%); }

/* Bad — hierarchy through size only, everything same color */
.card-title { color: black; font-size: 24px; font-weight: 800; }
.card-description { color: black; font-size: 16px; }
.card-meta { color: black; font-size: 12px; }
```

```tsx
// Good — Tailwind
<h3 className="text-gray-900 text-lg font-semibold">Title</h3>
<p className="text-gray-500">Description of the item.</p>
<span className="text-gray-400 text-sm">2 hours ago</span>

// Bad — everything black, differentiated only by size
<h3 className="text-black text-2xl font-extrabold">Title</h3>
<p className="text-black">Description of the item.</p>
<span className="text-black text-xs">2 hours ago</span>
```

### Never Use Pure Black

Pure `#000000` on white has excessive contrast that causes eye strain. Use `hsl(0 0% 9%)` / `text-gray-900` as the darkest text color.

```css
/* Good */
body { color: hsl(0 0% 9%); }

/* Bad */
body { color: #000000; }
```

## Text on Colored Backgrounds

Don't pick a specific grey for text on colored backgrounds — it will look washed out or clash. Use opacity-reduced white on dark backgrounds, or the darkest shade of the same hue on light tinted backgrounds.

### Exact Values

| Background | Text approach | CSS | Tailwind |
|---|---|---|---|
| Dark brand color | White with reduced opacity | `color: rgba(255, 255, 255, 0.85)` | `text-white/85` |
| Dark brand (secondary) | White, lower opacity | `color: rgba(255, 255, 255, 0.6)` | `text-white/60` |
| Light tinted surface | Darkest shade of same hue | `color: hsl(220 60% 20%)` | `text-blue-900` on `bg-blue-50` |

### Good vs. Bad

```css
/* Good — white with opacity on dark background */
.banner { background: hsl(220 60% 45%); }
.banner-title { color: rgba(255, 255, 255, 0.85); }
.banner-subtitle { color: rgba(255, 255, 255, 0.6); }

/* Bad — specific grey on colored background (looks muddy) */
.banner-title { color: #f5f5f5; }
.banner-subtitle { color: #6b7280; }
```

```tsx
// Good — Tailwind
<div className="bg-blue-600">
  <h2 className="text-white/85">Welcome</h2>
  <p className="text-white/60">Supporting text</p>
</div>

// Good — same-hue on light tinted surface
<div className="bg-blue-50">
  <h2 className="text-blue-900">Welcome</h2>
  <p className="text-blue-700">Supporting text</p>
</div>

// Bad — grey on colored background
<div className="bg-blue-600">
  <h2 className="text-gray-100">Welcome</h2>
  <p className="text-gray-500">Supporting text</p>
</div>
```

## Background Tinting

Instead of pure grey backgrounds, tint them with a subtle amount of your brand hue. This makes backgrounds feel intentional rather than default.

Take your brand hue, set saturation to 5–15%, lightness to 96–98%.

```css
/* Good — slate-tinted, feels designed */
.surface { background: hsl(220 10% 97%); }

/* Bad — pure grey, feels default */
.surface { background: hsl(0 0% 96%); }
```

```tsx
// Good — Tailwind greys with subtle hue
<div className="bg-slate-50">  {/* blue-tinted grey */}
<div className="bg-stone-50">  {/* warm-tinted grey */}

// Bad — pure neutral grey
<div className="bg-neutral-100">
<div className="bg-[#f5f5f5]">
```

**Rule:** Match the tint hue to your brand. Blue brand → `slate`. Warm brand → `stone` or `zinc`. Green brand → custom `hsl(150 8% 97%)`.
