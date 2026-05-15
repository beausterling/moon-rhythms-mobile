# Phase 1 — Migration Plan

**Version:** 2.0 (revised after Beau said "start from scratch, drop everything")
**Date:** 2026-05-15
**Author:** Claude Code
**Status:** DRAFT — awaiting Beau's approval before any SQL is written (Deliverable C).
**Companion:** `docs/CALL_SITES_TO_UPDATE.md` in the web repo (Deliverable B).
**Supersedes:** v1.0 (which preserved test data via rename + backfill). Beau confirmed the existing 1 profile row and 20 readings rows are disposable.

---

## What changed in v2.0

Beau's call on 2026-05-15: *"i dont care about the existing profile because i created it. so you can delete it and we start from scratch. delete all of the data in the other table as well."*

This **eliminates the entire rename + backfill arc** from v1.0:

- ❌ Removed: rename `profiles` → `web_profiles_legacy`, rename `readings` → `web_readings_legacy`.
- ❌ Removed: backfill migration (no data to preserve).
- ❌ Removed: drop-legacy-tables migration (subsumed by a single `DROP TABLE` in the simplified cutover).
- ❌ Removed: open questions §4.1, §4.2, §4.3, §4.9 (all became moot when there's no data to preserve).

The migration count drops from 11 to 9 files. The deploy is now: drop, rebuild, sign in / sign up fresh. Web app code updates are still required because the API endpoints will read from new tables — but they're simpler now (no shape-translation gymnastics needed; we can write the new code clean rather than mimicking the legacy shape).

> **Auth user (you) — what happens.** Your existing `auth.users` row stays. The new `handle_new_user` trigger fires only on INSERT, so it won't run for you automatically. **Migration 0009 seeds an empty `accounts` row + empty `self` profile for your existing user** so you can log in on the new schema and finish onboarding through the normal app flow. Tradeoff: if you'd rather nuke your auth user too and re-sign-up from scratch (testing the trigger end-to-end), say the word and I'll swap migration 0009 for `DELETE FROM auth.users;`. Default keeps your login.

---

## 1. Migration file list (in execution order)

Nine files, numbered 0002–0010, sitting alongside the existing `0001_mobile_core_schema.sql` (which Decision 5 of the handoff moves to `_archive/`).

| # | Filename | Phase ref | Purpose |
|---|----------|-----------|---------|
| 0002 | `0002_enable_pgvector.sql` | 1.0 | `CREATE EXTENSION IF NOT EXISTS vector;`. Isolated so the toggle is reviewable on its own. |
| 0003 | `0003_astro_deterministic_schema.sql` | 1.1 | The 17 `astro_*` reference tables, their indexes, views (`v_planet_dignities`, `v_signs_full`, `v_houses_full`), the three SQL helpers (`get_effective_preference`, `set_user_preference`, `reset_user_preference`), and public-read RLS on every table. Per handoff §3.1. |
| 0004 | `0004_astro_deterministic_seed.sql` | 1.1 | Idempotent `INSERT … ON CONFLICT … DO UPDATE` seed: 10 planets, 12 signs, 12 houses, 11 aspects, 46 dignities, 36 decans, 8 lunar phases, 4 elements, 3 modalities, 4 house systems, 14 synastry patterns, 16 moon-compatibility cells, 10 transit-significance rows, 13 app settings, 7 overridable preferences. Per handoff §3.2. |
| 0005 | `0005_drop_legacy_tables.sql` | (new, replaces rename + backfill) | `DROP TRIGGER on_auth_user_created ON auth.users; DROP FUNCTION public.handle_new_user(); DROP TABLE public.readings; DROP TABLE public.profiles;` — in that order so FKs and triggers tear down cleanly. **All existing user data is destroyed by this migration.** Beau explicitly authorized. |
| 0006 | `0006_new_user_domain_schema.sql` | 1.4 | Creates `public.accounts`, the new `public.profiles` (with `subject_type`, `account_id`, `relationship_label`, soft-delete), `public.birth_data`, `public.charts` (with GIN index on `chart_data`), `public.profile_summaries`, `public.relationships`, `public.relationship_summaries`, `public.subscriptions`. Plus helper functions `user_owns_profile(UUID)` and `user_owns_relationship(UUID)`, the `sync_account_plan_tier()` trigger function + trigger, generic `updated_at` triggers, and all RLS policies per master doc §3.5. Per handoff §3.3. |
| 0007 | `0007_knowledge_corpus_schema.sql` | 1.5 | `public.knowledge_chunks` table with the HNSW vector index, the `match_knowledge_chunks` RPC, and RLS (authenticated read, service-role write). Table left empty (corpus loaded in Phase 1.8 via edge function). Per handoff §3.4. |
| 0008 | `0008_new_handle_new_user.sql` | 1.4 | Recreates the auth-signup trigger to insert one `accounts` row AND one `self`-typed `profiles` row whenever a new `auth.users` row appears. SECURITY DEFINER. Full SQL body in §3 of this plan. |
| 0009 | `0009_seed_existing_account.sql` | (new) | One-row seed: inserts an empty `accounts` row + empty `self`-profile for Beau's existing `auth.users` row, so his login still works on the new schema. Idempotent. **Skip-or-swap option:** replace this migration with `DELETE FROM auth.users;` if Beau wants to test the new trigger end-to-end via a fresh signup. |
| 0010 | `0010_interaction_domain_schema.sql` | 1.6 | Creates `public.chat_sessions`, `public.chat_messages`, `public.ai_responses`. Adds `user_owns_chat_session(UUID)` helper. RLS per master doc §3.5 — including the read-only-assistant-message rule (only `role='user'` may be inserted by authenticated callers). Per handoff §3.6. |

**Out of scope for Phase 1:** the knowledge-corpus seed (`sepharial_chunks_v1.json` → embeddings via OpenAI). Handoff §3.5 defers this to Phase 1.8 (an edge function / Node script, not SQL).

**Naming convention.** Four-digit zero-padded prefix (`0002_`, `0003_`, …) matching the existing `0001_mobile_core_schema.sql`. The mobile repo is the migration home going forward; the web repo's `001_initial_schema.sql` stays as-is for historical reference but is functionally retired the moment 0005 runs.

---

## 2. The seed migration for Beau's existing account (migration 0009)

Replaces the v1.0 backfill arc. One short script.

### 2.1 Source data

```
auth.users (1 row)
  id          = 64d3f1bd-66dd-4851-85fd-4adee2780f46
  email       = beaujsterling@gmail.com
  created_at  = 2026-04-13 03:06:30.852894+00
```

That's it. No more profile data, no more readings — both tables get dropped in 0005.

### 2.2 What 0009 creates

**`public.accounts`** — 1 row:

| column            | value                                    |
|-------------------|------------------------------------------|
| id                | `64d3f1bd-66dd-4851-85fd-4adee2780f46`   |
| email             | `beaujsterling@gmail.com`                |
| first_name        | `''` (empty — you fill in via onboarding)|
| last_name         | `NULL`                                   |
| plan_tier         | `'free'`                                 |
| astro_preferences | `'{}'::jsonb`                            |
| created_at        | `2026-04-13 03:06:30.852894+00` (preserved) |
| updated_at        | `NOW()`                                  |
| deleted_at        | `NULL`                                   |

**`public.profiles`** — 1 row, the self profile:

| column             | value                                 |
|--------------------|---------------------------------------|
| id                 | `gen_random_uuid()`                   |
| account_id         | `64d3f1bd-66dd-4851-85fd-4adee2780f46`|
| subject_type       | `'self'`                              |
| display_name       | `''` (you fill in)                    |
| relationship_label | `NULL`                                |
| created_at         | `NOW()`                               |
| updated_at         | `NOW()`                               |
| deleted_at         | `NULL`                                |

**No `birth_data` row, no `charts` row.** You enter birth data fresh via the normal onboarding flow. That flow goes through the updated `/api/profile` PUT endpoint (per Deliverable B §1.2), which writes to `birth_data` and `charts` correctly.

### 2.3 SQL strategy

The migration uses `INSERT … SELECT … FROM auth.users` so it generalizes to N existing users (still 1, but defensive). Each `INSERT` has `ON CONFLICT DO NOTHING` so re-running is safe.

---

## 3. The new `handle_new_user` trigger (migration 0008)

Unchanged from v1.0. Exact function body for review:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_first_name TEXT;
BEGIN
  -- raw_user_meta_data may carry a first_name from OAuth providers
  -- (Google, Apple). Fallback to '' so NOT NULL holds; onboarding fills it.
  v_first_name := COALESCE(NEW.raw_user_meta_data ->> 'first_name', '');

  INSERT INTO public.accounts (
    id, email, first_name, plan_tier, astro_preferences,
    created_at, updated_at
  )
  VALUES (
    NEW.id, NEW.email, v_first_name, 'free', '{}'::jsonb, NOW(), NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO public.profiles (
    id, account_id, subject_type, display_name, relationship_label,
    created_at, updated_at
  )
  VALUES (
    gen_random_uuid(), NEW.id, 'self', v_first_name, NULL, NOW(), NOW()
  );
  -- No ON CONFLICT: the partial unique index on (account_id) WHERE
  -- subject_type='self' should hard-fail on duplicate trigger fires.

  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

Validated in Deliverable D against a docker postgres — insert a fake auth user, confirm one row each in accounts + profiles, verify second insert hits the partial unique on the self profile.

---

## 4. Remaining open questions (down to 4)

The "delete everything" decision retired questions §4.1, §4.2, §4.3, §4.9 from v1.0. Still on the table:

### 4.1 (was §4.4) — redundant `pgcrypto` extension statement

`pgcrypto` is already enabled live. I plan to put `CREATE EXTENSION IF NOT EXISTS "pgcrypto";` at the top of `0006_new_user_domain_schema.sql` anyway for safety in the docker validation env. Idempotent and harmless on live. ✅/❌?

### 4.2 (was §4.5) — `charts` table write policy

Master doc §3.5 says writes are service-role only. The current web `/api/save-reading` endpoint uses the user-authenticated client (which fails under service-role-only RLS).

- **Option I:** Add `INSERT`/`UPDATE` RLS policy on `charts` `WITH CHECK (public.user_owns_profile(profile_id))`. Default-deny still holds (RLS gates on profile ownership); only the write path widens beyond service-role.
- **Option II:** Keep service-role-only. Refactor `/api/save-reading` to use the service-role client + add an explicit "this auth user owns this profile" check before the insert.

**Recommendation: Option I for Phase 1.** Less code surface in the cutover, revisit when Phase 2 edge functions land. ✅/❌?

### 4.3 (was §4.6) — `astro_dignities` row count

Handoff §4.2 expects `dignities ≈ 46`. Math: 10 planets × 4 dignities = 40, plus ~6 traditional rulerships (Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune carry a traditional ruler distinct from modern). Target exactly 46, documented in a SQL comment. No decision needed — flagging only so the validation row count is right.

### 4.4 (was §4.7) — API contract preservation in the web app

The web call-site updates (Deliverable B) keep `/api/profile`, `/api/readings`, `/api/save-reading` request/response shapes identical. Internals translate to the new tables. Avoids touching front-end code. ✅/❌?

---

## 5. Mapping to audit §5.1 plan

| Audit §5.1 step                          | New migration(s) | Notes |
|------------------------------------------|------------------|-------|
| 1. Pre-flight: deterministic spine files | (Deliverable C — files produced, not separate migrations) | |
| 2. Enable `pgvector`                     | 0002             | Isolated. |
| 3. Migration B — rename existing tables  | **Retired in v2.0** | Replaced by 0005 (DROP). |
| 4. Migration C — drop or rewire trigger  | 0005 (drops legacy trigger as part of dropping legacy tables) + 0008 (new trigger) | |
| 5. Phase 1A — apply deterministic spine  | 0003 + 0004      | Schema and seed are separate files for reviewability. |
| 6. Phase 1C — new user-domain tables     | 0006             | Single migration with all 8 tables + helpers + triggers + RLS. |
| 7. Migration D — backfill existing user  | **Retired in v2.0** | Replaced by 0009 (seed an empty account+profile for the existing auth user). |
| 8. Migration E — drop legacy tables      | **Merged into 0005** | Single combined drop. |
| (audit didn't list) — knowledge corpus   | 0007             | Empty table; corpus loaded in Phase 1.8. |
| (audit didn't list) — interaction domain | 0010             | |

---

## 6. What I'm NOT doing yet

- Not writing any SQL files. That's Deliverable C.
- Not touching the live database.
- Not updating any web app code. That's Deliverable B + a separate Vercel deploy.
- Not modifying `0001_mobile_core_schema.sql`. Decision 5 moves it to `_archive/`; happens as part of Deliverable C file work.
- Not implementing the knowledge-corpus seed (Phase 1.8 — edge function, separate work).
- Not implementing edge functions for chart calculation, summary synthesis, or chat (Phase 2).

---

## 7. Revised effort estimate

| Deliverable | What | Approx effort |
|-------------|------|---------------|
| C | Write all 9 SQL files (~1100 lines total — was 1500 in v1.0). Move archived migration. | 2 hours |
| D | Docker postgres validation + iteration. | 1 hour |
| Web code updates | Refactor 4 API endpoints to read/write new tables. No front-end change. Build + smoke test. Deploy to Vercel. | 1–2 hours |
| Live apply | Sequential 0002→0010 via Supabase SQL Editor, with verification gates per handoff §5.1. | 30–45 min |

Total: 4–6 hours of build work between approval and Phase 1 complete.

---

## 8. Stop

Per handoff §2 ("Stop after producing this document. Wait for review."), I'm stopping again. With the simplification, the remaining decisions are tiny:

1. ✅/❌ Approve the 9-migration list in §1.
2. ✅/❌ Confirm `0009_seed_existing_account.sql` keeps your auth.users row (default), OR swap to `DELETE FROM auth.users` for a true fresh signup test.
3. ✅/❌ Approve `handle_new_user` SQL in §3.
4. ✅/❌ Resolve §4.2 (Option I vs II for `charts` write policy) — Option I recommended.
5. ✅/❌ Approve §4.4 (preserve API endpoint contracts).

The other items in §4 are micro-confirmations, no real decision.

Once these land, Deliverable C is next.
