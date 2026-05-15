# Phase 1 — COMPLETE

**Date completed:** 2026-05-15
**Supabase project:** `worbycfxsaeqwzlckvah`
**Web deploy:** moonrhythms.io (Vercel, commit `c8bc842` on `main`)
**Mobile repo:** moon-rhythms-mobile (commit `6216284` on `master`)

Phase 1 of the Moon Rhythms Supabase build-out is fully delivered. The
schema is live, the deterministic spine is seeded, the knowledge corpus is
embedded, the web app is wired to the new schema, and end-to-end signup →
onboarding → chart save → dashboard verified against the production
moonrhythms.io site.

## What's live

### Schema (8 migrations, all applied)

| # | File | What it added |
|---|------|---------------|
| 0002 | `0002_enable_pgvector.sql` | pgvector 0.8.0 extension |
| 0003 | `0003_astro_deterministic_schema.sql` | 17 `astro_*` reference tables, 3 views, 3 helper SQL functions, public-read RLS |
| 0004 | `0004_astro_deterministic_seed.sql` | 211 reference rows (10 planets, 8 points, 12 signs, 12 houses, 11 aspects, 47 dignities, 36 decans, 8 lunar phases, 4 elements, 3 modalities, 4 house systems, 14 synastry patterns, 16 moon-compatibility cells, 10 transit-significance rows, 13 app settings, 7 overridable preferences) |
| 0005 | `0005_drop_legacy_tables.sql` | Dropped legacy `profiles`/`readings` and wiped `auth.users` for clean slate (Beau authorized full destruction) |
| 0006 | `0006_new_user_domain_schema.sql` | 8 user-domain tables (`accounts`, `profiles`, `birth_data`, `charts`, `profile_summaries`, `relationships`, `relationship_summaries`, `subscriptions`), helpers (`user_owns_profile`, `user_owns_relationship`, `set_updated_at`, `sync_account_plan_tier`), full RLS |
| 0007 | `0007_knowledge_corpus_schema.sql` | `knowledge_chunks` table, HNSW vector index, `match_knowledge_chunks` RPC |
| 0008 | `0008_new_handle_new_user.sql` | New auth-signup trigger auto-creates account + self profile on `auth.users` INSERT |
| 0009 | `0009_interaction_domain_schema.sql` | `chat_sessions`, `chat_messages`, `ai_responses` + `user_owns_chat_session` helper + RLS |

### Knowledge corpus (Phase 1.8 seed)

- 31 chunks from `moon_rhythms_build_bundle/sepharial_chunks_v1.json` embedded
  via OpenAI `text-embedding-3-small` (1536d) and loaded into `knowledge_chunks`.
- Breakdown: planet=10, house=12, aspect=5, framework=4. (sign and synastry
  chunk categories are 0 — starter corpus, extend post-MVP.)
- Cost: $0.000069 across 3,473 tokens.
- RPC `match_knowledge_chunks` smoke-tested with 4 semantic queries; every
  query returned the correct top-ranked chunk (Sun question → `planet_sun_nature`
  at sim=0.629, etc.).
- Script: `scripts/seed_knowledge_chunks.mjs` (idempotent, re-runnable).

### Web app

The 3 Supabase-touching API endpoints were rewritten to translate between the
legacy front-end contract and the new schema, so no front-end / mobile code
needs changes. Lives in `/Users/beausterling/Projects/moon-rhythms`:

- `pages/api/profile.api.js` — GET joins accounts + self profile + birth_data;
  PUT updates profile.display_name and upserts birth_data with IANA timezone
  derived from lat/lng (via `tz-lookup`).
- `pages/api/readings.api.js` — returns `charts` rows mapped to the legacy
  reading shape; deferred types (human_design, numerology, quizzes) return
  empty arrays.
- `pages/api/save-reading.api.js` — for `type='birth_chart'`, upserts
  birth_data + charts (UNIQUE on profile_id, so re-saving overwrites).
- `lib/supabase/legacyShape.js` — helper module with `parseUtcOffset`,
  `formatUtcOffset`, `timezoneFromLatLng`, `buildLegacyProfilePayload`,
  `buildLegacyChartReading`.
- `lib/supabase/server.js` — picks up Bearer-token auth so mobile clients
  can hit these endpoints without cookies.

### Auth configuration

- `site_url` updated from `http://localhost:3000` → `https://moonrhythms.io`
  (was misconfigured pre-cutover; caused the first signup confirmation
  email's redirect to break).
- `uri_allow_list` set to allow `https://moonrhythms.io/**`,
  `https://*.vercel.app/**`, `http://localhost:3000/**`, `http://localhost:3001/**`.

### Environment

`OPENAI_API_KEY` saved to all the right places:
- `~/.claude/secrets.env` (global secrets, mode 600)
- `moon-rhythms-mobile/.env.local`
- `moon-rhythms/.env.local`
- Vercel Production
- Vercel Development

(Vercel Preview env didn't take due to a CLI quirk; revisit when PR preview
deploys are needed.)

## End-to-end verification

Beau signed up on production moonrhythms.io as `beaujsterling@gmail.com` on
2026-05-15 at 07:57 UTC. The new schema captured:

| Table | Rows | Sample |
|-------|------|--------|
| `auth.users` | 1 | email_confirmed_at populated |
| `public.accounts` | 1 | first_name='', plan_tier='free' |
| `public.profiles` (self) | 1 | display_name='Beau James Sterling' |
| `public.birth_data` | 1 | 1991-01-02 10:16 Federal Way WA, America/Los_Angeles, -480 min |
| `public.charts` | 1 | has_houses=true, moshier-ephemeris, 11 planets in chart_data |

Dashboard rendered the chart on first visit; non-birth-chart sections
correctly empty per master doc §7.

## What's deferred (Phase 2 territory)

These are explicitly NOT in Phase 1 and need a fresh plan when ready:

- **Edge functions:** `calculate-chart`, `synthesize-profile-summary`,
  `synthesize-relationship-summary`, `chat-respond`,
  `embed-knowledge-chunks` (loop version), `regenerate-summaries`.
- **Mobile HTTP client refactor** to call the new endpoints directly (rather
  than via the web's `/api/*` translation layer).
- **RevenueCat / IAP integration** for subscriptions.
- **Additional knowledge corpus growth** (Alan Leo, Raphael, etc.) — the 31
  starter chunks are sufficient for MVP validation per handoff §3.
- **`ANTHROPIC_API_KEY`** — not yet in env. Required for Phase 2 chat synthesis.
- **Vercel Preview env OpenAI key** — CLI quirk needs revisiting if PR preview
  deploys become important.

## Known minor cleanups (not blocking)

- **Google Maps `SearchBox` deprecation notice** in browser console. Google
  gave 12+ months notice, no action needed until then. Migrate to
  `PlaceAutocompleteElement` when convenient.
- **`share-modal.js:1` console TypeError** — verified NOT in our codebase
  (grep returns no matches). Almost certainly from a browser extension on
  Beau's machine; reproducing requires testing in clean incognito.

## What "Phase 1 complete" means going forward

Anyone reading this doc later: the database is the canonical foundation for
the rest of the build. Edge functions, mobile client work, AI synthesis, and
chat UI all sit on top of this schema. The architectural decisions in
`supabase_master_doc.md` are now committed code; revisit them only with
deliberate intent.

Next is Phase 2 — start with `synthesize-profile-summary` (one-time text
generation per profile via Claude Opus, written into `profile_summaries`),
then `chat-respond` (the per-message chat loop using cached summaries +
`match_knowledge_chunks` retrieval).
