-- ============================================================================
-- Moon Rhythms — Deterministic Chinese Zodiac / BaZi Reference Schema
-- ============================================================================
--
-- Purpose: Postgres/Supabase schema for the deterministic Chinese astrology
-- (Sheng Xiao + BaZi / 八字) reference data. This is the CHINESE ZODIAC SPINE
-- of Moon Rhythms — every four-pillars calculation, every AI prompt assembly,
-- and every RAG chunk that touches Chinese astrology references these tables.
--
-- Created: 2026-06-23
-- Source JSON: moon_rhythms_build_bundle/systems/chinese_zodiac_data.json
--
-- Mirrors the Western astrology spine (deterministic_schema.sql). Where the
-- astrology spine uses the `astro_` prefix, this uses `cz_` (Chinese Zodiac).
--
-- This schema is for STRUCTURED LOOKUP data only. Interpretive content goes in
-- the separate `knowledge_chunks` table with pgvector embeddings.
--
-- All tables are READ-ONLY for the application. They're seeded once from
-- chinese_zodiac_data.json and never updated by user actions. RLS allows SELECT
-- for `authenticated`, ALL for `service_role`.
--
-- UTF-8 note: every column holding Chinese characters is TEXT. The companion
-- seed file writes those characters literally (not escaped).
-- ============================================================================

-- ============================================================================
-- FIVE ELEMENTS (Wu Xing / 五行)
-- ============================================================================

CREATE TABLE cz_five_elements (
    id              TEXT PRIMARY KEY,           -- 'wood','fire','earth','metal','water'
    name            TEXT NOT NULL,
    chinese         TEXT NOT NULL,              -- 木 火 土 金 水
    pinyin          TEXT NOT NULL,
    color           TEXT NOT NULL,              -- hex, app's exact value
    season          TEXT NOT NULL,
    direction       TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_five_elements IS 'The five Wu Xing elements underlying stems, branches, animals, and NaYin. Read-only seed data.';

-- ============================================================================
-- FIVE-ELEMENT CYCLES (the 4 directed Wu Xing interaction cycles)
-- ============================================================================
-- The four standard directed cycles as explicit from->to pairs.
-- cycle: 'generating_sheng' (生), 'controlling_ke' (克), 'weakening_xie' (泄),
--        'insulting_wu' (侮). Note: 乘 (Cheng / over-acting) shares the exact
--        controlling_ke pairs and is NOT stored separately (see seed note).

CREATE TABLE cz_element_cycles (
    id              SERIAL PRIMARY KEY,
    cycle           TEXT NOT NULL CHECK (cycle IN ('generating_sheng', 'controlling_ke', 'weakening_xie', 'insulting_wu')),
    cycle_chinese   TEXT NOT NULL,              -- 生 / 克 / 泄 / 侮
    cycle_meaning   TEXT NOT NULL,
    from_element    TEXT NOT NULL REFERENCES cz_five_elements(id),
    to_element      TEXT NOT NULL REFERENCES cz_five_elements(id),
    note            TEXT NOT NULL,

    UNIQUE (cycle, from_element, to_element)
);

CREATE INDEX idx_cz_element_cycles_cycle ON cz_element_cycles(cycle);
CREATE INDEX idx_cz_element_cycles_from ON cz_element_cycles(from_element);

COMMENT ON TABLE cz_element_cycles IS 'The 4 directed Wu Xing cycles (Sheng/Ke/Xie/Wu) as from->to pairs. 5 pairs each = 20 rows.';

-- ============================================================================
-- HEAVENLY STEMS (Tian Gan / 天干) — 10
-- ============================================================================

CREATE TABLE cz_heavenly_stems (
    chinese         TEXT PRIMARY KEY,           -- 甲 乙 丙 ...
    ordinal         INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 10),
    pinyin          TEXT NOT NULL,
    element         TEXT NOT NULL REFERENCES cz_five_elements(id),
    polarity        TEXT NOT NULL CHECK (polarity IN ('Yang', 'Yin')),
    imagery         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_heavenly_stems IS 'The 10 Heavenly Stems in canonical order. element is the lowercase cz_five_elements id.';

-- ============================================================================
-- EARTHLY BRANCHES (Di Zhi / 地支) — 12
-- ============================================================================
-- hidden_stems (cangan / 藏干) are irregular (1-3 per branch) so stored as JSONB.
-- month_start_solar_term is a small nested object, also JSONB.

CREATE TABLE cz_earthly_branches (
    chinese                 TEXT PRIMARY KEY,   -- 子 丑 寅 ...
    ordinal                 INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 12),
    pinyin                  TEXT NOT NULL,
    animal                  TEXT NOT NULL,      -- English animal name
    fixed_element           TEXT NOT NULL REFERENCES cz_five_elements(id),
    polarity                TEXT NOT NULL CHECK (polarity IN ('Yang', 'Yin')),
    hidden_stems            JSONB NOT NULL,     -- [{stem,pinyin,qi,element,polarity}, ...]
    shichen                 TEXT NOT NULL,      -- e.g. '23:00-01:00'
    lunar_month             INTEGER NOT NULL CHECK (lunar_month BETWEEN 1 AND 12),
    month_start_solar_term  JSONB NOT NULL,     -- {name,chinese,approx_date}

    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cz_branches_animal ON cz_earthly_branches(animal);

COMMENT ON TABLE cz_earthly_branches IS 'The 12 Earthly Branches. hidden_stems (1-3 each) and month_start_solar_term stored as JSONB; fixed_element is the lowercase element id.';

-- ============================================================================
-- ANIMALS (the 12 zodiac animals / Sheng Xiao)
-- ============================================================================
-- emoji preserved verbatim from the app (the only place an emoji appears; it is
-- a stored data value the app uses, never rendered into prose). traits, lucky
-- numbers/colors, and loose compatibility are the app's verbatim strings.

CREATE TABLE cz_animals (
    name                TEXT PRIMARY KEY,       -- 'Rat','Ox',...
    ordinal             INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 12),
    chinese             TEXT NOT NULL,          -- 鼠 牛 虎 ...
    emoji               TEXT NOT NULL,          -- app's exact emoji value
    branch              TEXT NOT NULL REFERENCES cz_earthly_branches(chinese),
    fixed_element       TEXT NOT NULL REFERENCES cz_five_elements(id),
    traits              TEXT NOT NULL,
    lucky_numbers       TEXT NOT NULL,          -- app's string, e.g. '2, 3'
    lucky_colors        TEXT NOT NULL,
    compatible_loose    TEXT NOT NULL,          -- popular-astrology approximation
    incompatible_loose  TEXT NOT NULL,          -- popular-astrology approximation

    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cz_animals_branch ON cz_animals(branch);

COMMENT ON TABLE cz_animals IS 'The 12 zodiac animals. compatible_loose/incompatible_loose are popular approximations kept for UI back-compat; prefer cz_compatibility for rigorous logic.';

-- ============================================================================
-- SIXTY CYCLE (Jiazi / 六十甲子) — 60 entries, one row per position
-- ============================================================================

CREATE TABLE cz_sixty_cycle (
    position        INTEGER PRIMARY KEY CHECK (position BETWEEN 1 AND 60),
    index0          INTEGER NOT NULL UNIQUE CHECK (index0 BETWEEN 0 AND 59),
    ganzhi          TEXT NOT NULL UNIQUE,       -- 甲子 ...
    stem            TEXT NOT NULL REFERENCES cz_heavenly_stems(chinese),
    stem_pinyin     TEXT NOT NULL,
    branch          TEXT NOT NULL REFERENCES cz_earthly_branches(chinese),
    branch_pinyin   TEXT NOT NULL,
    animal          TEXT NOT NULL REFERENCES cz_animals(name),
    stem_element    TEXT NOT NULL REFERENCES cz_five_elements(id),
    polarity        TEXT NOT NULL CHECK (polarity IN ('Yang', 'Yin')),
    nayin_chinese   TEXT NOT NULL,              -- 海中金 ...
    nayin_english   TEXT NOT NULL,              -- app's verbatim English name
    nayin_element   TEXT NOT NULL REFERENCES cz_five_elements(id),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cz_sixty_animal ON cz_sixty_cycle(animal);
CREATE INDEX idx_cz_sixty_nayin ON cz_sixty_cycle(nayin_chinese);

COMMENT ON TABLE cz_sixty_cycle IS 'The full 60-position sexagenary cycle. Anchor: position 1 / index0 0 = 甲子 = Wood Rat = year 1984. (year-4) mod 60 = index0.';

-- ============================================================================
-- NAYIN (纳音) — 30 melodic five-element phases
-- ============================================================================
-- Each NaYin spans 2 consecutive 60-cycle positions, so 30 entries cover 60.
-- cycle_positions (int[2]) and ganzhi_pair (text[2]) are small fixed arrays.

CREATE TABLE cz_nayin (
    ordinal         INTEGER PRIMARY KEY CHECK (ordinal BETWEEN 1 AND 30),
    chinese         TEXT NOT NULL UNIQUE,       -- 海中金 ...
    english         TEXT NOT NULL,              -- app's verbatim English (no new names invented)
    element         TEXT NOT NULL REFERENCES cz_five_elements(id),
    cycle_positions INTEGER[] NOT NULL,         -- two consecutive positions, e.g. {1,2}
    ganzhi_pair     TEXT[] NOT NULL,            -- two ganzhi, e.g. {甲子,乙丑}

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_nayin IS '30 NaYin melodic phases. Each spans 2 cycle positions. English names taken verbatim from the app; none invented.';

-- ============================================================================
-- YEAR BOUNDARY RULES (Lunar New Year vs Li Chun)
-- ============================================================================
-- The two competing year boundaries, plus the Gregorian->cycle formula and a
-- flag marking which rule the app currently uses. detail JSONB carries the
-- full nested structure for each rule.

CREATE TABLE cz_year_boundary_rules (
    id              TEXT PRIMARY KEY,           -- 'popular_zodiac_year' | 'formal_bazi_year_pillar' | 'gregorian_to_cycle_formula'
    label           TEXT NOT NULL,
    boundary        TEXT,                       -- human description of the boundary (null for the formula row)
    applies_to      TEXT,                       -- what this boundary governs
    note            TEXT,                       -- extra caveats
    used_by_app     BOOLEAN NOT NULL DEFAULT FALSE,  -- TRUE for the rule the app currently follows
    detail          JSONB NOT NULL DEFAULT '{}'::JSONB,  -- full nested structure / formula

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_year_boundary_rules IS 'Lunar-New-Year vs Li-Chun year boundaries + the Gregorian->cycle formula. used_by_app=TRUE marks the popular Lunar-New-Year rule the app currently follows.';

-- ============================================================================
-- COMPATIBILITY (San He / Liu He / Liu Chong / Liu Hai / Xing / San Hui)
-- ============================================================================
-- Each compatibility SYSTEM is one row in cz_compatibility_systems; each
-- concrete group/pair/trio is one row in cz_compatibility_groups. Branches,
-- animals, and the variable extra attributes (produces_element, transforms_to,
-- direction/season, punishment type, notes) are stored per-group. Branch and
-- animal lists are arrays; the irregular extra attributes go in JSONB.

CREATE TABLE cz_compatibility_systems (
    id              TEXT PRIMARY KEY,           -- 'san_he','liu_he','liu_chong','liu_hai','xing','san_hui'
    name            TEXT NOT NULL,
    chinese         TEXT NOT NULL,              -- 三合 六合 ...
    label           TEXT NOT NULL,
    description     TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_compatibility_systems IS 'The 6 canonical branch-based compatibility systems. Prefer these over the loose per-animal strings.';

CREATE TABLE cz_compatibility_groups (
    id              SERIAL PRIMARY KEY,
    system_id       TEXT NOT NULL REFERENCES cz_compatibility_systems(id),
    branches        TEXT[] NOT NULL,            -- the branches in this group/pair/trio
    animals         TEXT[] NOT NULL,            -- the matching animal names
    attributes      JSONB NOT NULL DEFAULT '{}'::JSONB,  -- produces_element, transforms_to, direction, season, type, note, etc.

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_cz_compat_groups_system ON cz_compatibility_groups(system_id);

COMMENT ON TABLE cz_compatibility_groups IS 'Concrete groups/pairs/trios per system. Variable attributes (produces_element, transforms_to, direction, season, punishment type, notes) live in JSONB.';

-- ============================================================================
-- FOUR PILLARS (BaZi / 四柱)
-- ============================================================================
-- The 4 pillars + the inner/secret/true popular framing. Variable fields per
-- pillar (public_animal, inner_animal, day_master, secret_animal) go in JSONB.

CREATE TABLE cz_four_pillars (
    id              TEXT PRIMARY KEY,           -- 'year','month','day','time'
    ordinal         INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 4),
    chinese         TEXT NOT NULL,              -- 年柱 月柱 日柱 时柱
    derived_from    TEXT NOT NULL,
    represents      TEXT NOT NULL,
    role            JSONB NOT NULL DEFAULT '{}'::JSONB,  -- public_animal / inner_animal / day_master / secret_animal text

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_four_pillars IS 'The 4 BaZi pillars. role JSONB holds each pillar''s special framing (public/inner/secret animal, day master).';

CREATE TABLE cz_four_pillars_framing (
    key             TEXT PRIMARY KEY,           -- 'true_animal','inner_animal','secret_animal','day_master','_note'
    value           TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_four_pillars_framing IS 'The popular inner/secret/true-animal + day-master framing layered on the four pillars.';

-- ============================================================================
-- SHICHEN (時辰) — 12 two-hour periods
-- ============================================================================

CREATE TABLE cz_shichen (
    branch          TEXT PRIMARY KEY REFERENCES cz_earthly_branches(chinese),
    ordinal         INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 12),
    animal          TEXT NOT NULL REFERENCES cz_animals(name),
    hours           TEXT NOT NULL,              -- '23:00-01:00'

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE cz_shichen IS 'The 12 shichen two-hour periods of the traditional day, each keyed to an Earthly Branch and its animal.';

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================
-- Reference data: readable by authenticated users, writable only by service_role
-- (migrations / seed). Mirrors the astrology spine idiom.

ALTER TABLE cz_five_elements          ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_element_cycles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_heavenly_stems         ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_earthly_branches       ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_animals                ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_sixty_cycle            ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_nayin                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_year_boundary_rules    ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_compatibility_systems  ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_compatibility_groups   ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_four_pillars           ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_four_pillars_framing   ENABLE ROW LEVEL SECURITY;
ALTER TABLE cz_shichen                ENABLE ROW LEVEL SECURITY;

-- authenticated SELECT
CREATE POLICY "Authenticated read cz_five_elements"         ON cz_five_elements         FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_element_cycles"        ON cz_element_cycles        FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_heavenly_stems"        ON cz_heavenly_stems        FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_earthly_branches"      ON cz_earthly_branches      FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_animals"               ON cz_animals               FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_sixty_cycle"           ON cz_sixty_cycle           FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_nayin"                 ON cz_nayin                 FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_year_boundary_rules"   ON cz_year_boundary_rules   FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_compatibility_systems" ON cz_compatibility_systems FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_compatibility_groups"  ON cz_compatibility_groups  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_four_pillars"          ON cz_four_pillars          FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_four_pillars_framing"  ON cz_four_pillars_framing  FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read cz_shichen"               ON cz_shichen               FOR SELECT TO authenticated USING (true);

-- service_role ALL (seed / migrations)
CREATE POLICY "Service role all cz_five_elements"         ON cz_five_elements         FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_element_cycles"        ON cz_element_cycles        FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_heavenly_stems"        ON cz_heavenly_stems        FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_earthly_branches"      ON cz_earthly_branches      FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_animals"               ON cz_animals               FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_sixty_cycle"           ON cz_sixty_cycle           FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_nayin"                 ON cz_nayin                 FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_year_boundary_rules"   ON cz_year_boundary_rules   FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_compatibility_systems" ON cz_compatibility_systems FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_compatibility_groups"  ON cz_compatibility_groups  FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_four_pillars"          ON cz_four_pillars          FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_four_pillars_framing"  ON cz_four_pillars_framing  FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role all cz_shichen"               ON cz_shichen               FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- END SCHEMA
-- ============================================================================
-- Next steps:
-- 1. Run this migration on your Supabase project.
-- 2. Run chinese_zodiac_seed.sql (UTF-8) to load data from
--    chinese_zodiac_data.json. Idempotent (ON CONFLICT upserts).
-- 3. Reference these tables in edge functions when assembling Chinese-zodiac /
--    BaZi AI prompts or running four-pillars calculations.
-- ============================================================================
