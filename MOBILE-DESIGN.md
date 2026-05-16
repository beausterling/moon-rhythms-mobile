---
version: v1
name: Moon Rhythms — Mobile
description: Source of truth for the Moon Rhythms native app (Expo SDK 54 + React Native + NativeWind v4). Pairs with WEB-DESIGN.md — brand contract identical, platform implementation different.
colors:
  background:        "#000000"
  on-background:     "#FFFFFF"
  surface-1:         "#0A0A0F"
  surface-2:         "#14141C"
  text-primary:      "#FFFFFF"
  text-secondary:    "#D4D4D8"
  text-tertiary:     "#8A8A90"
  text-disabled:     "#5A5A60"
  border-hairline:   "#FFFFFF1A"
  border-strong:     "#FFFFFF59"
  glow-soft:         "#FFFFFF40"
  glow-bright:       "#FFFFFF99"
  shimmer-band:      "#FFFFFF47"
  destructive:       "#EF4444"
  on-destructive:    "#FFFFFF"
typography:
  brand-wordmark:
    fontFamily: JosefinSans-SemiBold
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.05em
  display:
    fontFamily: JosefinSans-SemiBold
    fontSize: 32px
    fontWeight: 600
    lineHeight: 1.2
  heading-lg:
    fontFamily: JosefinSans-SemiBold
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.2
  heading-md:
    fontFamily: JosefinSans-SemiBold
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.25
  title:
    fontFamily: JosefinSans-Regular
    fontSize: 20px
    fontWeight: 400
    lineHeight: 1.3
  body-lg:
    fontFamily: JosefinSans-Regular
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.55
  body:
    fontFamily: JosefinSans-Regular
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.55
  body-sm:
    fontFamily: JosefinSans-Regular
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: JosefinSans-Regular
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0.18em
  caption:
    fontFamily: JosefinSans-Regular
    fontSize: 11px
    fontWeight: 400
    lineHeight: 1.3
    letterSpacing: 0.18em
  numeric-xl:
    fontFamily: Inter-Regular
    fontSize: 44px
    fontWeight: 400
    lineHeight: 1.1
  numeric-lg:
    fontFamily: Inter-Regular
    fontSize: 28px
    fontWeight: 400
    lineHeight: 1.25
  numeric-md:
    fontFamily: Inter-Regular
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.5
  numeric-sm:
    fontFamily: Inter-Regular
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  cta-label:
    fontFamily: JosefinSans-SemiBold
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: 0.3px
rounded:
  none: 0px
  sm:   6px
  md:   12px
  lg:   16px
  xl:   20px
  pill: 9999px
spacing:
  base: 4px
  "1":  4px
  "2":  8px
  "3":  12px
  "4":  16px
  "5":  20px
  "6":  24px
  "8":  32px
  "10": 40px
  "12": 48px
  "16": 64px
  "20": 80px
  "24": 96px
  screen-padding: 16px
  card-padding:   16px
components:
  ghost-pill-button:
    backgroundColor: transparent
    textColor: "{colors.text-primary}"
    typography: "{typography.cta-label}"
    rounded: "{rounded.pill}"
    height: 56px
    padding: "0 32px"
    borderColor: "{colors.border-strong}"
    borderWidth: 1px
  ghost-pill-button-pressed:
    backgroundColor: "#FFFFFF0F"
  text-link:
    textColor: "{colors.text-tertiary}"
    typography: "{typography.body}"
  text-link-emphasis:
    textColor: "{colors.text-primary}"
    typography: "{typography.cta-label}"
  input-field:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.text-primary}"
    typography: "{typography.body}"
    rounded: "{rounded.md}"
    height: 52px
    padding: "0 16px"
    borderColor: "{colors.border-hairline}"
    borderWidth: 1px
  input-field-focused:
    backgroundColor: "{colors.surface-2}"
    borderColor: "{colors.border-strong}"
  input-field-error:
    borderColor: "{colors.destructive}"
  card:
    backgroundColor: "{colors.surface-1}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.xl}"
    padding: "{spacing.card-padding}"
    borderColor: "{colors.border-hairline}"
    borderWidth: 1px
  divider:
    backgroundColor: "{colors.border-hairline}"
    height: 1px
  data-row-label:
    typography: "{typography.label}"
    textColor: "{colors.text-tertiary}"
  data-row-value:
    typography: "{typography.numeric-md}"
    textColor: "{colors.text-primary}"
---

# Moon Rhythms — Mobile

## Overview

The native companion to moonrhythms.io. A quiet observatory in a phone — calm, precise, observational. The brand voice is identical to the web: black, white, glow, the moon as hero, the starfield as content. The mobile app is a thin HTTP client to the web's API surface, so the visual identity stays consistent across both.

There is **no accent color.** Emphasis comes from white **glow** instead of hue. The one allowed hue is `destructive` red, reserved for validation errors and destructive confirmations.

This file supersedes the prior aspirational `DESIGN.md` (deleted) and the planning-era `.planning/.../01-UI-SPEC.md` (deleted). The web pair lives in `~/Projects/moon-rhythms/WEB-DESIGN.md`.

**What's preserved from the current implementation:**
- Welcome screen composition (moon loop + NightSky + Begin button + tagline + Sign in link)
- 240px moon loop at 24fps from CDN WebP frames (649–1360)
- NightSky starfield (`components/NightSky.tsx`) — 150 stars + occasional satellites + rare shooting stars
- Josefin Sans (Regular + SemiBold) as the brand voice
- The ghost-pill Begin button with its 7.5s shimmer, inner glow, hairline border, and press feedback — now extracted as `components/ui/GhostPillButton.tsx` and reusable everywhere

Everything else in the app (tab bar, auth screens, home, birth matrix, chat, dashboard, quizzes) is up for redesign. See `CURRENT_MOBILE_DESIGN.md` for the current-state snapshot of those screens.

## Colors

Six text/surface roles, two glow roles, one destructive. Every value is the contract — never substitute a "close enough" hex.

- **Background `#000000`** — the body. Pure black. The NightSky overlays on top with `pointerEvents="none"`.
- **Surface-1 `#0A0A0F`** — card, input, message bubble fill. Barely brighter than black.
- **Surface-2 `#14141C`** — hovered/focused card, elevated sheet, focused input.
- **Text-primary `#FFFFFF`** — pure white. Headings, primary body text, numeric values, link emphasis, CTA labels.
- **Text-secondary `#D4D4D8`** — calmer white for long prose. Easier on the eye than pure white at body sizes.
- **Text-tertiary `#8A8A90`** — labels, captions, placeholders, helper copy, inactive tab tint. Neutral cool grey (replaces the old purple-grey `#8888aa`).
- **Text-disabled `#5A5A60`** — disabled buttons and inputs.
- **Border-hairline `#FFFFFF1A`** (10% white) — default 1px outline on cards, dividers, inputs.
- **Border-strong `#FFFFFF59`** (35% white) — the ghost-pill border, focused-input border.
- **Glow-soft `#FFFFFF40`** (25% white) — default glow on numeric readouts and the wordmark.
- **Glow-bright `#FFFFFF99`** (60% white) — emphasis glow (the moon, active scrub indicator, focused interactive elements).
- **Shimmer-band `#FFFFFF47`** (28% white) — peak of the ghost-pill shimmer gradient. Already encoded in `GhostPillButton.tsx`.
- **Destructive `#EF4444`** — the only allowed hue. Validation errors, destructive confirmations, sign-out text.

## Typography

Two families:

- **Josefin Sans (Regular 400 + SemiBold 600)** — currently loaded via `expo-font` in `app/_layout.tsx` lines 38–41. Used for **everything humans read**: welcome screen wordmark + tagline, screen titles, body copy, labels, CTA labels, links, chat bubbles. Already shipped.
- **Inter (Regular 400)** — **not yet loaded.** Used for every numeric readout: timestamps, degrees/minutes/seconds, percentages, kilometres, coordinates, UTC offsets. User picked Inter over IBM Plex Mono because it reads cleaner.

**To add Inter (follow-up, do this before redesigning the home screen):**

1. Download `Inter-Regular.ttf` from `https://fonts.google.com/specimen/Inter` (or `npx expo install expo-font` already covers the loader).
2. Place at `assets/fonts/Inter-Regular.ttf`.
3. Extend `app/_layout.tsx` font loader:
   ```ts
   const [fontsLoaded] = useFonts({
     "JosefinSans-Regular": require("../assets/fonts/JosefinSans-Regular.ttf"),
     "JosefinSans-SemiBold": require("../assets/fonts/JosefinSans-SemiBold.ttf"),
     "Inter-Regular": require("../assets/fonts/Inter-Regular.ttf"),
   });
   ```
4. Add to `tailwind.config.js`:
   ```js
   fontFamily: {
     josefin:          ["JosefinSans-Regular"],
     "josefin-semibold": ["JosefinSans-SemiBold"],
     inter:            ["Inter-Regular"],
   },
   ```
5. Native EAS build required (font is a native asset). After local test, run `eas build --profile preview --platform all`.

**Treatment rules:**
- `label` and `caption` are rendered ALL-CAPS by convention. Section eyebrows, data-row labels, metadata.
- Apply a soft glow to every numeric value at `numeric-md` and larger via React Native's `textShadow*` props:
  ```ts
  textShadowColor: "#FFFFFF40",
  textShadowOffset: { width: 0, height: 0 },
  textShadowRadius: 8,
  ```
  (RN renders one shadow per text element. We accept the single-layer limitation — phones don't need the doubled-up bloom that web gets via CSS.)
- For emphasis, swap to `textShadowColor: "#FFFFFF99"` (glow-bright) and `textShadowRadius: 12`.

## Layout & Spacing

4px base unit. NativeWind's default spacing scale matches this 1:1 (`p-1` = 4px, `p-4` = 16px, `p-6` = 24px). The same scale is used on web — every gap and pad is identical across platforms.

- **Screen padding (horizontal):** 16px (`px-4`). The starfield can bleed to the device edge; interactive content stays inside the safe area + 16px padding.
- **Card padding:** 16px (`p-4`) default. Use 20–24px (`p-5` / `p-6`) for primary surfaces with breathing room.
- **Vertical rhythm:** all gaps are multiples of 4px. Canonical "section break" gap is 48px (`mt-12`).
- **Safe areas:** wrap content in `SafeAreaView` (or `useSafeAreaInsets()`). The NightSky bleeds; interactive elements do not.
- **Whitespace philosophy:** generous, deliberate. If a screen feels empty, that's correct.

## Elevation & Glow

There are no drop shadows. Depth is conveyed by **hairline borders + white glow**, not shadow lifts.

- **Level 0:** background + NightSky overlay.
- **Level 1:** `surface-1` card with 1px `border-hairline`. Default content surface.
- **Level 2:** `surface-2` card with 1px `border-hairline`. Hovered or focused state.
- **Level 3 (emphasis only):** white glow ring via two stacked Views — the inner View is the element; the outer is a slightly larger transparent View with `shadowColor: "#FFFFFF"`, `shadowOpacity: 0.5`, `shadowRadius: 24`. iOS-only via `shadowProps`; Android uses `elevation` (less consistent — accept the divergence on Android or render a `react-native-svg` glow ring instead).

The ghost-pill button uses **three layered effects** that combine into the brand's signature CTA — these are all implemented inside `components/ui/GhostPillButton.tsx`:
1. 1px `border-strong` outline (top-level `View` with `borderColor`).
2. Inner top-to-transparent linear gradient (`expo-linear-gradient`, `#FFFFFF14 → #FFFFFF00`).
3. Periodic shimmer band (24px wide, 22.5° rotation, `expo-linear-gradient` `#FFFFFF00 → #FFFFFF47 → #FFFFFF00`, animated via `react-native-reanimated` with `withRepeat(withSequence(withDelay(7500, withTiming(1, {duration: 900}))))`).

Press state: `opacity: 0.85`, `transform: scale(0.98)`.

## Shapes

Same scale as web. Six radii. Pick one.

- `rounded.sm` (6px) — small ghost buttons, outlined badges.
- `rounded.md` (12px) — input fields, chat input, message bubbles.
- `rounded.lg` (16px) — secondary cards.
- `rounded.xl` (20px) — primary cards, modal panels.
- `rounded.pill` (9999px) — every primary CTA, every chip, every status badge. **Non-negotiable.**
- Circles (`borderRadius: <half of size>`) — moon visualization (`borderRadius: 120` on a 240×240 box), avatars, phase indicators.

No squared corners. No mixing pills with rounded rectangles in the same view.

## Components

### Shipped — `components/ui/`

- **`GhostPillButton.tsx`** — the canonical CTA. Props: `label`, `onPress`, `height?` (default 56), `shimmer?` (default true), `disabled?`, `style?`. Measures its own width via `onLayout` so it works at any width — full-bleed, inside a card, in a horizontal row. **Use this for every primary action in the app.**
- **`TextLink.tsx`** — tertiary action. Props: `prefix?`, `linkText`, `onPress`. Muted prefix + bright white emphasis word. Use for "Already have an account? Sign in", "Forgot password?", footer links.

### Shipped — `components/`

- **`NightSky.tsx`** — the starfield. Drop on any dark screen as `<NightSky />` directly under the root `<View>`. Pointer-events off. Generates once on mount and persists.

### Not yet extracted — to build as screens are redesigned

- **`<Screen>`** — wraps `SafeAreaView` + `View className="flex-1 bg-black"` + optional `NightSky`. Single-line replacement for the same 6-line preamble most screens repeat.
- **`<Input>`** — 52px height, surface-1 fill, hairline border that flips to border-strong on focus and destructive on error. Currently inlined in `sign-in.tsx`, `sign-up.tsx`, `birth-matrix.tsx`; extract on first redesign that touches them.
- **`<Card>`** — surface-1 fill, hairline border, 20px radius, 16px padding. Currently inlined everywhere.
- **`<NumericValue>`** — `Text` with Inter-Regular family + glow-soft text-shadow + `tabular-nums` (Inter has tabular figures available — enable via `fontVariant: ["tabular-nums"]`). The single point where mono-like steadiness comes in.
- **`<DataRow>`** — `label-left, value-right` horizontal pair. Composes `<NumericValue>` for the value side.
- **`<TabBarBackground>`** — `expo-blur` BlurView wrapper. Currently inlined in `app/(tabs)/_layout.tsx`; extract when the tab bar is redesigned.

### Moon imagery

Render at 240px circle on the welcome screen, 260px on the home tab, 80vw with a 500px cap if the design ever surfaces a "hero moon" page. Transparent background so the starfield shows through. **Never** crop the moon into a rectangle. **Never** apply a coloured tint.

### Starfield (already shipped)

`components/NightSky.tsx`. 150 stars at 0.5–2px white with 3–7s twinkle, occasional satellite drift (every 15–45s), rare shooting star (every 20–60s). `pointerEvents="none"`. Generates once on mount; do not regenerate on screen change.

## Platform Implementation (NativeWind v4)

**Current `tailwind.config.js` needs cleanup.** It still has:

```js
accent: "#7BA5FF",       // periwinkle blue — DELETE, no accent in this design
destructive: "#ef4444",  // keep
background: "#000000",   // keep
surface: "#12122a",      // DELETE — old purple-tinged surface, replace with #0A0A0F
border: "#2a2a4a",       // DELETE — replace with rgba border tokens
"text-primary": "#e8e8f0",   // ADJUST to #FFFFFF
"text-secondary": "#8888aa", // ADJUST to #8A8A90
```

Target tailwind theme extension:

```js
colors: {
  background:        "#000000",
  "surface-1":       "#0A0A0F",
  "surface-2":       "#14141C",
  "text-primary":    "#FFFFFF",
  "text-secondary":  "#D4D4D8",
  "text-tertiary":   "#8A8A90",
  "text-disabled":   "#5A5A60",
  destructive:       "#EF4444",
},
borderColor: {
  hairline: "rgba(255,255,255,0.10)",
  strong:   "rgba(255,255,255,0.35)",
},
fontFamily: {
  josefin:            ["JosefinSans-Regular"],
  "josefin-semibold": ["JosefinSans-SemiBold"],
  inter:              ["Inter-Regular"],
},
```

Don't ship this update as a standalone PR — apply it incrementally as screens are redesigned, so unredesigned screens that still reference the old `accent`/`surface`/`border` tokens don't break before they're touched.

Animation libraries already wired up: `react-native-reanimated` (shimmer, twinkle, scrubber), `react-native-gesture-handler` (pan), `expo-blur` (tab bar), `expo-linear-gradient` (button gradient + shimmer band), `expo-image` (moon frames). No new libs needed.

## Do's and Don'ts

- **Do** treat the night sky as content. Empty space + stars is the design, not absence.
- **Don't** introduce an accent color. The black/white/glow constraint is the brand. The current `accent: "#7BA5FF"` in `tailwind.config.js` is legacy and will be removed.
- **Do** use Inter for every number displayed to the user. Load it before redesigning the home screen.
- **Don't** use Inter for prose or labels. Inter is only the numeric voice.
- **Do** use `<GhostPillButton>` for every primary CTA. It carries the brand and is already animated.
- **Don't** build a new button component when `GhostPillButton` exists. Pass `shimmer={false}` if the screen is too busy for animation.
- **Do** apply a soft glow to numeric values at `numeric-md` and larger via `textShadow*` props.
- **Don't** use Android `elevation` for emphasis on dark backgrounds — it renders as a grey halo, not a glow. Use `shadowColor: "#FFFFFF"` on iOS; on Android, render a glow ring with absolute-positioned views or live with the divergence.
- **Do** preserve the 7.5s shimmer interval. It is the brand rhythm shared with the web ghost-pill.
- **Don't** ship more than two type families. Inter only appears when there's a number.
- **Do** wrap content in `SafeAreaView`. The NightSky bleeds; interactive elements stay inside the inset.
- **Don't** delete `components/NightSky.tsx` or change its star count. The current implementation runs well on real iOS and is part of what the user explicitly wants preserved.
- **Do** extract patterns to `components/ui/` as they're touched the second time. Inlining once is fine; inlining twice creates drift.
- **Don't** add the navy `#0a0a1a` background back. Pure `#000000` is the contract now.
