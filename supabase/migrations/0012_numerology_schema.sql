-- ============================================================================
-- Moon Rhythms — Deterministic Numerology Reference Schema
-- ============================================================================
--
-- Purpose: Postgres/Supabase schema for the deterministic numerology reference
-- data. This is the numerology SPINE of Moon Rhythms — every numerology
-- calculation, every AI prompt assembly, and every RAG chunk references these
-- tables. It is the structural parallel to the astrology spine in
-- deterministic_schema.sql (astro_* tables); here every table is prefixed num_.
--
-- This schema is for STRUCTURED LOOKUP and exact computation reproducibility
-- only. Interpretive long-form prose belongs in the separate knowledge_chunks
-- RAG corpus with pgvector embeddings, NOT here.
--
-- All tables are READ-ONLY for the application. They're seeded once from
-- numerology_data.json (numerology_seed.sql) and never updated by user actions.
--
-- Generated: 2026-06-23
-- Source JSON: moon_rhythms_build_bundle/systems/numerology_data.json
-- Tested against Postgres 16.
--
-- Naming convention: prefix all tables with `num_` to namespace them clearly
-- and parallel the astrology `astro_` set.
-- ============================================================================

-- ============================================================================
-- SYSTEMS (letter-to-number alphabets: Pythagorean default + Chaldean alternate)
-- ============================================================================

CREATE TABLE num_systems (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    is_app_default  BOOLEAN NOT NULL DEFAULT FALSE,
    reference_only  BOOLEAN NOT NULL DEFAULT FALSE,
    value_range     TEXT NOT NULL,
    note            TEXT,
    -- letter_values: { "a": 1, ... } and value_to_letters: { "1": ["a","j","s"], ... }
    -- kept as JSONB (the app reads the maps wholesale); the normalized split lives
    -- in num_letter_values below for relational queries.
    letter_values   JSONB NOT NULL,
    value_to_letters JSONB NOT NULL,
    -- system-specific extras (nine_rule, known_variants) — irregular per system
    extra           JSONB NOT NULL DEFAULT '{}'::JSONB,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one app-default system
CREATE UNIQUE INDEX idx_num_systems_one_default
    ON num_systems(is_app_default) WHERE is_app_default = TRUE;

COMMENT ON TABLE num_systems IS 'The two numerology alphabets. Pythagorean is the app default and basis of every computed number; Chaldean is reference-only.';

-- ============================================================================
-- LETTER VALUES (normalized one row per system + letter)
-- ============================================================================

CREATE TABLE num_letter_values (
    system_id       TEXT NOT NULL REFERENCES num_systems(id),
    letter          TEXT NOT NULL CHECK (char_length(letter) = 1),
    value           INTEGER NOT NULL CHECK (value BETWEEN 1 AND 9),

    PRIMARY KEY (system_id, letter)
);

CREATE INDEX idx_num_letter_values_system ON num_letter_values(system_id);
CREATE INDEX idx_num_letter_values_value ON num_letter_values(value);

COMMENT ON TABLE num_letter_values IS 'Relational letter-to-value map. Pythagorean covers a-z (1-9); Chaldean omits any letter for value 9 (9 is held sacred).';

-- ============================================================================
-- VOWEL / CONSONANT RULES
-- ============================================================================

CREATE TABLE num_vowel_consonant_rules (
    id              TEXT PRIMARY KEY,
    vowels          TEXT[] NOT NULL DEFAULT '{}',
    y_is_vowel      BOOLEAN NOT NULL,
    w_is_vowel      BOOLEAN NOT NULL,
    -- app_convention is the reproducible rule the engine ships; the
    -- standard_phonetic_rule documents the more accurate convention for a future
    -- upgrade. Both are nested/irregular so stored as JSONB.
    app_convention  JSONB NOT NULL,
    standard_phonetic_rule JSONB NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_vowel_consonant_rules IS 'Vowel/consonant split rules. The app uses {a,e,i,o,u} only (Y and W always consonant); the standard phonetic rule is documented as JSONB for any future upgrade.';

-- ============================================================================
-- REDUCTION RULES
-- ============================================================================

CREATE TABLE num_reduction_rules (
    id              TEXT PRIMARY KEY,
    app_function    TEXT NOT NULL,
    rule            TEXT NOT NULL,
    used_for        TEXT[] NOT NULL DEFAULT '{}',
    preserves_masters BOOLEAN NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_reduction_rules IS 'How multi-digit sums collapse. reduceToSingle preserves masters 11/22/33; reduceStrict does not. Master numbers themselves live in num_meta and the rule rows.';

-- ============================================================================
-- CORE NUMBERS (Life Path, Expression, Soul Urge, Personality, Birthday, Maturity)
-- ============================================================================

CREATE TABLE num_core_numbers (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    alternate_names TEXT[] NOT NULL DEFAULT '{}',
    inputs          TEXT[] NOT NULL DEFAULT '{}',
    formula         TEXT NOT NULL,
    app_implementation TEXT NOT NULL,
    reduction_mode  TEXT NOT NULL,
    can_carry_karmic_debt BOOLEAN NOT NULL DEFAULT FALSE,
    meaning_context TEXT,
    note            TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_core_numbers IS 'The primary numbers computed from name and/or birthdate, each with the exact app formula and reduction mode for reproducibility.';

-- ============================================================================
-- PERSONAL CYCLES (Personal Year shipped; Personal Month / Day added by research)
-- ============================================================================

CREATE TABLE num_personal_cycles (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    added_by_research BOOLEAN NOT NULL DEFAULT FALSE,
    inputs          TEXT[] NOT NULL DEFAULT '{}',
    formula         TEXT NOT NULL,
    app_implementation TEXT,
    example         TEXT,
    output_range    TEXT,
    reduction_mode  TEXT,
    meaning_context TEXT,
    note            TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_personal_cycles IS 'Time-based cycles. Personal Year is shipped by the app; Personal Month and Day are the standard extensions (added_by_research = true).';

-- ============================================================================
-- PINNACLES (single config row; formulas + timing are irregular -> JSONB)
-- ============================================================================

CREATE TABLE num_pinnacles (
    id              TEXT PRIMARY KEY,
    formulas        JSONB NOT NULL,
    component_reduction TEXT NOT NULL,
    master_numbers_preserved BOOLEAN NOT NULL,
    timing          JSONB NOT NULL,
    meaning_context TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_pinnacles IS 'The four Pinnacle cycles. Formulas and 36-minus-life-path timing match the app exactly; meanings live in num_meaning_simple under context pinnacle.';

-- ============================================================================
-- CHALLENGES (single config row)
-- ============================================================================

CREATE TABLE num_challenges (
    id              TEXT PRIMARY KEY,
    formulas        JSONB NOT NULL,
    labels          JSONB NOT NULL,
    component_reduction TEXT NOT NULL,
    master_numbers_preserved BOOLEAN NOT NULL,
    output_range    TEXT NOT NULL,
    timing_note     TEXT,
    meaning_context TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_challenges IS 'The four Challenge numbers. Always reduce to a single digit 0-8 (masters NOT preserved); meanings in num_meaning_simple under context challenge.';

-- ============================================================================
-- LIFE CYCLES (single config row; BOTH timing conventions preserved)
-- ============================================================================

CREATE TABLE num_life_cycles (
    id              TEXT PRIMARY KEY,
    formulas        JSONB NOT NULL,
    labels          JSONB NOT NULL,
    themes          JSONB NOT NULL,
    master_numbers_preserved BOOLEAN NOT NULL,
    -- Divergence preserved: the reproducible app timing AND the canonical Decoz
    -- timing are both stored. The app conflates the pinnacle boundary; Decoz
    -- ties Period-Cycle 1 to the Personal-Year wheel. Do not drop either.
    app_engine_timing JSONB NOT NULL,
    canonical_decoz_timing JSONB NOT NULL,
    meaning_context TEXT NOT NULL,
    meaning_note    TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_life_cycles IS 'The three Period (Life) Cycles. Stores both app_engine_timing (reproducible) and canonical_decoz_timing (documented divergence) per the JSON design decision.';

-- ============================================================================
-- KARMIC DEBT (13, 14, 16, 19 detected on pre-reduction totals)
-- ============================================================================

CREATE TABLE num_karmic_debt (
    number          INTEGER PRIMARY KEY CHECK (number IN (13, 14, 16, 19)),
    reduces_to      INTEGER NOT NULL CHECK (reduces_to BETWEEN 1 AND 9),
    theme           TEXT NOT NULL,
    descriptor      TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_karmic_debt IS 'Karmic Debt numbers. Present when a core number pre-reduction total is 13/14/16/19. Framing reworded into present-tense growth themes.';

-- ============================================================================
-- KARMIC LESSONS (numbers 1-9 absent from the name)
-- ============================================================================

CREATE TABLE num_karmic_lessons (
    number          INTEGER PRIMARY KEY CHECK (number BETWEEN 1 AND 9),
    meaning         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_karmic_lessons IS 'A Karmic Lesson is a Pythagorean value 1-9 that never appears among the full-birth-name letters: an undeveloped quality to grow into.';

-- ============================================================================
-- HIDDEN PASSION / INTENSITY (most-frequent value in the name)
-- ============================================================================

CREATE TABLE num_hidden_passion (
    number          INTEGER PRIMARY KEY CHECK (number BETWEEN 1 AND 9),
    meaning         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_hidden_passion IS 'The Hidden Passion (Intensity) number: the Pythagorean value appearing most often in the name, a concentrated repeated strength.';

-- ============================================================================
-- BRIDGE NUMBERS (types + per-value meanings)
-- ============================================================================

CREATE TABLE num_bridge_types (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    computation     TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_bridge_types IS 'The two Bridge number types (Life Path-to-Expression, Soul Urge-to-Personality) and how each is computed.';

CREATE TABLE num_bridge_meanings (
    number          INTEGER PRIMARY KEY CHECK (number BETWEEN 0 AND 8),
    meaning         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_bridge_meanings IS 'Per-value (0-8) guidance for closing the gap a Bridge number measures.';

-- ============================================================================
-- ESSENCE / TRANSIT (single config row; nested method -> JSONB)
-- ============================================================================

CREATE TABLE num_essence_transit (
    id              TEXT PRIMARY KEY,
    transit_letters JSONB NOT NULL,
    essence         JSONB NOT NULL,
    confidence_note TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_essence_transit IS 'Name-based annual cycle method (transit letters + Essence). Documented, not computed by the app; carries a confidence note for moderately-sourced edge cases.';

-- ============================================================================
-- MEANING TABLE: core (general number essence)
-- ============================================================================

CREATE TABLE num_meaning_core (
    number          TEXT PRIMARY KEY,  -- '1'..'9','11','22','33'
    title           TEXT NOT NULL,
    keywords        TEXT[] NOT NULL DEFAULT '{}',
    essence         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_meaning_core IS 'Context-independent essence of each number (1-9, 11, 22, 33). Fallback and reuse for Maturity / Period-Cycle / Personal-Month.';

-- ============================================================================
-- MEANING TABLE: life_path (title + description)
-- ============================================================================

CREATE TABLE num_meaning_life_path (
    number          TEXT PRIMARY KEY,  -- '1'..'9','11','22','33'
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_meaning_life_path IS 'Life Path life-purpose meanings (title + description), preserved verbatim from the app.';

-- ============================================================================
-- MEANING TABLE: birthday (day-of-month 1-31)
-- ============================================================================

CREATE TABLE num_meaning_birthday (
    day             INTEGER PRIMARY KEY CHECK (day BETWEEN 1 AND 31),
    title           TEXT NOT NULL,
    description     TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_meaning_birthday IS 'Day-of-month talent table for the un-reduced Birthday Number, days 1-31.';

-- ============================================================================
-- MEANING TABLES: simple string contexts
-- (expression, soul_urge, personality, maturity, personal_year, pinnacle, challenge)
-- ============================================================================
-- These contexts each map a number to a single descriptor string. Rather than a
-- table per context, one tall table keyed by (context, number). number is TEXT
-- so it covers single digits, masters ('11','22','33'), and challenge '0'.

CREATE TABLE num_meaning_simple (
    context         TEXT NOT NULL CHECK (context IN (
                        'expression', 'soul_urge', 'personality', 'maturity',
                        'personal_year', 'pinnacle', 'challenge')),
    number          TEXT NOT NULL,
    meaning         TEXT NOT NULL,

    PRIMARY KEY (context, number)
);

CREATE INDEX idx_num_meaning_simple_context ON num_meaning_simple(context);

COMMENT ON TABLE num_meaning_simple IS 'Single-string meaning tables keyed by (context, number). Covers expression/soul_urge/personality/maturity/personal_year/pinnacle/challenge, including masters and challenge 0.';

-- ============================================================================
-- COMPATIBILITY MATRIX (INTERPRETIVE, NON-DETERMINISTIC)
-- ============================================================================

CREATE TABLE num_compatibility (
    life_path       INTEGER PRIMARY KEY CHECK (life_path BETWEEN 1 AND 9),
    most_compatible INTEGER[] NOT NULL DEFAULT '{}',
    challenging     INTEGER[] NOT NULL DEFAULT '{}',
    is_deterministic BOOLEAN NOT NULL DEFAULT FALSE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_compatibility IS 'Life Path compatibility heuristic. INTERPRETIVE and asymmetric (is_deterministic = false). Master Life Paths reduced for lookup (see num_compatibility_meta).';

CREATE TABLE num_compatibility_meta (
    id              TEXT PRIMARY KEY,
    is_deterministic BOOLEAN NOT NULL,
    master_reduction_for_lookup JSONB NOT NULL,
    commonly_cited_harmonious_pairs JSONB NOT NULL,
    note            TEXT,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_compatibility_meta IS 'Compatibility lookup metadata: master reduction map (11->2, 22->4, 33->6), commonly cited harmonious pairs, and the non-deterministic flag.';

-- ============================================================================
-- METADATA / DESIGN DECISIONS (provenance; irregular -> JSONB key/value)
-- ============================================================================

CREATE TABLE num_meta (
    key             TEXT PRIMARY KEY,
    value           JSONB NOT NULL,

    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE num_meta IS 'Provenance and engine-convention notes from the source JSON metadata (master numbers, divergence flags, voice rules, sources).';

-- ============================================================================
-- VIEWS — common queries the AI/app will run
-- ============================================================================

-- "Full meaning of a number across every simple context" — used by the assembler
CREATE VIEW v_num_meanings_by_number AS
SELECT
    number,
    context,
    meaning
FROM num_meaning_simple
ORDER BY number, context;

-- "Pythagorean letter map as relational rows" — quick value lookup
CREATE VIEW v_num_pythagorean_letters AS
SELECT letter, value
FROM num_letter_values
WHERE system_id = 'pythagorean'
ORDER BY letter;

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================
-- Reference data: readable by all authenticated users, writable only by the
-- service role (migrations / seed). Mirrors the astrology spine's public-read
-- idiom and adds an explicit service_role ALL policy per table.

ALTER TABLE num_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_letter_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_vowel_consonant_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_reduction_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_core_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_personal_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_pinnacles ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_life_cycles ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_karmic_debt ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_karmic_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_hidden_passion ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_bridge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_bridge_meanings ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_essence_transit ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_meaning_core ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_meaning_life_path ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_meaning_birthday ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_meaning_simple ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_compatibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_compatibility_meta ENABLE ROW LEVEL SECURITY;
ALTER TABLE num_meta ENABLE ROW LEVEL SECURITY;

-- Read access for all authenticated users
CREATE POLICY "Public read num_systems" ON num_systems FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_letter_values" ON num_letter_values FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_vowel_consonant_rules" ON num_vowel_consonant_rules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_reduction_rules" ON num_reduction_rules FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_core_numbers" ON num_core_numbers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_personal_cycles" ON num_personal_cycles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_pinnacles" ON num_pinnacles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_challenges" ON num_challenges FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_life_cycles" ON num_life_cycles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_karmic_debt" ON num_karmic_debt FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_karmic_lessons" ON num_karmic_lessons FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_hidden_passion" ON num_hidden_passion FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_bridge_types" ON num_bridge_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_bridge_meanings" ON num_bridge_meanings FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_essence_transit" ON num_essence_transit FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_meaning_core" ON num_meaning_core FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_meaning_life_path" ON num_meaning_life_path FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_meaning_birthday" ON num_meaning_birthday FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_meaning_simple" ON num_meaning_simple FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_compatibility" ON num_compatibility FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_compatibility_meta" ON num_compatibility_meta FOR SELECT TO authenticated USING (true);
CREATE POLICY "Public read num_meta" ON num_meta FOR SELECT TO authenticated USING (true);

-- Full write access for the service role (migrations / seed only)
CREATE POLICY "Service manage num_systems" ON num_systems FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_letter_values" ON num_letter_values FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_vowel_consonant_rules" ON num_vowel_consonant_rules FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_reduction_rules" ON num_reduction_rules FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_core_numbers" ON num_core_numbers FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_personal_cycles" ON num_personal_cycles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_pinnacles" ON num_pinnacles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_challenges" ON num_challenges FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_life_cycles" ON num_life_cycles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_karmic_debt" ON num_karmic_debt FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_karmic_lessons" ON num_karmic_lessons FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_hidden_passion" ON num_hidden_passion FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_bridge_types" ON num_bridge_types FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_bridge_meanings" ON num_bridge_meanings FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_essence_transit" ON num_essence_transit FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_meaning_core" ON num_meaning_core FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_meaning_life_path" ON num_meaning_life_path FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_meaning_birthday" ON num_meaning_birthday FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_meaning_simple" ON num_meaning_simple FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_compatibility" ON num_compatibility FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_compatibility_meta" ON num_compatibility_meta FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service manage num_meta" ON num_meta FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- END SCHEMA
-- ============================================================================
-- Next steps:
-- 1. Run this migration on your Supabase project
-- 2. Run numerology_seed.sql to load data from numerology_data.json
-- 3. Reference these tables in edge functions when assembling AI prompts or
--    running numerology calculations (lib/numerology.js stays the source of the
--    actual math; these tables are the lookup + provenance spine)
-- ============================================================================
