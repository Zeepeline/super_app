# Design System Document: The Sonic Curator

## 1. Overview & Creative North Star
The "Creative North Star" for this design system is **"The Digital Curator."** 

We are moving away from the "utility-first" look of standard streaming apps and toward a high-end, editorial experience. The goal is to make the user feel like they are interacting with a premium physical vinyl collection through a digital lens. We achieve this by rejecting rigid, boxy layouts in favor of **intentional asymmetry** and **tonal depth**.

The design system breaks the "template" mold by utilizing overlapping elements—such as album art bleeding into the background or text layers floating above glass containers—to create a sense of immersion. Every screen should feel like a custom-designed poster, not a data grid.

---

## 2. Colors: Tonal Depth & The Neon Pulse
Our palette is rooted in the "Deep Black" (`#0e0e0e`) to ensure maximum contrast for the vibrant `primary` neon green.

### The Palette Logic
- **Primary (`#72fe8f`):** Use sparingly. This is your "Pulse." It is reserved for active states, playback progress, and high-priority CTAs.
- **Surface Hierarchy:** We use a "Dark Matter" approach. 
    - `surface`: The foundation layer.
    - `surface-container-low`: Primary sections.
    - `surface-container-highest`: Elevated interactive elements.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to section off content. 
Boundaries must be defined solely through background color shifts. For example, a tracklist should sit on a `surface-container-low` section, while the individual track rows remain on `surface`. This creates a cleaner, more sophisticated aesthetic that relies on human perception of "blocks" rather than artificial "cages."

### The "Glass & Gradient" Rule
To move beyond a flat UI, we employ **Glassmorphism**. For floating elements like the Mini-Player or Navigation Bar, use `surface-variant` with a 60% opacity and a `backdrop-blur` of 20px. 
- **Signature Textures:** For Hero sections or large Play buttons, use a subtle linear gradient transitioning from `primary` (`#72fe8f`) to `primary-container` (`#1cb853`) at a 135-degree angle.

---

## 3. Typography: Editorial Authority
We utilize two typefaces to create a hierarchy of "Information vs. Emotion."

- **Display & Headline (Plus Jakarta Sans):** These are our "Editorial" voices. They should be used with tight letter-spacing (-2%) to feel authoritative and modern. 
- **Body & Labels (Inter):** Our "Utility" voice. Inter provides maximum legibility at small scales for track durations, artist names, and metadata.

**Hierarchy Strategy:**
- Use `display-lg` for curated playlist titles to create a "Magazine Cover" feel.
- Use `label-sm` in all-caps with 5% letter-spacing for secondary metadata (e.g., "RELEASE DATE") to add a premium, technical touch.

---

## 4. Elevation & Depth: The Layering Principle
Hierarchy is achieved through **Tonal Layering**, not shadows.

- **Stacking Surfaces:** Instead of a shadow, place a `surface-container-highest` card on a `surface` background. The subtle shift from `#0e0e0e` to `#262626` is enough to define the object.
- **Ambient Shadows:** If an element must float (like a Context Menu), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4)`. The shadow must never be pure black; it should feel like an ambient occlusion.
- **The "Ghost Border" Fallback:** If a container lacks contrast (e.g., on a complex image background), use the `outline-variant` token at **15% opacity**. This creates a "breath" of a border rather than a hard line.
- **Glass Integration:** Player controls must use glassmorphism to let album art colors "bleed" through, making the UI feel reactive to the music being played.

---

## 5. Components: Purposeful Interaction

### Buttons
- **Primary:** High-gloss. Use the `primary` to `primary-container` gradient. Roundedness: `full`.
- **Secondary:** Glass-style. `surface-variant` at 20% opacity with a `backdrop-blur`.
- **Tertiary:** Text-only using `on-surface-variant`. On hover, shift to `on-surface`.

### Album Art Cards
- **Rounding:** Use `xl` (1.5rem) for main gallery cards; `md` (0.75rem) for small list thumbnails.
- **Interaction:** On hover, cards should scale by 2% and increase in brightness. Never use a border on a card.

### Track Lists
- **Rule:** Forbid divider lines. 
- **Separation:** Use 8px of vertical whitespace (`spacing-sm`) between items. Active tracks should be highlighted by changing the text color to `primary` and applying a `surface-container-low` background to the entire row.

### Interactive "Liquid" Slider
- The seek bar should not be a static line. The "played" portion uses the `primary` green, while the "unplayed" portion is `outline-variant` at 30% opacity. The handle (thumb) should only appear on hover to reduce visual clutter.

### Navigation Bar
- Positioned at the bottom, using a glassmorphic `surface-container-high` container. Icons should be "hollow" when inactive and "solid/filled" with a `primary` glow when active.

---

## 6. Do's and Don'ts

### Do:
- **Do** use asymmetrical layouts (e.g., a large album cover on the left with text pushed to the far right).
- **Do** use `surface-bright` for hover states to give a "metallic" glow effect.
- **Do** ensure all touch targets are at least 44x44px, even if the icon inside is smaller.

### Don't:
- **Don't** use 100% white (`#ffffff`) for body text; use `on-surface-variant` (`#adaaaa`) to reduce eye strain in dark mode. Save pure white for Headlines.
- **Don't** use standard "Drop Shadows." If it doesn't look like a natural ambient light falloff, remove it.
- **Don't** use dividers. If the layout feels cluttered, increase the spacing scale rather than adding lines.
- **Don't** use the `error` red for anything other than destructive actions (e.g., "Delete Playlist"). It will clash with the `primary` green pulse.