# Moon — live tick + time-scrub implementation reference

> **Audience:** the next Claude session working in this mobile repo.
> **Source files in web repo** (`~/Projects/moon-rhythms`):
> - `pages/index.deploy.js` — the home page (everything below is in this file).
> - `lib/useTimeScrub.js` — the scrub hook.
> - `pages/api/moon-position.api.js` — single-snapshot API.
> - `pages/api/moon-timeline.api.js` — multi-sample timeline API.
> - `lib/moon.js` — server-side ephemeris call (Moshier Swiss Ephemeris via the `ephemeris` npm package).
>
> The mobile app should call the **same web API endpoints** (master doc: mobile = thin HTTP client). All math below is identical on either side — only the gesture handling differs.

---

## The trick in one sentence

We never compute the moon's position locally for the live display — we poll the server every 30 s, **measure the angular velocity between consecutive samples**, and **linearly extrapolate** from the last sample on a rAF loop. The arcseconds that appear to tick continuously are not server data — they're `lastSample.longitude + rate × elapsedMs`, re-rendered ~5× per second.

Scrubbing is unrelated: when the user drags, we ignore the live extrapolation and instead binary-search a precomputed timeline (`/api/moon-timeline`) and lerp between two bracketing samples. The drag gesture writes to a ref; a rAF throttle (50 ms) flushes it to React state to avoid 60 Hz re-renders.

---

## Part 1 — Live tick (the "seconds ticking by")

### 1.1 Server polling

Every 30 s, the page POSTs `/api/moon-position` (with optional `{ location: {latitude, longitude} }` from `navigator.geolocation`). Response shape comes from `getMoonPositionData()` in `lib/moon.js`:

```js
{
  timestamp,            // ISO string of the calculation moment
  moonLongitude,        // 0–360°, ecliptic longitude
  moonLatitude,
  moonDistanceKm,
  sunLongitude,
  moonPhase: { name, angle },   // angle is 0–360°
  illuminationPercent,          // 0–100
  illuminationFraction,
  phaseDaysPast,
  zodiacSign,                   // { name, glyph, ... }
  altitude: { apparentAltitude, azimuth },
  source: 'Moshier Ephemeris',
}
```

On the web side this is computed via the `ephemeris` npm package against pure JS Moshier ephemeris. Mobile does not need to reproduce this — just consume the JSON.

### 1.2 Measuring rate between samples

Every successful poll, we compare against the previous sample to derive `rate.lon`, `rate.angle`, `rate.illum` — each in *units per millisecond*. The relevant block (`pages/index.deploy.js:362–374`):

```js
if (prev && (now - prev.fetchedAt) > 10000) {
  const dt = now - prev.fetchedAt;
  const lonRate   = normalizeAngleDelta(data.moonLongitude, prev.moonLongitude) / dt;
  const angleRate = normalizeAngleDelta(data.moonPhase.angle, prev.moonPhase.angle) / dt;
  const maxRate = 1.0 / 3600000;   // 1°/hour clamp — sanity guard
  rateRef.current = {
    lon:   Math.max(-maxRate, Math.min(maxRate, lonRate)),
    angle: Math.max(-maxRate, Math.min(maxRate, angleRate)),
    illum: ((data.illuminationPercent ?? 0) - (prev.illuminationPercent ?? 0)) / dt,
  };
} else if (!prev) {
  // Bootstrap before we have two samples: assume ~0.5°/hr (close to moon's
  // average of ~0.55°/hr) so the display moves immediately on first load.
  rateRef.current = { lon: 0.5 / 3600000, angle: 0.5 / 3600000, illum: 0 };
}
```

`normalizeAngleDelta(curr, prev)` returns the short-arc delta clamped to ±180° — handles 0°↔360° wraparound. Without it, longitude crossing 360° would produce a -359° rate spike and the moon would visually rocket backwards.

`maxRate = 1.0 / 3600000` ≈ 1°/hour. The moon's true angular velocity is ~0.55°/hour. The clamp is purely defensive against API hiccups (network blip → very small `dt` → divide producing a huge rate). Pick the same clamp on mobile.

Refs (not state):
- `currentDataRef` — the most recent server sample (with its `fetchedAt` timestamp).
- `rateRef` — the derived rates.
- `displayRef` — the value currently being rendered (extrapolation target).
- `serverDataRef` — the raw last sample (used for things we don't extrapolate, like "altitude" or "zodiacSign", which are point-in-time and don't tick).

### 1.3 The rAF extrapolation loop

A single `requestAnimationFrame` loop runs continuously (mounted via `useEffect` on first render). On each frame, if 200 ms have elapsed since the last update **and** the user is not scrubbing, it recomputes `displayRef.current` from the last sample + rate × elapsed-since-fetch (`pages/index.deploy.js:400–420`):

```js
const frame = (timestamp) => {
  if (timestamp - lastUpdate >= 200) {
    if (!isScrrubbingRef.current) {
      const curr = currentDataRef.current;
      if (curr) {
        const elapsed = Date.now() - curr.fetchedAt;
        const rate = rateRef.current;
        displayRef.current = {
          lon:   normalize360(curr.moonLongitude + rate.lon * elapsed),
          angle: normalize360(curr.moonPhase.angle + rate.angle * elapsed),
          illum: curr.illuminationPercent + rate.illum * elapsed,
        };
        setTick(t => t + 1);   // forces a re-render to flush displayRef
      }
    }
    lastUpdate = timestamp;
  }
  rafId = requestAnimationFrame(frame);
};
```

Three things to note:

1. **5 fps, not 60.** The 200 ms throttle means we re-render about 5×/second. The moon's longitude moves ~0.55″/sec — at 5 fps that's ~0.1″ per frame, well under the noise floor of the visible character glyph change. Going to 60 fps would burn the JS thread for no visible gain.

2. **`setTick` is the only React signal.** All the data lives in refs. We bump a counter to force the render that flushes `displayRef.current` into the JSX. This pattern is the entire reason the display can update without state-churn cascades.

3. **`isScrrubbingRef.current`** (yes, with the triple-r typo it ships with) is checked **before** the extrapolation runs. When the user is dragging the moon, we don't want live updates fighting the scrub display — the scrub takes over completely.

### 1.4 Rendering the arcseconds

`getZodiacFromLongitude(lon)` (lines 53–67 of `index.deploy.js`) converts a longitude (0–360°) into `{ name, glyph, degrees, minutes, seconds }`:

```js
function getZodiacFromLongitude(lon) {
  const norm = ((lon % 360) + 360) % 360;
  const signIndex = Math.floor(norm / 30);
  const sign = ZODIAC_SIGNS[signIndex];
  const inSign = norm - signIndex * 30;          // 0–29.999°
  const degrees = Math.floor(inSign);
  const minutes = Math.floor((inSign - degrees) * 60);
  let seconds = Math.floor(((inSign - degrees) * 60 - minutes) * 60);
  if (seconds >= 60) { seconds = 0; minutes += 1; }
  return { name: sign.name, glyph: sign.glyph, degrees, minutes, seconds };
}
```

Then in the JSX: `{zodiac.degrees}° {zodiac.minutes.toString().padStart(2, '0')}' {zodiac.seconds.toString().padStart(2, '0')}"`.

Since `displayRef.current.lon` advances by a small fraction every 200 ms, and arcseconds are 1/3600 of a degree, the `seconds` integer ticks up by 1 roughly every 1.8 s of real time (60 arcmin/hr × 60 arcsec/min = 3600 arcsec/hr; moon moves at ~33 arcmin/hr ≈ 2000 arcsec/hr → ~1 arcsec every 1.8 s). That's the rhythm you see.

### 1.5 Pattern transfer to React Native

The whole live-tick system maps directly:

| Web                                          | React Native                                                                 |
|----------------------------------------------|------------------------------------------------------------------------------|
| `fetch('/api/moon-position', {...})`         | Same — `fetch` works.                                                        |
| `setInterval(fetchMoonPosition, 30000)`      | Same.                                                                        |
| `useRef` for `currentDataRef` / `rateRef`    | Same.                                                                        |
| `requestAnimationFrame` rAF loop             | Available in RN (polyfill is built in). Same API.                            |
| `setTick(t => t + 1)`                        | Same.                                                                        |
| `navigator.geolocation`                      | Use `expo-location`. Pass `{ latitude, longitude }` to the API in the body. |

**Do not** try to compute moon positions client-side on the device. The `ephemeris` npm package works in Node and the browser, but mobile would either need a pure-JS port (it actually is one — but ~200 KB of code + lookup tables) or a native module. Just call the existing web endpoint over HTTPS.

---

## Part 2 — The scrubber

### 2.1 Two-layer cache

Two independent fetches:
- **Live:** `/api/moon-position` once / 30 s (Part 1).
- **Timeline:** `/api/moon-timeline` once / 30 min, with an additional 15 min freshness check inside `useTimeScrub`. Shape (`pages/api/moon-timeline.api.js`):

```js
// POST body
{ location, rangeHours = 72, intervalHours = 2 }

// Response
{
  points: [
    { timestamp, moonLongitude, moonLatitude, moonDistanceKm, sunLongitude,
      moonPhase: {name, angle}, illuminationPercent, illuminationFraction,
      phaseDaysPast, zodiacSign, altitude, offsetMs: -259200000 },
    ...
    { ..., offsetMs:  259200000 },
  ],
  generatedAt
}
```

73 points covering ±72 h at 2 h spacing. Each point ≈ 200 bytes JSON → ~14 KB total. Tiny; even a 4G phone slurps it in <100 ms.

### 2.2 Look-up + interpolation

`useTimeScrub.getInterpolatedData(offsetMs)` (lib/useTimeScrub.js:79–133) does:

1. **Clamp** `offsetMs` to `[minOffset, maxOffset]` so dragging off the end snaps to the boundary instead of producing junk.
2. **Binary search** for the two points bracketing the requested offset. O(log n) — at 73 samples this is ~7 comparisons; at 169 (a week) it'd be ~8. Negligible.
3. **Lerp** every scalar field independently:
   - `lerpAngle` for angles (longitude, phase angle, sun longitude) — short-arc aware.
   - `lerp` for everything else (distance, latitude, illumination, phaseDaysPast).
4. **Pick nearest** sample's discrete fields (`zodiacSign.name`, `moonPhase.name`, `altitude`) — these don't lerp meaningfully across a sign boundary, so we just snap to the closer side.
5. **Interpolate the timestamp** itself between `a.timestamp` and `b.timestamp` so the "displayed time" matches the displayed position.

The two angle helpers:

```js
function normalize360(v) { return ((v % 360) + 360) % 360; }

function lerpAngle(a, b, t) {
  let delta = normalize360(b - a);
  if (delta > 180) delta -= 360;     // take the short way around
  return normalize360(a + delta * t);
}
```

### 2.3 Gesture → state pipeline

The drag handler writes raw pixel deltas to `pendingOffsetRef.current` *and nothing else* — never directly into React state. A separate rAF loop checks this ref and, only if 50 ms have elapsed since the last flush, calls `setScrubOffsetMs(offset)` + computes/sets `scrubDisplayData` (lib/useTimeScrub.js:36–52):

```js
const flush = (timestamp) => {
  if (pendingOffsetRef.current !== null && timestamp - lastFlushRef.current >= 50) {
    const offset = pendingOffsetRef.current;
    pendingOffsetRef.current = null;
    lastFlushRef.current = timestamp;
    setScrubOffsetMs(offset);
    const data = getInterpolatedDataRef.current(offset);
    if (data) setScrubDisplayData(data);
  }
  rafRef.current = requestAnimationFrame(flush);
};
```

This caps re-renders to ~20 fps even if the user is dragging like a maniac. Crucially, the gesture handler itself never blocks — it just stamps a ref, so it stays at full pointermove rate (~60 Hz) without React being involved.

### 2.4 Pointer math in `MoonDragArea` (pages/index.deploy.js:257–311)

```js
const DRAG_RANGE_MS = 72 * 60 * 60 * 1000;   // ±72 hours
const DRAG_TOTAL_MS = DRAG_RANGE_MS * 2;     // 144 hours total

// Inside onPointerDown:
const deltaX = e.clientX - startX.current;
const sensitivity = DRAG_TOTAL_MS / 600;     // 600 px = full ±range
let newOffset = startOffset.current + deltaX * sensitivity;
newOffset = Math.max(-DRAG_RANGE_MS, Math.min(DRAG_RANGE_MS, newOffset));
```

So 600 px of horizontal drag corresponds to 6 full days. Sensitivity ≈ 14.4 minutes per pixel. The moon container is the drag area (`w={{ base: '80vw', md: '500px' }}`).

### 2.5 Mobile gesture mapping

React Native equivalent:

```ts
// preferred — react-native-gesture-handler + react-native-reanimated already used elsewhere
import { Gesture, GestureDetector } from 'react-native-gesture-handler';

const DRAG_RANGE_MS = 72 * 60 * 60 * 1000;
const DRAG_TOTAL_MS = DRAG_RANGE_MS * 2;
const dragWidthPx = 500; // or measure the moon container's onLayout
const sensitivity = DRAG_TOTAL_MS / dragWidthPx;

const pan = Gesture.Pan()
  .onBegin(() => { startScrub(); })
  .onUpdate((e) => {
    const next = Math.max(
      -DRAG_RANGE_MS,
      Math.min(DRAG_RANGE_MS, startOffset.value + e.translationX * sensitivity)
    );
    pendingOffsetRef.current = next;   // identical to web — write to ref, let rAF flush
  });
```

The 50 ms throttle / `requestAnimationFrame` flush is unchanged on mobile — both APIs exist in RN. `useTimeScrub` itself can be lifted into the mobile repo essentially verbatim; only the gesture wiring at the call site needs `Gesture.Pan()` instead of `onPointerDown`.

---

## Part 3 — Widening the range to ±1 week

The user asked for ±1 week of scrub. Here's exactly what changes:

### 3.1 What stays the same

- The live-tick system (Part 1). Nothing — that's the always-now display.
- `useTimeScrub.js` math. Binary search, lerp, throttling — all range-agnostic.
- `/api/moon-timeline.api.js` API surface. It already takes `rangeHours` as a body param.

### 3.2 What changes

**On the web (pages/index.deploy.js):**

```js
// Old:
const DRAG_RANGE_MS = 72 * 60 * 60 * 1000;        // 72 h
// New:
const DRAG_RANGE_MS = 7 * 24 * 60 * 60 * 1000;    // 168 h
```

```js
// In useTimeScrub.js — fetchTimeline currently posts {} (server defaults to rangeHours=72).
// Either:
//   (a) change the server default to 168 in /api/moon-timeline.api.js, OR
//   (b) explicitly pass rangeHours: 168 in the body.
// Recommend (b) — keeps the API param tunable per caller (mobile can pick its own).
body: JSON.stringify({ location, rangeHours: 168, intervalHours: 2 }),
```

**Drag sensitivity considerations:**
- Current: 600 px → 144 h → ~14.4 min/px.
- After change with same `dragWidth=600`: 600 px → 336 h → ~33.6 min/px (~2.3× faster scrub).

You have two options for the sensitivity trade-off:

| Option | Result |
|---|---|
| Keep `sensitivity = DRAG_TOTAL_MS / 600`. | Easier to skim across a week, but precise minute-level positioning is harder. Probably what most users want. |
| Bump to `DRAG_TOTAL_MS / 1400`. | Same per-pixel granularity as today (~14 min/px), but you'd have to drag across 1400 px (= more than the screen) to reach the extreme. |

A pragmatic third option: **clamp drag-to-end by accelerating near the edges.** Not worth the code unless someone complains about either tradeoff in practice.

**Payload impact:**
- 73 samples × 200 B ≈ 14 KB → 169 samples × 200 B ≈ 34 KB. Inconsequential.

**Server CPU impact:**
- Moshier ephemeris call ≈ 5–10 ms per sample. Going from 73 → 169 doubles the function execution time from ~500 ms → ~1.2 s. Still well under the 60 s Vercel function timeout. The timeline is only re-fetched once per 15–30 min per user, so this is not a hot path.

**Interpolation accuracy at 2 h spacing across a week:**
- The moon's longitude is roughly cubic over any short interval; linear interpolation across 2 h windows produces <1 arcmin of error (verified empirically — Beau previously confirmed this works for the current 3-day range). Same holds across a week. **Do not** drop the interval to 1 h or lower — payload doubles for no visible gain.

### 3.3 Recommended implementation order

1. Bump `DRAG_RANGE_MS` in the web home page to one week.
2. Pass `rangeHours: 168` from `useTimeScrub.fetchTimeline` (or change the server default).
3. Smoke test in dev: drag to each extreme; confirm the clamp works and the date displayed is exactly ±7 days from now.
4. On mobile: copy `useTimeScrub.js` verbatim, set the same constants. Drag width comes from the moon container's measured `onLayout` width.

---

## Part 4 — Common pitfalls observed during development

1. **Refs vs state.** The whole thing only works because rate/current data live in refs. Putting them in state would trigger renders every poll, every frame, and React would slow to a crawl. Resist the urge to "clean this up" by useState-ifying these refs.
2. **Angle wraparound.** If you ever introduce a new angular field, route it through `lerpAngle` / `normalizeAngleDelta`, not raw subtraction. Crossing 0°/360° will look like a -359° spike.
3. **Throttle the gesture.** Don't `setState` on every pointermove — the pendingOffsetRef + rAF flush pattern is what keeps the scrub smooth. Mobile gesture handler libraries (RNGH/Reanimated) make it tempting to put the math in a worklet and skip React entirely. That works too, but means you have two display sources of truth (UI thread + JS thread) and they can desync. Until there's a clear perf problem, just port the React pattern.
4. **Rate clamp.** Forgetting `maxRate` will, the first time the user's network blips, cause the moon to teleport. Keep the 1°/hr clamp.
5. **Bootstrap rate.** Without the `!prev` branch that seeds rate to ~0.5°/hr, the display sits frozen on first paint until the second sample lands 30 s later. Looks broken. Always seed.

---

## Open file references

- `pages/index.deploy.js:53` — `getZodiacFromLongitude`
- `pages/index.deploy.js:257–311` — `MoonDragArea` (pointer gesture)
- `pages/index.deploy.js:347–388` — `fetchMoonPosition` + rate derivation
- `pages/index.deploy.js:396–424` — live rAF extrapolation loop
- `lib/useTimeScrub.js:36–52` — gesture flush loop
- `lib/useTimeScrub.js:79–133` — `getInterpolatedData`
- `pages/api/moon-timeline.api.js` — timeline server
- `pages/api/moon-position.api.js` — single-point server
- `lib/moon.js` — Moshier ephemeris wrapper (server-side only — do not import on mobile)
