# Current Supabase State — Reconciliation Report

> ⚠️ **STALE — DO NOT TRUST.** This was a pre-rebuild snapshot from 2026-05-14, before Phase 1A. The schema has changed substantially since:
> - The full multi-table rebuild landed (migrations 0002–0009): accounts, profiles, birth_data, charts, profile_summaries, relationships, subscriptions, chat_sessions/messages, ai_responses, knowledge_chunks, plus astro_* spine.
> - Migration 0010 (2026-05-16) added chinese_zodiac_readings, human_design_readings, numerology_readings.
>
> **For current schema, read `supabase_master_doc.md` at the repo root — it is the source of truth.** This file is kept only for historical context.

**Generated:** 2026-05-14
**Authored by:** Claude Code (per Section 8 of `supabase_master_doc.md`)
**Status:** Read-only inventory. NO tables created, NO migrations run.
**Audience:** Beau — review before Phase 1A begins.

---

## TL;DR (read this first)

- **One Supabase project is shared between the web and mobile repos.** Both `.env.local` files point at `worbycfxsaeqwzlckvah.supabase.co`.
- **Only 2 tables are live in `public`:** `profiles` and `readings`. Both are from the web app's `001_initial_schema.sql`.
- **The mobile repo's `0001_mobile_core_schema.sql` was never applied.** It exists only as a file on disk. If we ran it as-is, three of its four `create table if not exists` statements would succeed (creating `birth_readings`, `quiz_results`, `notification_preferences`) and one (`profiles`) would silently no-op against the existing table — leaving the mobile code expecting columns that don't exist (`display_name`, `birth_timezone`, `birth_location_name`, `birth_latitude`, `birth_longitude`). **Do not run it.**
- **The deterministic spine (`astro_*` tables) is not in the database.** Master doc Phase 1A refers to migration files (`deterministic_schema.sql`, `deterministic_data_seed.sql`, `user_preferences_schema.sql`) which exist conceptually but were not located in either repo's `supabase/migrations/` directory. Beau will need to point me at them before Phase 1A.
- **`pgvector` is NOT enabled.** Required for Phase 1D.
- **The naming conflict on `profiles` is real and unavoidable.** Section 5.2 of the master doc anticipated this — recommended path is Option A (rename web's `profiles` → `account_profiles` and split it into `accounts` + `profiles` + `birth_data`). Details and a step-by-step plan are in Section 5 of this report.

---

## 1. Live database inventory

Project: `worbycfxsaeqwzlckvah` (region/plan inferred from URL; not queried). Queried via Supabase Management API on 2026-05-14.

### 1.1 Tables in `public`

```
profiles      (1 row,  10 columns)
readings      (20 rows, 6 columns)
```

That's the entire schema. No deterministic spine, no chat tables, no chart cache, no subscriptions.

### 1.2 `public.profiles` columns

| column            | type                       | nullable | default |
| ----------------- | -------------------------- | -------- | ------- |
| `id`              | `uuid`                     | NO       | — (FK to `auth.users.id`, PK) |
| `name`            | `text`                     | YES      | — |
| `birthdate`       | `date`                     | YES      | — |
| `birthtime`       | `time without time zone`   | YES      | — |
| `birth_lat`       | `numeric`                  | YES      | — |
| `birth_lng`       | `numeric`                  | YES      | — |
| `birth_location`  | `text`                     | YES      | — |
| `birth_utc_offset`| `text`                     | YES      | — |
| `created_at`      | `timestamptz`              | YES      | `now()` |
| `updated_at`      | `timestamptz`              | YES      | `now()` |

**Effective shape:** "auth.users + birth data merged into one row." Each row is a 1:1 sidecar to `auth.users`. There is no `account` / `profile` separation, no `subject_type`, no soft-delete, no `relationship_label`. The whole concept of "a profile is a person you care about" from the master doc does not exist here.

### 1.3 `public.readings` columns

| column        | type            | nullable | default |
| ------------- | --------------- | -------- | ------- |
| `id`          | `uuid`          | NO       | `gen_random_uuid()` (PK) |
| `user_id`     | `uuid`          | NO       | — (FK → `profiles.id`) |
| `type`        | `text`          | NO       | — (CHECK: `birth_chart \| human_design \| chinese_zodiac \| numerology \| mbti \| bigfive \| disc \| enneagram`) |
| `input_data`  | `jsonb`         | NO       | `'{}'::jsonb` |
| `result_data` | `jsonb`         | NO       | `'{}'::jsonb` |
| `created_at`  | `timestamptz`   | YES      | `now()` |

**Effective shape:** "one bag for every kind of reading the user has ever generated, keyed by `type`." The master doc's `charts`, `human_design_data`, `numerology_data`, `chinese_zodiac_data`, and the four quiz tables are all collapsed here under different `type` values.

### 1.4 Indexes

```
profiles_pkey          (id)
readings_pkey          (id)
readings_user_id_idx   (user_id)
readings_type_idx      (type)
readings_user_type_idx (user_id, type)
```

### 1.5 RLS policies (all enabled)

| table    | policy                          | cmd    | predicate |
| -------- | ------------------------------- | ------ | ---------------------------- |
| profiles | "Users can view own profile"    | SELECT | `auth.uid() = id` |
| profiles | "Users can update own profile"  | UPDATE | `auth.uid() = id` |
| readings | "Users can view own readings"   | SELECT | `auth.uid() = user_id` |
| readings | "Users can insert own readings" | INSERT | `auth.uid() = user_id` (with_check) |
| readings | "Users can delete own readings" | DELETE | `auth.uid() = user_id` |

**Gaps vs master doc Section 3.5:**

- No INSERT policy on `profiles` (the trigger `handle_new_user` writes via SECURITY DEFINER instead).
- No DELETE policy on `profiles` (no soft-delete pattern exists).
- No UPDATE policy on `readings`.

### 1.6 Triggers

| schema | table           | trigger                  | timing | event  | function |
| ------ | --------------- | ------------------------ | ------ | ------ | -------- |
| auth   | users           | `on_auth_user_created`   | AFTER  | INSERT | `public.handle_new_user()` — auto-creates an empty `profiles` row |
| public | profiles        | `on_profile_updated`     | BEFORE | UPDATE | `public.handle_updated_at()` — bumps `updated_at` |

### 1.7 Functions in `public`

- `handle_new_user()` — SECURITY DEFINER. Inserts `(id)` into `public.profiles` on auth signup.
- `handle_updated_at()` — generic `updated_at = now()` trigger.

No `match_knowledge_chunks`, `user_owns_profile`, `user_owns_relationship`, `user_owns_chat_session`, or `sync_account_plan_tier`.

### 1.8 Extensions

| extension          | version | notes                              |
| ------------------ | ------- | ---------------------------------- |
| `plpgsql`          | 1.0     | default                            |
| `pgcrypto`         | 1.3     | enabled                            |
| `uuid-ossp`        | 1.1     | enabled                            |
| `pg_stat_statements` | 1.11  | enabled (monitoring)               |
| `supabase_vault`   | 0.3.1   | Supabase secrets — leave alone     |

**Missing for Phase 1D:** `vector` (pgvector). Must be enabled before `knowledge_chunks` can be created.

### 1.9 Data currently present

| table        | rows | notes |
| ------------ | ---- | ----- |
| `auth.users` | 1    | a single test user (likely Beau). |
| `profiles`   | 1    | auto-created by `handle_new_user`. |
| `readings`   | 20   | five each of: `birth_chart`, `human_design`, `chinese_zodiac`, `numerology`. No quiz reading types present. |

These 21 rows are the entire production-data footprint. Migration cost is low because there's almost nothing to preserve, but **the plan should still treat them as real data** — the test user's birth data is what every dev flow has been built against and may be referenced from the web app code.

### 1.10 What's NOT here

The master doc names these tables; none exist live:

- **Deterministic spine:** `astro_planets`, `astro_signs`, `astro_houses`, `astro_aspects`, `astro_dignities`, `astro_decans`, `astro_lunar_phases`, `astro_elements`, `astro_modalities`, `astro_house_systems`, `astro_app_settings`, `astro_synastry_patterns`, `astro_moon_compatibility`, `astro_transit_significance`, `astro_points`, `astro_overridable_preferences`, `astro_preference_changes`.
- **User domain (planned MVP):** `accounts`, the new `profiles` (with `subject_type`), `birth_data`, `charts`, `profile_summaries`, `relationships`, `relationship_summaries`, `subscriptions`.
- **Knowledge domain:** `knowledge_chunks`.
- **Interaction domain:** `chat_sessions`, `chat_messages`, `ai_responses`.
- **Older shapes the master doc mentions reconciling:** `birth_charts`, `chart_cache`. **These do not exist live.** The "existing web schema reconciliation" that Section 5.2 of the master doc anticipates is *actually* a reconciliation against `profiles` (above) and `readings` — not `birth_charts`. Update master doc accordingly when the reconciliation lands.

---

## 2. Migration files on disk

### 2.1 `moon-rhythms` (web)

```
supabase/migrations/
└── 001_initial_schema.sql       <-- APPLIED (matches live DB exactly)
```

Creates `public.profiles`, `public.readings`, the `handle_new_user` trigger, the `handle_updated_at` trigger, and the five RLS policies listed above. Live DB matches this file 1:1.

### 2.2 `moon-rhythms-mobile`

```
supabase/migrations/
└── 0001_mobile_core_schema.sql  <-- NEVER APPLIED
```

Defines:

- `public.profiles` (different column set than the live table — `display_name`, `birth_date`, `birth_time`, `birth_timezone`, `birth_location_name`, `birth_latitude`, `birth_longitude`).
- `public.birth_readings` (label, chart_payload JSONB, human_design_payload JSONB, etc).
- `public.quiz_results` (mbti / big_five / enneagram / disc).
- `public.notification_preferences`.

**Important:** the mobile migration uses `CREATE TABLE IF NOT EXISTS` on `profiles`. If it were applied today against the live DB:

- `profiles` would NOT be modified (table exists; the `IF NOT EXISTS` clause silently skips). The mobile app would then expect columns that don't exist (`display_name`, `birth_date`, etc.) and fail.
- The other three tables WOULD be created.
- New RLS policies on `profiles` (`profiles_select_own`, `profiles_insert_own`, `profiles_update_own`) would be added alongside the existing two web policies — duplicates that pass `auth.uid() = id` twice, no conflict but noise.

**Recommendation:** do not apply this migration. It was written before the master doc existed and is now superseded by the master doc's Section 3 schema. Treat it as a historical artifact.

### 2.3 Files referenced by the master doc but NOT FOUND in either repo

The master doc's Phase 1A says: *"Apply the existing migration files (already designed in this conversation's artifacts): `deterministic_schema.sql`, `deterministic_data_seed.sql`, `user_preferences_schema.sql`."*

Neither repo's `supabase/migrations/` contains these files. Searches across the whole project tree did not turn them up. Either:

- They were drafted in the Claude chat where the master doc was created and never saved to disk — Beau will need to paste them in or hand me the artifacts.
- They live in a third location (Notion, Drive, another repo) — point me at it.

This is the **first blocker for Phase 1A**.

---

## 3. Overlaps with the master doc's Section 3 schema

### 3.1 Direct table-name collisions

| live table | master doc table | collision type |
| ---------- | ---------------- | -------------- |
| `public.profiles` | `public.profiles` (master doc §3.2) | **Same name, different semantics.** Live = "auth user + birth data merged." Master doc = "a person (self or other) the user cares about, owned by an account, with `subject_type` and `relationship_label`." Cannot coexist under one name. |

### 3.2 Concept-level overlaps (no name collision, but data needs to move)

| live concept | master doc destination | notes |
| ------------ | ---------------------- | ----- |
| `profiles.id, email (via auth.users), created_at` | `accounts` | Account-level fields (`plan_tier`, `astro_preferences`, soft-delete) get added on top. |
| `profiles.name` | `accounts.first_name`/`last_name` AND/OR new `profiles.display_name` | The old `name` is ambiguous (could be the account holder's name OR the display name for their "self" profile). Master doc separates these. |
| `profiles.birthdate/birthtime/birth_lat/birth_lng/birth_location/birth_utc_offset` | `birth_data` (linked to the "self" `profile_id` under the new model) | The web app's birth data needs to migrate into the new `birth_data` table. |
| `readings` rows where `type = 'birth_chart'` | `charts.chart_data` (JSONB, linked to the "self" `profile_id`) | The five existing birth-chart readings need to become five `charts` rows. |
| `readings` rows where `type` ∈ {`human_design`, `chinese_zodiac`, `numerology`} | **Scaffolded futures** (master doc §7). | These rows belong to features not in MVP scope. **Open question for Beau:** preserve as-is in `readings`, archive to a `legacy_readings` table, or drop on the floor? |
| `readings` rows where `type` ∈ quiz types | **Deferred (master doc §7 Quizzes).** | Currently 0 rows of these types live, so this is a no-op for migration. |

### 3.3 RLS / trigger overlaps

- The web `on_auth_user_created → handle_new_user()` trigger inserts a row into the current `public.profiles`. Post-rename it will need to insert into `public.accounts` instead (and possibly auto-create a corresponding `self` profile row in the new `public.profiles`).
- The `on_profile_updated → handle_updated_at()` trigger pattern needs to be re-applied to *every* new table per master doc §3.2 (the master doc shows defaults on each `updated_at` column but no triggers; many of those tables benefit from the same auto-bump trigger).

---

## 4. Web app code dependencies on the current schema

Quick scan of the web repo to inform impact analysis. (Confirm with a deeper grep before any schema rename.)

- `lib/supabase/server.js` is the only Supabase server client. There is no auto-generated types file pinning the schema.
- A grep for `'profiles'` and `'readings'` should be run before the rename — every read/write site needs to be updated. I did not run this grep yet; flagging it as **a required prep step** before Phase 1B.

Mobile app code dependencies: the mobile migration was never applied, so any mobile code referencing `birth_readings`, `quiz_results`, etc. is currently broken anyway. Re-aligning to the master doc schema is a fresh-start opportunity.

---

## 5. Reconciliation proposal

The master doc's Section 5.2 lays out two options for the `profiles` naming conflict. After reviewing the live DB, **Option A is the cleaner choice** because:

1. The live `profiles` table has almost no rows (1 row, 1 user). Migration cost is genuinely trivial.
2. The web app is the only consumer of the existing name. Renaming + updating call sites in one repo is bounded work.
3. The new `profiles` semantics (a `subject_type='self'|'other'` person tied to an `account_id`) is the design we want everywhere. Carving out a second name for it on mobile (`subject_profiles`, `astro_profiles`) leaves a permanent naming wart.
4. The mobile migration never shipped, so there's no installed-base concern on that side.

### 5.1 Proposed step order (do NOT execute yet — awaiting Beau)

This is the order I'd run things in once Beau approves. Each step is a separate, reversible migration file.

1. **Pre-flight: deterministic spine files.** Beau hands me `deterministic_schema.sql`, `deterministic_data_seed.sql`, `user_preferences_schema.sql`. I save them to `moon-rhythms-mobile/supabase/migrations/` with proper numbering. (Blocker — see §2.3.)
2. **Migration A — enable `pgvector`.** Single statement: `CREATE EXTENSION IF NOT EXISTS vector;`. Independent of any rename.
3. **Migration B — rename existing tables out of the way.**
   - `ALTER TABLE public.profiles RENAME TO web_profiles_legacy;`
   - `ALTER TABLE public.readings RENAME TO web_readings_legacy;`
   - Rename their indexes (Postgres doesn't auto-rename) to `web_profiles_legacy_*`, `web_readings_legacy_*`.
   - Existing RLS policies move with the rename.
   - **Critical:** before applying B, every call site in the web repo that touches `profiles`/`readings` must be updated to the new names. Otherwise the web app breaks the moment the migration runs.
4. **Migration C — drop or rewire the auth trigger.** The current `handle_new_user` trigger writes to a table that no longer exists under that name. Choose:
   - (a) Drop the trigger temporarily. New `accounts` row creation happens in app code at sign-up.
   - (b) Rewrite `handle_new_user` to insert into the new `public.accounts` + create a `self` profile row in `public.profiles`.
   - I recommend (b) since it preserves "account exists immediately after signup" semantics.
5. **Phase 1A proper.** Apply the deterministic spine migration files.
6. **Phase 1C.** Create `public.accounts`, the new `public.profiles`, `public.birth_data`, `public.charts`, `public.profile_summaries`, `public.relationships`, `public.relationship_summaries`, `public.subscriptions`, plus their RLS, indexes, and triggers from master doc §3.
7. **Migration D — backfill the existing user.** A one-shot script that:
   - Reads the single existing `auth.users` row.
   - Creates an `accounts` row.
   - Reads the existing `web_profiles_legacy` row (one row), splits it into a `self` row in the new `profiles` table and a `birth_data` row.
   - Reads `web_readings_legacy` where `type = 'birth_chart'` and inserts those into `charts` (linked to the new `self` profile).
   - Leaves the other reading types in `web_readings_legacy` for now (decision below).
8. **Migration E — phase out the legacy tables.** Once the backfill is verified, the web app no longer reads from `web_profiles_legacy` / `web_readings_legacy`, and the data is durably copied to the new tables, drop the legacy tables.

### 5.2 Open decisions for Beau before Phase 1A

Please confirm each:

1. **Confirm Option A from master doc §5.2.** Rename + split web's `profiles` into `accounts` + `profiles` + `birth_data` per master doc §3.2. (Recommended above.) Or pick Option B and live with `subject_profiles` as the new name.
2. **Where are the deterministic spine migration files** (`deterministic_schema.sql`, `deterministic_data_seed.sql`, `user_preferences_schema.sql`)? Paste them in chat, drop them in the project, or point me at the source.
3. **What to do with the non-birth-chart legacy readings** (`human_design`, `chinese_zodiac`, `numerology` — 5 rows each)?
   - Option α: leave them in `web_readings_legacy` indefinitely (read-only archive).
   - Option β: migrate them into deferred-feature tables (would require building empty future tables, which master doc §2.8 forbids).
   - Option γ: drop them. These are five rows of test data per type; almost certainly disposable.
   - Recommendation: **γ (drop) for the test user.** Reconfirm there's no real user data first.
4. **What's the cutover plan for the web app?** The rename in Migration B will break every site in the web codebase that touches `profiles`/`readings` until they're updated. Do we:
   - (i) Update web code first, deploy, then run the migration in a tight window (lowest risk, slight downtime).
   - (ii) Use compatibility views (`CREATE VIEW public.profiles AS SELECT * FROM public.web_profiles_legacy;`) to keep the web app running while the rename rolls out (more moving parts).
   - I'd suggest (i) — the web app has one production user (Beau) and minimal traffic; coordinated downtime is fine.
5. **Mobile schema starting point.** Should the mobile migration `0001_mobile_core_schema.sql` be deleted from the repo (it's now misleading) or moved to `supabase/migrations/_archive/`?
6. **The `handle_new_user` rewrite.** Confirm we want the trigger to auto-create both an `accounts` row AND a `self` `profiles` row on signup, OR keep that as an app-layer responsibility so signup and "profile created" are explicit user-visible steps.

### 5.3 What I am NOT proposing

- Deleting any data. The legacy tables will be renamed, not dropped, until backfill is verified.
- Touching `auth.users`. That table is Supabase-managed.
- Modifying the existing migration file `001_initial_schema.sql` in the web repo. New migrations are additive.
- Running anything against the live database. This document is the deliverable; the next deliverable will be the proposed migration files for review.

---

## 6. What I'm waiting on

Per master doc Section 8 step 5 ("Stop and wait for Beau's review. Do not create new tables, do not run migrations, do not modify the existing schema."), I am stopping here.

To unblock Phase 1A I need:

1. ✅ Confirmation on §5.2 question 1 (Option A vs B for the `profiles` rename).
2. ✅ The three deterministic spine migration files (§5.2 question 2).
3. ✅ A decision on legacy non-birth-chart `readings` rows (§5.2 question 3).
4. ✅ A cutover-plan choice for the web app rename (§5.2 question 4).
5. (Optional) Decisions on the smaller items in §5.2 questions 5–6.

Once 1–4 are settled, I can draft the migration files for review and we move into Phase 1A.

---

## 7. Sanity checks before continuing

- [ ] Confirm the `worbycfxsaeqwzlckvah` project is the only Supabase project in play (no staging/prod split that's hiding tables).
- [ ] Run a `grep -rn "from('profiles'\|from('readings'\|\.from(\"profiles\"\|\.from(\"readings\""` (or the JS-client equivalent) across both repos to catalog every call site that will need updating during the rename.
- [ ] Verify there's no scheduled job, edge function, or external integration writing to these tables that this doc missed.

These checks are not blockers for *reading* this report, but they should be done before any migration runs.

---

*End of report. No tables were created or migrations run in the writing of this document.*
