---
name: design-seed
description: Derive art direction for a design so it looks authentic and unique. Use for design inspiration and when the user says "let's design a landing page", "art direction", "this looks generic", "make it distinctive". Not for wireframes or information architecture.
---

# Design seed

Models pick the most likely option at every step, so asking for a "unique" or "random" design gives the same look on every run. A random string breaks that: the model reads patterns in the string and turns them into design decisions it would not reach on its own. The method is adapted from Sakana AI's String Seed of Thought, where the model writes the string itself; here a shell command generates it, so every run starts from a different string.

## When it applies

The seed sets art direction: palette, typography, composition, imagery, texture and motion.

- **Structure comes first.** If the layout, content hierarchy or information architecture is still open, settle it with a plain look (neutral grays, one accent, system fonts) before seeding. A strong look hides structural problems.
- **A concept overrides the seed.** If the user gave a concept (a game, an art movement, a place, an object), the concept is the direction. Seed only the decisions the concept leaves open.
- **A fixed design system skips it.** If the project's tokens already set palette and type, the art direction is decided.

## Steps

1. Generate one string per direction you need:

   ```bash
   openssl rand -base64 48
   ```

   Run the command instead of writing a string yourself; the command gives a different string on every run.

2. Read the string closely. Look past the surface for subpatterns: repeated or mirrored characters, runs, digit groups and the numbers they form, letter clusters, case changes, positions. Turn what you find into decisions about hue and contrast, type pairing, grid and density, shape language, imagery and motion. You choose the mapping; there is no fixed table.

3. Write the direction in five to seven lines:
   - Palette, with hex values
   - Type, with font names
   - Composition and grid
   - Imagery and texture
   - Motion
   - A real-world reference the direction evokes (a poster style, a game, an interior, a printed object)

4. Build from the direction with your own judgment. It is inspiration, not a spec. Keep text contrast accessible and keep the craft standards the work already has.

5. Keep the string out of the design: don't use it, or pieces of it, in copy, class names or any visible text. Report the direction to the user, not the string.

For several variants, generate one string each. If two directions come out alike, generate a new string for one of them.
