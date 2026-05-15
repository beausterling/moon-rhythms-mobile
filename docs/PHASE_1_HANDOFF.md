# Moon Rhythms — Phase 1 Handoff to Claude Code

**Version:** 1.0
**Date:** 2026-05-14
**Status:** Audit complete. Ready to execute Phase 1.
**For:** Claude Code. Read this top to bottom before doing anything.

---

## Read order

1. This document (the handoff — decisions and next steps)
2. `docs/supabase_master_doc.md` (architecture reference — already in repo)
3. `docs/CURRENT_SUPABASE_STATE.md` (audit you produced — already in repo)

This handoff resolves all open decisions from Section 5.2 of the audit and authorizes Phase 1 to proceed.

---

## 1. All six open decisions — locked

### Decision 1 — Naming conflict: **Option A confirmed**

Rename the live tables out of the way and build the new schema with the names from master doc §3.

- `public.profiles` → `public.web_profiles_legacy`
- `public.readings` → `public.web_readings_legacy`
- Rename their indexes accordingly (Postgres doesn't auto-rename indexes).
- Existing RLS policies move with the rename (Postgres handles this automatically).

Reasoning: 1 row in the live `profiles` table, 1 user, 1 repo consuming the names. Trivial migration cost. The alternative leaves a permanent naming wart in the schema forever.

### Decision 2 — Deterministic spine migration files: **regenerate them**

The `deterministic_schema.sql`, `deterministic_data_seed.sql`, and `user_preferences_schema.sql` files referenced in the master doc were drafted in a prior Claude conversation and never saved to disk. They are NOT in the repo and the original `moon_rhythms_build_bundle.zip` is missing or was not properly unzipped.

**Do not block on finding the originals.** Regenerate them from the specifications below in Section 3 of this handoff. The specs are complete enough to produce equivalent files. The originals were validated end-to-end against fresh Postgres 16; your regenerated versions should be validated the same way (see Section 4).

### Decision 3 — Legacy non-birth-chart readings: **drop them**

The 15 non-`birth_chart` rows in `web_readings_legacy` (human_design, chinese_zodiac, numerology — 5 each) are test data from earlier exploration. None of those features are in MVP scope (master doc §7). Do not preserve them.

In the backfill migration: insert only `type = 'birth_chart'` rows into the new `charts` table. The other rows stay in `web_readings_legacy` and get dropped along with that table at the end of Phase 1 cleanup.

### Decision 4 — Web app cutover plan: **Option (i) — update web code first, then run rename**

Sequence:

1. Grep both repos for every call site touching `profiles` and `readings`. Catalog them in `docs/CALL_SITES_TO_UPDATE.md` in the web repo.
2. Update each web call site to reference the new schema names.
   - "Account-level fields" (id, email, created_at) map to the new `accounts` table.
   - "Birth data fields" (birthdate, birthtime, birth_lat, etc.) map to the new `birth_data` table, linked via the `self` profile.
   - Display name maps to either `accounts.first_name` or `profiles.display_name` depending on context.
3. Test the web app locally against a Supabase branch if available, otherwise test after migration.
4. Deploy the updated web app code.
5. Run the rename migrations.
6. Run the new-schema migrations.
7. Run the backfill migration.
8. Verify the web app still works end-to-end.

Accept brief coordinated downtime between steps 4 and 8. The web app has one user (Beau) and zero real traffic. Do NOT build compatibility views — added complexity for no real benefit.

### Decision 5 — Old mobile migration: **move to archive**

Move `moon-rhythms-mobile/supabase/migrations/0001_mobile_core_schema.sql` to `moon-rhythms-mobile/supabase/migrations/_archive/0001_mobile_core_schema.sql`. Do not delete — preserve for historical context. Add a note at the top of the moved file:

```sql
-- ARCHIVED 2026-05-14
-- This migration was drafted before the master architecture doc existed.
-- It was never applied to any environment and is superseded by the
-- migrations in this directory. Preserved for historical reference only.
-- See docs/supabase_master_doc.md for the active schema.
```

### Decision 6 — `handle_new_user` trigger rewrite: **auto-create account AND self profile**

The existing trigger inserts into `public.profiles`. After the rename, that table no longer exists under that name. Rewrite the trigger to:

1. Insert into `public.accounts` with:
   - `id = NEW.id` (the auth.users UUID)
   - `email = NEW.email`
   - `first_name = COALESCE(NEW.raw_user_meta_data->>'first_name', '')` (empty string is fine for MVP — mobile fills it during onboarding)
   - `plan_tier = 'free'`
   - `astro_preferences = '{}'::JSONB`
2. Insert into the NEW `public.profiles` with:
   - `account_id = NEW.id`
   - `subject_type = 'self'`
   - `display_name = COALESCE(NEW.raw_user_meta_data->>'first_name', '')`
   - `relationship_label = NULL`

Use SECURITY DEFINER as the original trigger does. The invariant we want: "after signup, every user has both an account row and a self-profile row." Birth data is filled in the subsequent onboarding step, attached to the existing self-profile.

---

## 2. Your next deliverables (in order)

Do these in order. Stop and report after each.

### Deliverable A — Migration plan document

Produce `docs/PHASE_1_MIGRATION_PLAN.md` in the mobile repo. Include:

1. List of every migration file you propose to create, in execution order, with filenames and a one-paragraph description of what each does.
2. The exact backfill plan for the 1 existing user's data: what rows get created in which new tables.
3. The exact `handle_new_user` rewrite plan (the SQL function body you intend to ship).
4. Any new open questions or risks you spot now that you have decisions in hand.
5. An explicit mapping of each migration to a step in the audit's §5.1 plan.

Stop after producing this document. Wait for review.

### Deliverable B — Call site catalog

In parallel with Deliverable A (or right after), produce `docs/CALL_SITES_TO_UPDATE.md` in the **web** repo. This catalogs every place in the web codebase that references the soon-to-be-renamed tables.

Run this grep:

```bash
grep -rn "from('profiles')\|from('readings')\|\.from(\"profiles\")\|\.from(\"readings\")" \
  --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" \
  /Users/beausterling/Projects/moon-rhythms
```

For each match, document:
- File path and line number
- The exact code line
- What change is needed (which new table/column it maps to)

Stop after producing this document. Wait for review.

### Deliverable C — Migration files (only after A and B are approved)

Once Deliverables A and B are reviewed and approved, write the actual migration SQL files. Do not write SQL before then.

Follow the existing numbering convention in the mobile repo's `supabase/migrations/` directory. Use sequential numbers (`0002_`, `0003_`, ...) matching the existing `0001_mobile_core_schema.sql` style.

### Deliverable D — Local validation

Before any migration runs against the live Supabase project, validate against a local Postgres 16 instance:

```bash
docker run -d --name moon-rhythms-pg-test \
  -e POSTGRES_PASSWORD=test \
  -p 5433:5432 \
  -e POSTGRES_DB=test \
  postgres:16

docker exec moon-rhythms-pg-test psql -U postgres -d test \
  -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Apply migrations in order:
for f in supabase/migrations/*.sql; do
  echo "Applying: $f"
  cat "$f" | docker exec -i moon-rhythms-pg-test psql -U postgres -d test
done

# Run verification queries (see Section 4 of this handoff)

# Cleanup:
docker rm -f moon-rhythms-pg-test
```

Report results before any deployment to the live project.

### Deliverable E — Live deployment

Only after all above are approved, apply migrations to the live Supabase project in the documented order. Confirm with Beau before each migration runs in production.

---

## 3. Deterministic spine specifications

These specs are complete enough to regenerate the missing SQL files. Produce them as part of Deliverable C.

### 3.1 File: `astro_deterministic_schema.sql`

Creates the 15 `astro_*` reference tables that hold the structured grammar of Western astrology. All tables are read-only at runtime — seeded once via the next migration, never written by application code.

**Tables to create:**

#### `astro_planets`
The 10 planetary bodies plus chart points.

Columns: `id TEXT PRIMARY KEY` (e.g., 'sun', 'moon', 'mercury'), `name TEXT NOT NULL`, `glyph TEXT NOT NULL`, `type TEXT NOT NULL CHECK IN ('luminary', 'personal_planet', 'social_planet', 'transpersonal_planet')`, `archetype TEXT NOT NULL`, `function_text TEXT NOT NULL`, `is_personal BOOLEAN NOT NULL DEFAULT FALSE`, `is_social BOOLEAN NOT NULL DEFAULT FALSE`, `is_transpersonal BOOLEAN NOT NULL DEFAULT FALSE`, `avg_speed_per_day_degrees NUMERIC`, `orbit_years NUMERIC`, `discovery_year INTEGER`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `sort_order INTEGER NOT NULL`, `user_facing BOOLEAN NOT NULL DEFAULT TRUE`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_points`
Non-planetary chart points (nodes, asteroids, angles, arabic parts).

Columns: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `alternate_names TEXT[] DEFAULT '{}'`, `glyph TEXT`, `type TEXT NOT NULL CHECK IN ('lunar_node', 'centaur', 'calculated_point', 'chart_angle', 'arabic_part')`, `archetype TEXT NOT NULL`, `function_text TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `calculation_method TEXT`, `is_house_cusp INTEGER`, `always_opposite TEXT REFERENCES astro_points(id) DEFERRABLE INITIALLY DEFERRED`, `user_facing BOOLEAN NOT NULL DEFAULT TRUE`, `sort_order INTEGER NOT NULL`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_signs`
The 12 zodiac signs.

Columns: `id TEXT PRIMARY KEY` (lowercase, e.g., 'aries'), `name TEXT NOT NULL`, `glyph TEXT NOT NULL`, `symbol TEXT NOT NULL` (e.g., 'the ram'), `ordinal INTEGER NOT NULL UNIQUE CHECK BETWEEN 1 AND 12`, `element TEXT NOT NULL CHECK IN ('fire', 'earth', 'air', 'water')`, `modality TEXT NOT NULL CHECK IN ('cardinal', 'fixed', 'mutable')`, `polarity TEXT NOT NULL CHECK IN ('active', 'receptive')`, `ruler TEXT NOT NULL REFERENCES astro_planets(id)`, `traditional_ruler TEXT REFERENCES astro_planets(id)`, `approximate_dates TEXT NOT NULL`, `season_northern_hemisphere TEXT`, `archetype TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

Indexes: `idx_signs_element` on `(element)`, `idx_signs_modality` on `(modality)`, `idx_signs_ruler` on `(ruler)`.

#### `astro_dignities`
Many-to-many: which planets are strong/weak in which signs.

Columns: `id SERIAL PRIMARY KEY`, `planet_id TEXT NOT NULL REFERENCES astro_planets(id)`, `sign_id TEXT NOT NULL REFERENCES astro_signs(id)`, `dignity_type TEXT NOT NULL CHECK IN ('rulership', 'exaltation', 'detriment', 'fall', 'traditional_rulership')`, `UNIQUE (planet_id, sign_id, dignity_type)`.

Indexes: on `planet_id`, on `sign_id`, on `dignity_type`.

#### `astro_houses`
The 12 houses.

Columns: `ordinal INTEGER PRIMARY KEY CHECK BETWEEN 1 AND 12`, `name TEXT NOT NULL`, `alternate_names TEXT[] DEFAULT '{}'`, `polarity TEXT NOT NULL CHECK IN ('angular', 'succedent', 'cadent')`, `weight TEXT NOT NULL CHECK IN ('high', 'medium', 'low')`, `associated_sign TEXT NOT NULL REFERENCES astro_signs(id)`, `associated_planet TEXT NOT NULL REFERENCES astro_planets(id)`, `associated_planet_traditional TEXT REFERENCES astro_planets(id)`, `cusp_is_chart_angle TEXT`, `domain TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

Index: on `polarity`.

#### `astro_aspects`
Major and minor aspects with their default orbs.

Columns: `id TEXT PRIMARY KEY` (e.g., 'conjunction'), `name TEXT NOT NULL`, `alternate_names TEXT[] DEFAULT '{}'`, `glyph TEXT`, `degrees NUMERIC NOT NULL CHECK BETWEEN 0 AND 180`, `default_orb NUMERIC NOT NULL CHECK > 0`, `valence TEXT NOT NULL` (e.g., 'merging', 'frictional', 'flowing'), `polarity TEXT NOT NULL CHECK IN ('harmonious', 'challenging', 'neutral')`, `description TEXT NOT NULL`, `is_major BOOLEAN NOT NULL`, `synastry_orb NUMERIC`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

Index: on `is_major`.

#### `astro_elements`
The four elements.

Columns: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `archetype TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `compatible_elements TEXT[] NOT NULL DEFAULT '{}'`, `challenging_elements TEXT[] NOT NULL DEFAULT '{}'`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_modalities`
Cardinal, Fixed, Mutable.

Columns: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `archetype TEXT NOT NULL`, `function_text TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `season_marker TEXT`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_lunar_phases`
The 8 lunar phases.

Columns: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `alternate_names TEXT[] DEFAULT '{}'`, `ordinal INTEGER NOT NULL UNIQUE CHECK BETWEEN 1 AND 8`, `sun_moon_angle_min NUMERIC NOT NULL CHECK >= 0 AND < 360`, `sun_moon_angle_max NUMERIC NOT NULL CHECK > 0 AND <= 360`, `archetype TEXT NOT NULL`, `function_text TEXT NOT NULL`, `modern_keywords TEXT[] NOT NULL DEFAULT '{}'`, `CHECK (sun_moon_angle_max > sun_moon_angle_min)`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_decans`
36 decans (12 signs × 3).

Columns: `id SERIAL PRIMARY KEY`, `sign_id TEXT NOT NULL REFERENCES astro_signs(id)`, `decan_number INTEGER NOT NULL CHECK BETWEEN 1 AND 3`, `degree_start NUMERIC NOT NULL CHECK >= 0 AND < 30`, `degree_end NUMERIC NOT NULL CHECK > 0 AND <= 30`, `sub_ruler TEXT NOT NULL REFERENCES astro_planets(id)`, `flavor TEXT NOT NULL`, `UNIQUE (sign_id, decan_number)`, `CHECK (degree_end > degree_start)`.

Indexes: on `sign_id`, on `sub_ruler`.

#### `astro_house_systems`
The available house systems.

Columns: `id TEXT PRIMARY KEY`, `name TEXT NOT NULL`, `method TEXT NOT NULL`, `best_for TEXT`, `limitation TEXT`, `is_default BOOLEAN NOT NULL DEFAULT FALSE`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

Unique index: only one default allowed (`is_default = TRUE`).

#### `astro_synastry_patterns`
Patterns the AI weights when interpreting two-chart compatibility.

Columns: `id SERIAL PRIMARY KEY`, `pattern_key TEXT NOT NULL UNIQUE`, `pattern_type TEXT NOT NULL CHECK IN ('high_significance', 'challenging', 'harmonious')`, `description TEXT NOT NULL`, `weight INTEGER NOT NULL DEFAULT 1 CHECK BETWEEN 1 AND 10`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_moon_compatibility`
Element-based moon-sign compatibility heuristic.

Columns: `id SERIAL PRIMARY KEY`, `element_a TEXT NOT NULL REFERENCES astro_elements(id)`, `element_b TEXT NOT NULL REFERENCES astro_elements(id)`, `compatibility TEXT NOT NULL CHECK IN ('high', 'moderate', 'challenging')`, `description TEXT NOT NULL`, `UNIQUE (element_a, element_b)`.

Index: on `(element_a, element_b)`.

#### `astro_transit_significance`
Which transit patterns matter enough to surface to users.

Columns: `id SERIAL PRIMARY KEY`, `transit_pattern TEXT NOT NULL UNIQUE`, `significance TEXT NOT NULL CHECK IN ('highest', 'moderate', 'low')`, `description TEXT NOT NULL`, `user_alert_default BOOLEAN NOT NULL DEFAULT FALSE`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_app_settings`
Moon Rhythms-specific configuration as JSONB.

Columns: `key TEXT PRIMARY KEY`, `value JSONB NOT NULL`, `description TEXT NOT NULL`, `updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_overridable_preferences` (from user_preferences_schema)
Closed catalog of which app settings users may override.

Columns: `key TEXT PRIMARY KEY`, `label TEXT NOT NULL`, `description TEXT NOT NULL`, `valid_values JSONB NOT NULL`, `advanced_user_only BOOLEAN NOT NULL DEFAULT TRUE`, `sort_order INTEGER NOT NULL DEFAULT 100`, `created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

#### `astro_preference_changes` (from user_preferences_schema)
Append-only log of user preference changes.

Columns: `id BIGSERIAL PRIMARY KEY`, `user_id UUID NOT NULL` (FK added later when accounts table exists), `preference_key TEXT NOT NULL REFERENCES astro_overridable_preferences(key)`, `old_value JSONB`, `new_value JSONB NOT NULL`, `source TEXT NOT NULL CHECK IN ('user_action', 'admin', 'system_migration', 'rollback')`, `changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()`.

Indexes: `(user_id, changed_at DESC)`, on `preference_key`.

**Helper SQL functions to create:**

`get_effective_preference(p_user_id UUID, p_preference_key TEXT) RETURNS JSONB` — returns the user's override if set, otherwise the global default from `astro_app_settings`. Wrap the user-table lookup in BEGIN/EXCEPTION/END so the function works even before the accounts table exists.

`set_user_preference(p_user_id UUID, p_preference_key TEXT, p_new_value JSONB, p_source TEXT DEFAULT 'user_action') RETURNS BOOLEAN` — validates the new value against `astro_overridable_preferences.valid_values`, updates the accounts row, logs the change.

`reset_user_preference(p_user_id UUID, p_preference_key TEXT) RETURNS BOOLEAN` — removes the user's override.

**Views to create:**

`v_planet_dignities` — joins planets, dignities, and signs for easy querying.
`v_signs_full` — signs with their element, modality, and ruler details.
`v_houses_full` — houses with their associated sign and planet details.

**RLS:** Enable RLS on every table. Add public-read policies for all `astro_*` tables (`USING (TRUE)`). Writes are service-role only (no INSERT/UPDATE/DELETE policies for authenticated role).

### 3.2 File: `astro_deterministic_seed.sql`

Idempotent seed data for the reference tables. All inserts use `ON CONFLICT ... DO UPDATE` so the file is safe to re-run.

**Authoritative data:**

#### Elements (4 rows)
- `fire` — archetype "spark and momentum", signs: aries, leo, sagittarius, compatible: fire+air, challenging: water+earth
- `earth` — archetype "groundedness and material", signs: taurus, virgo, capricorn, compatible: earth+water, challenging: fire+air
- `air` — archetype "thought and exchange", signs: gemini, libra, aquarius, compatible: air+fire, challenging: earth+water
- `water` — archetype "feeling and depth", signs: cancer, scorpio, pisces, compatible: water+earth, challenging: fire+air

#### Modalities (3 rows)
- `cardinal` — initiator, marks start of each season, signs: aries, cancer, libra, capricorn
- `fixed` — sustainer, middle of each season, signs: taurus, leo, scorpio, aquarius
- `mutable` — adapter, end of each season, signs: gemini, virgo, sagittarius, pisces

#### Planets (10 rows)
Use these archetypes and modern keywords. Glyphs are Unicode astrological symbols.

- `sun` — glyph ☉, luminary, archetype "vital self", rules: leo, exalted: aries, detriment: aquarius, fall: libra, keywords: identity, vitality, purpose, ego, expression, leadership, self
- `moon` — glyph ☽, luminary, archetype "emotional operating system", rules: cancer, exalted: taurus, detriment: capricorn, fall: scorpio, keywords: emotion, instinct, safety, home, memory, mood, nurturing, inner life
- `mercury` — glyph ☿, personal_planet, archetype "the messenger", rules: gemini AND virgo, exalted: virgo, detriment: sagittarius AND pisces, fall: pisces
- `venus` — glyph ♀, personal_planet, archetype "the connector", rules: taurus AND libra, exalted: pisces, detriment: aries AND scorpio, fall: virgo
- `mars` — glyph ♂, personal_planet, archetype "the warrior", rules: aries, traditional ruler of: scorpio, exalted: capricorn, detriment: taurus AND libra, fall: cancer
- `jupiter` — glyph ♃, social_planet, archetype "the expander", rules: sagittarius, traditional ruler of: pisces, exalted: cancer, detriment: gemini AND virgo, fall: capricorn
- `saturn` — glyph ♄, social_planet, archetype "the structurer", rules: capricorn, traditional ruler of: aquarius, exalted: libra, detriment: cancer AND leo, fall: aries
- `uranus` — glyph ♅, transpersonal, archetype "the disruptor", rules: aquarius, discovery 1781, exalted: scorpio, detriment: leo, fall: taurus
- `neptune` — glyph ♆, transpersonal, archetype "the dissolver", rules: pisces, discovery 1846, exalted: leo, detriment: virgo, fall: aquarius
- `pluto` — glyph ♇, transpersonal, archetype "the transformer", rules: scorpio, discovery 1930, exalted: aries, detriment: taurus, fall: libra

For each planet, write a one-sentence `function_text` and 6-8 `modern_keywords` in Moon Rhythms voice (modern, grounded, no mystical language, no malefic/benefic framing). Sort order matches the list above (sun=0, moon=1, mercury=2, ... pluto=9).

#### Signs (12 rows)
Standard zodiacal data. Element + modality + polarity + ruler per the lists above. Approximate dates: aries Mar 20-Apr 19, taurus Apr 20-May 20, ... through pisces Feb 19-Mar 19. Each gets a one-word archetype (initiator, builder, messenger, nurturer, performer, analyst, harmonizer, alchemist, seeker, architect, visionary, mystic) and 6 modern keywords.

#### Houses (12 rows)
- 1 (Self): angular, high weight, sign aries, ruler mars, cusp angle ascendant, domain "self, presentation, physical body, first impressions"
- 2 (Resources): succedent, medium, taurus, venus, domain "money, possessions, values, self-worth, income"
- 3 (Mind): cadent, low, gemini, mercury, domain "communication, siblings, neighbors, short trips, daily learning"
- 4 (Home): angular, high, cancer, moon, cusp angle imum_coeli, domain "home, family, roots, foundation"
- 5 (Creation): succedent, medium, leo, sun, domain "creativity, romance, children, play, self-expression"
- 6 (Craft): cadent, low, virgo, mercury, domain "daily work, routine, health practices, service"
- 7 (Partnership): angular, high, libra, venus, cusp angle descendant, domain "partnership, marriage, contracts, projection"
- 8 (Depth): succedent, medium, scorpio, pluto (traditional: mars), domain "intimacy, shared resources, transformation, taboo"
- 9 (Horizons): cadent, low, sagittarius, jupiter, domain "philosophy, higher education, long travel, meaning"
- 10 (Vocation): angular, high, capricorn, saturn, cusp angle midheaven, domain "career, public role, reputation, authority"
- 11 (Community): succedent, medium, aquarius, uranus (traditional: saturn), domain "friends, networks, community, future hopes"
- 12 (Inner): cadent, low, pisces, neptune (traditional: jupiter), domain "unconscious, solitude, dreams, spirituality, hidden patterns"

#### Aspects (5 major + 6 minor = 11 rows)
Major (`is_major = TRUE`):
- conjunction: 0°, default orb 8, valence "merging", polarity "neutral"
- sextile: 60°, orb 6, "cooperative", "harmonious"
- square: 90°, orb 8, "frictional", "challenging"
- trine: 120°, orb 8, "flowing", "harmonious"
- opposition: 180°, orb 8, "polarizing", "challenging"

Minor (`is_major = FALSE`):
- semisextile: 30°, orb 2
- semisquare: 45°, orb 2
- quintile: 72°, orb 2
- sesquiquadrate: 135°, orb 2
- biquintile: 144°, orb 2
- quincunx: 150°, orb 3

#### Lunar phases (8 rows)
1. new_moon: 0-45°, archetype "the seed"
2. waxing_crescent: 45-90°, "the gathering"
3. first_quarter: 90-135°, "the test"
4. waxing_gibbous: 135-180°, "the refinement"
5. full_moon: 180-225°, "the revelation"
6. waning_gibbous: 225-270°, "the distribution"
7. last_quarter: 270-315°, "the reckoning"
8. waning_crescent: 315-360°, "the rest"

#### Decans (36 rows)
For each of the 12 signs, three decans (1, 2, 3) covering degree ranges 0-9.99, 10-19.99, 20-29.99. Sub-rulers follow the Chaldean order: each sign's first decan is ruled by the sign's own ruler, subsequent decans by the next planet in the same element. For example:
- aries decan 1: mars (own ruler), decan 2: sun (leo overlay), decan 3: jupiter (sagittarius overlay)
- taurus decan 1: venus, decan 2: mercury, decan 3: saturn
- cancer decan 1: moon, decan 2: pluto, decan 3: neptune (modern rulers used)

Each decan gets a one-line `flavor` description.

#### House systems (4 rows)
- placidus (`is_default = TRUE`): time-based division, modern Western default
- whole_sign: each sign occupies one full house
- koch: similar to Placidus but birthplace-specific
- equal_house: each house exactly 30° from ascendant

#### Synastry patterns (~14 rows)
High-significance patterns (weight 8): sun_moon_any_aspect, moon_moon_any_aspect, venus_mars_any_aspect, ascendant_sun_or_moon, saturn_personal_planet, node_personal_planet.

Challenging patterns (weight 5): saturn_square_or_opposite_personal_planet, mars_square_or_opposite_mars, moon_square_or_opposite_moon, pluto_aspecting_personal_planet.

Harmonious patterns (weight 5): sun_trine_or_sextile_moon, venus_trine_or_sextile_jupiter, moon_in_partners_4th_house, venus_in_partners_5th_or_7th_house.

#### Moon compatibility matrix (16 rows)
Cross-product of fire/earth/air/water elements (a × b for all combinations).
- same element pair → 'high' compatibility
- fire+air, earth+water → 'high'
- fire+water, fire+earth, air+earth, air+water → 'challenging'

Write a one-sentence description for each pair from a moon-sign-relationships perspective.

#### Transit significance (~10 rows)
Highest (alert default TRUE): outer_planet_transits_to_personal_planets, saturn_return, outer_planet_to_angles, progressed_lunar_phases.

Moderate: jupiter_returns, jupiter_to_personal_planets, saturn_to_houses.

Low: mercury_retrograde, venus_retrograde, mars_retrograde, new_and_full_moons_in_users_sign.

#### App settings (13 rows)
- `default_house_system`: "placidus"
- `default_zodiac`: "tropical"
- `default_node_calculation`: "true_node"
- `default_lilith_calculation`: "mean_apogee"
- `fallback_house_system_high_latitude`: "whole_sign"
- `use_traditional_rulerships`: false
- `preferred_aspect_orbs`: "default"
- `show_minor_aspects`: false
- `supported_planets_mvp`: ["sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus", "neptune", "pluto"]
- `supported_points_mvp`: ["ascendant", "midheaven", "descendant", "imum_coeli", "north_node", "south_node", "chiron", "black_moon_lilith"]
- `user_facing_planet_order`: same as supported_planets_mvp + ["chiron", "north_node", "south_node", "black_moon_lilith"]
- `user_facing_voice_rules`: JSON object documenting voice conventions
- `future_additions`: ["part_of_fortune", "vertex", "ceres", "pallas", "juno", "vesta"]

#### Overridable preferences (7 rows)
- `default_house_system` — label "House System", valid: ["placidus", "whole_sign", "koch", "equal_house"]
- `default_zodiac` — label "Zodiac System", valid: ["tropical", "sidereal"]
- `use_traditional_rulerships` — label "Use Traditional Rulerships", valid: [true, false]
- `default_node_calculation` — label "Lunar Node Calculation", valid: ["mean_node", "true_node"]
- `default_lilith_calculation` — label "Black Moon Lilith Calculation", valid: ["mean_apogee", "true_apogee", "natural_apogee"]
- `preferred_aspect_orbs` — label "Aspect Orb Tightness", valid: ["default", "tight", "generous"]
- `show_minor_aspects` — label "Show Minor Aspects", valid: [true, false]

All set `advanced_user_only = TRUE` for MVP. None will surface in UI yet.

### 3.3 The new user-domain schema

This is the new schema per master doc §3. Build it as ONE migration file (`new_user_domain_schema.sql`) or split across two if it's cleaner — your call.

Tables (specs already in master doc §3.2, just summarizing here so the build order is unambiguous):

- `public.accounts`
- `public.profiles` (the new one — `subject_type`, `account_id`, etc.)
- `public.birth_data`
- `public.charts`
- `public.profile_summaries`
- `public.relationships`
- `public.relationship_summaries`
- `public.subscriptions`
- The `sync_account_plan_tier()` trigger function and trigger
- All RLS policies per master doc §3.5
- Helper functions: `user_owns_profile(UUID)`, `user_owns_relationship(UUID)`, `user_owns_chat_session(UUID)`

### 3.4 The knowledge corpus schema

One migration file: `knowledge_corpus_schema.sql`.

Includes:
- `CREATE EXTENSION IF NOT EXISTS vector;`
- `public.knowledge_chunks` table per master doc §3.3
- The HNSW index on the embedding column
- The `match_knowledge_chunks` RPC function per master doc §3.3
- RLS: authenticated read, service-role write

### 3.5 Knowledge corpus seed

If the `sepharial_chunks_v1.json` file is in the repo, use it. If not, the seed of 31 chunks is post-Phase 1 work — it requires generating embeddings via OpenAI API which is outside SQL scope.

For Phase 1, **just leave the knowledge_chunks table empty.** The chunks get loaded in Phase 1D as a separate post-migration step (an edge function that reads the JSON and POSTs to OpenAI for embeddings).

Add a TODO comment in the migration file noting this.

### 3.6 The interaction domain schema

One migration file: `interaction_domain_schema.sql`.

- `public.chat_sessions` per master doc §3.4
- `public.chat_messages` per master doc §3.4
- `public.ai_responses` per master doc §3.4
- All RLS policies per §3.5
- The helper function `user_owns_chat_session(UUID)` if not already created

---

## 4. Local validation requirements

Every migration must pass these checks before being applied to the live project.

### 4.1 Schema integrity

Run after applying all schema migrations:

```sql
-- Every FK references a valid table
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE contype = 'f'
ORDER BY conrelid::regclass;

-- Every table has RLS enabled
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = FALSE;
-- Should return zero rows.

-- Every table has at least one policy
SELECT schemaname, tablename
FROM pg_tables t
WHERE schemaname = 'public'
AND NOT EXISTS (
  SELECT 1 FROM pg_policies p
  WHERE p.schemaname = t.schemaname AND p.tablename = t.tablename
);
-- Should return zero rows.
```

### 4.2 Deterministic spine seed

```sql
SELECT 'planets' AS table_name, COUNT(*) FROM astro_planets
UNION ALL SELECT 'signs', COUNT(*) FROM astro_signs
UNION ALL SELECT 'houses', COUNT(*) FROM astro_houses
UNION ALL SELECT 'aspects', COUNT(*) FROM astro_aspects
UNION ALL SELECT 'dignities', COUNT(*) FROM astro_dignities
UNION ALL SELECT 'decans', COUNT(*) FROM astro_decans
UNION ALL SELECT 'lunar_phases', COUNT(*) FROM astro_lunar_phases
UNION ALL SELECT 'elements', COUNT(*) FROM astro_elements
UNION ALL SELECT 'modalities', COUNT(*) FROM astro_modalities
UNION ALL SELECT 'house_systems', COUNT(*) FROM astro_house_systems
UNION ALL SELECT 'app_settings', COUNT(*) FROM astro_app_settings
UNION ALL SELECT 'overridable_preferences', COUNT(*) FROM astro_overridable_preferences;
```

Expected: planets=10, signs=12, houses=12, aspects=11, dignities=~46, decans=36, lunar_phases=8, elements=4, modalities=3, house_systems=4, app_settings=13, overridable_preferences=7.

### 4.3 Cross-reference integrity

```sql
-- Every sign's ruler is a valid planet
SELECT s.id, s.ruler FROM astro_signs s
LEFT JOIN astro_planets p ON p.id = s.ruler
WHERE p.id IS NULL;
-- Should return zero rows.

-- Every house's associated sign is valid
SELECT h.ordinal, h.associated_sign FROM astro_houses h
LEFT JOIN astro_signs s ON s.id = h.associated_sign
WHERE s.id IS NULL;
-- Should return zero rows.

-- Every decan's sub_ruler is a valid planet
SELECT d.sign_id, d.decan_number, d.sub_ruler FROM astro_decans d
LEFT JOIN astro_planets p ON p.id = d.sub_ruler
WHERE p.id IS NULL;
-- Should return zero rows.
```

### 4.4 User preference system

```sql
-- get_effective_preference should return defaults for any user when no override exists
SELECT get_effective_preference('00000000-0000-0000-0000-000000000000'::UUID, 'default_house_system');
-- Should return "placidus".

SELECT get_effective_preference('00000000-0000-0000-0000-000000000000'::UUID, 'default_zodiac');
-- Should return "tropical".
```

### 4.5 Backfill verification

After running Migration D (backfill):

```sql
-- The single existing user should now have:
-- - 1 accounts row
SELECT COUNT(*) FROM public.accounts;

-- - 1 self profile
SELECT COUNT(*) FROM public.profiles WHERE subject_type = 'self';

-- - 1 birth_data row
SELECT COUNT(*) FROM public.birth_data;

-- - 1 chart row (from the birth_chart reading)
SELECT COUNT(*) FROM public.charts;

-- web_readings_legacy should still have its 20 rows (untouched)
SELECT COUNT(*) FROM public.web_readings_legacy;
```

---

## 5. Operating principles for the rest of this build

These supplement the master doc. Apply throughout Phase 1.

### 5.1 Stop-and-wait gates

Beau wants to review at three gates before SQL hits production:

1. **Migration plan** (Deliverable A) + **call site catalog** (Deliverable B) → review → approve
2. **Migration SQL files** (Deliverable C) → review → approve
3. **Local validation results** (Deliverable D) → review → approve

Do NOT skip a gate even if it feels obvious.

### 5.2 Decision conservatism

When you discover something unexpected during the build (something the docs don't address), STOP and ask Beau before deciding. The audit you produced is a perfect example of this discipline — "what I am NOT proposing" was exactly the right framing. Keep it.

### 5.3 No silent fixes

If you spot a bug, typo, or inconsistency in this handoff document, the master doc, or any existing code: flag it. Don't fix it silently. Even if the fix is obvious. The fix may be wrong in context you don't have.

### 5.4 Cost discipline

This applies to YOUR Claude API usage during the build. Tool calls cost real money:

- Don't read the same file multiple times in a session.
- Don't grep the whole repo when you can target a directory.
- When verifying schemas, query Postgres metadata directly rather than re-running `\d` commands repeatedly.

### 5.5 Beau is the only human in the loop

There's no second engineer. You operate as if you're handing work to Beau for code review. Optimize for clarity in PR descriptions, commit messages, and reports. Beau will read every diff.

---

## 6. The full Phase 1 sequence (canonical reference)

This is the master sequence. Use it as your roadmap.

```
Phase 1.0 — Setup
  └─ Confirm pgvector available in Supabase project (Dashboard → Database → Extensions)

Phase 1.1 — Deterministic spine
  ├─ Migration: astro_deterministic_schema.sql
  ├─ Migration: astro_deterministic_seed.sql
  └─ Validation queries pass

Phase 1.2 — Web app preparation
  ├─ Produce CALL_SITES_TO_UPDATE.md (web repo)
  ├─ Update each call site in web code to use new schema names
  ├─ Verify web app builds locally
  └─ Wait for Beau approval before any rename

Phase 1.3 — Legacy rename
  ├─ Migration: rename_legacy_tables.sql (renames profiles → web_profiles_legacy, readings → web_readings_legacy)
  ├─ Migration: drop_legacy_handle_new_user.sql (drops the old trigger; will be replaced in Phase 1.4)

Phase 1.4 — New user domain
  ├─ Migration: new_user_domain_schema.sql (accounts, profiles, birth_data, charts, profile_summaries, relationships, relationship_summaries, subscriptions, sync_account_plan_tier trigger, all RLS)
  ├─ Migration: new_handle_new_user.sql (the rewritten auth trigger that creates accounts + self profile)
  └─ Validation: insert a test auth user, verify accounts + profiles rows created

Phase 1.5 — Knowledge corpus schema
  ├─ Migration: knowledge_corpus_schema.sql (knowledge_chunks table, match_knowledge_chunks RPC)
  └─ Table left empty — chunks loaded in Phase 1.7

Phase 1.6 — Interaction domain
  ├─ Migration: interaction_domain_schema.sql (chat_sessions, chat_messages, ai_responses, helper functions, RLS)

Phase 1.7 — Backfill + cleanup
  ├─ Migration: backfill_legacy_data.sql (one-shot script that creates accounts, profiles, birth_data, charts rows from the legacy tables)
  ├─ Validation: existing user data appears in new schema
  ├─ Migration: drop_web_legacy_tables.sql (drops web_profiles_legacy and web_readings_legacy after verification)
  └─ Final validation pass

Phase 1.8 — Knowledge corpus seed (optional in Phase 1)
  └─ Edge function or script that reads sepharial_chunks_v1.json, generates embeddings via OpenAI, INSERTs into knowledge_chunks
```

End of Phase 1. Mobile app integration (Phase 2 of master doc) begins after this.

---

## 7. Where things live

For unambiguous reference:

- Mobile repo: `/Users/beausterling/Projects/moon-rhythms-mobile`
- Web repo: `/Users/beausterling/Projects/moon-rhythms`
- Supabase project ID: `worbycfxsaeqwzlckvah`
- Master architecture doc: `moon-rhythms-mobile/docs/supabase_master_doc.md`
- Audit: `moon-rhythms-mobile/docs/CURRENT_SUPABASE_STATE.md`
- This handoff: `moon-rhythms-mobile/docs/PHASE_1_HANDOFF.md`
- Migrations directory: `moon-rhythms-mobile/supabase/migrations/`
- Archive directory (move old mobile migration here): `moon-rhythms-mobile/supabase/migrations/_archive/`
- Migration plan to produce: `moon-rhythms-mobile/docs/PHASE_1_MIGRATION_PLAN.md`
- Call site catalog to produce: `moon-rhythms/docs/CALL_SITES_TO_UPDATE.md`

---

## 8. Begin

Start with Deliverable A (the migration plan) and Deliverable B (the call site catalog), per Section 2. Stop when both are produced and report back.

End of handoff.
