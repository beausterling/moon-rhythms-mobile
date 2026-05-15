# Mobile Next Brief

**Audience:** the next coding agent working in `~/Projects/moon-rhythms-mobile`.
**Last updated:** 2026-05-15
**Status of web side:** Phase 1 (schema rebuild) + Phase 2a (AI chat) are shipped and verified in production at moonrhythms.io. See `docs/PHASE_1_COMPLETE.md` and (soon) `docs/PHASE_2A_COMPLETE.md` for the web-side sign-off detail.

This brief covers what's next on the **mobile** side specifically. It is not the master architecture doc — that's `supabase_master_doc.md` at the repo root.

---

## Top priority: Birth Matrix entry + astrology-only dashboard

### 1. New tab — "Birth Matrix" form

Add a fourth tab to the bottom tab bar. **Position: 2nd from the left** (between Home and Quizzes).

New tab order:

```
[Home] [Birth Matrix] [Quizzes] [Dashboard]
  🌙        ⊕            ?         ▦
```

Pick an icon that reads as "natal chart / wheel" — `wheel` from Ionicons or a custom SVG. Keep style consistent with the existing frosted-glass tab bar.

**Form requirements** — mirror the web's `pages/natal-form.deploy.js` flow:

- Display name (text input)
- Birth date (native date picker)
- Birth time (native time picker, plus an "I don't know my birth time" toggle)
- Birth location (Google Places autocomplete; the project already has `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` in the web env — use the same key on mobile, or proxy through the web's `/api/timezone` endpoint to get IANA tz + offset).
- Submit → POST `/api/save-reading` with `{ type: 'birth_chart', input_data, result_data }`.
  - `input_data` shape (matches web): `{ name, birthdate, birthtime, lat, lng, location, utc_offset }`
  - `result_data` shape: the chart JSONB returned by the web's `/api/SwissEphemerisChart` endpoint. Mobile should call `/api/SwissEphemerisChart` server-to-server (or proxy through the web) to get the chart, then save it.
  - When the call succeeds, the web's `save-reading.api.js` will:
    1. Upsert `birth_data`
    2. Upsert `charts`
    3. Auto-trigger profile synthesis (Opus, ~5s) if no `profile_summaries` row exists yet

**Birth-time-unknown handling:**
- Send `birthtime: null`. The chart will set `has_houses=false`; rising sign, midheaven, and house cusps will be omitted. The web app already handles this — match it.

### 2. Rework Dashboard — astrology-only for now

Strip the quiz cards from the mobile Dashboard temporarily. Show only astrology info:

- Sun / Moon / Rising trio at the top (sign + glyph + degree)
- A condensed view of the natal chart (could be the SVG wheel or just a list of placements)
- A "Recent readings" list showing only `type === 'birth_chart'` rows from `/api/readings`
- Hide quiz results until quizzes themselves ship on mobile

The web Dashboard already does this kind of conditional rendering — see `pages/dashboard.deploy.js` for the pattern (it iterates `READING_META` keys and renders cards only for completed reading types).

### 3. Wiring notes

- **Auth:** mobile uses Bearer tokens against `moonrhythms.io/api/*`. The web's `lib/supabase/server.js` already handles Bearer-token auth in addition to cookies — no API change required.
- **Save flow:** mobile must NOT mutate `birth_data` or `charts` directly via supabase-js. Always go through the web endpoints — they enforce IANA-timezone derivation, the chart UNIQUE constraint, and the synthesis auto-trigger. Direct Supabase writes would bypass synthesis.
- **Existing `/profile` PUT** already accepts birth data and updates `birth_data`. You can choose: either call `/profile` PUT (just updates birth_data + display_name) followed by chart generation, OR call `/save-reading` once with the full payload. The web app uses `/save-reading` in `lib/useSaveReading.js`. Match that flow.

---

## Out of scope for this brief

These are real but separate work items — don't bundle them in:

- **AI chat on mobile.** Phase 3 of `supabase_master_doc.md`. Will consume `/api/chat-respond` (SSE), `/api/chat-sessions`, `/api/chat-messages`, `/api/synthesize-profile-summary`. The web `/chat` page is the reference implementation.
- **Quizzes back on the Dashboard.** They'll return when quiz logic is ported / shipped. The web Dashboard's `READING_META` map is the data model to follow.
- **Subscriptions / paywall.** Phase 4 in master doc.

---

## How to verify when done

1. New tab visible at position 2 in dev build and EAS preview.
2. Form submits successfully against production moonrhythms.io.
3. After submission, refresh `/chat` on web in a browser — the AI chat should already know the new birth data (synthesis fires automatically).
4. Dashboard on mobile shows the saved chart only — no empty quiz cards.
5. Database check: `birth_data` and `charts` rows exist for the user; `profile_summaries` populates within ~10s of submission.

If anything in this brief is unclear or stale, check `supabase_master_doc.md` first, then ask the user.
