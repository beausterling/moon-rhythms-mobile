-- ============================================================================
-- Moon Rhythms — Human Design Deterministic Mechanical Reference Schema
-- ============================================================================
--
-- Purpose: Postgres/Supabase schema for the deterministic Human Design
-- mechanical spine. Parallel to the astrology `astro_*` reference tables;
-- every Human Design chart calculation and prompt assembly references these.
--
-- This schema is for STRUCTURED MECHANICAL LOOKUP data only (gates, channels,
-- centers, types, authorities, lines, profiles, definitions, the gate wheel,
-- and incarnation-cross names). Interpretive prose is OUT of scope here and
-- lives in the separate knowledge_chunks / RAG layer.
--
-- All tables are READ-ONLY for the application. They're seeded once from
-- human_design_data.json and never updated by user actions.
--
-- Naming convention: prefix all tables with `hd_` to namespace them clearly,
-- parallel to astrology's `astro_` prefix.
--
-- Generated: 2026-06-23
-- Source JSON: systems/human_design_data.json
-- ============================================================================

-- ============================================================================
-- CENTERS (9 energy hubs)
-- ============================================================================

CREATE TABLE hd_centers (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    category        TEXT NOT NULL CHECK (category IN ('pressure','awareness','motor','throat','identity','pressure_and_motor')),
    sort_order      INTEGER NOT NULL,
    theme           TEXT NOT NULL,
    biological      TEXT NOT NULL,
    pressure        TEXT,                 -- pressure descriptor (pressure centers only)
    gates           INTEGER[] NOT NULL DEFAULT '{}',  -- the gates that sit in this center

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hd_centers_category ON hd_centers(category);

COMMENT ON TABLE hd_centers IS 'The 9 Human Design centers. category classifies each (pressure/awareness/motor/throat/identity).';

-- ============================================================================
-- GATES (64 hexagrams mapped onto the zodiac wheel)
-- ============================================================================

CREATE TABLE hd_gates (
    gate            INTEGER PRIMARY KEY CHECK (gate BETWEEN 1 AND 64),
    center          TEXT NOT NULL REFERENCES hd_centers(id),
    hd_name         TEXT NOT NULL,
    hexagram_number INTEGER NOT NULL CHECK (hexagram_number BETWEEN 1 AND 64),
    hexagram_name   TEXT NOT NULL,
    theme           TEXT NOT NULL,
    lines           INTEGER NOT NULL DEFAULT 6 CHECK (lines = 6),
    -- degree_range is irregular nested data: start/end longitudes, zodiac
    -- strings, wheel_index, span_degrees, wraps_aries_point. Stored as JSONB.
    degree_range    JSONB NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hd_gates_center ON hd_gates(center);

COMMENT ON TABLE hd_gates IS 'The 64 gates (I Ching hexagrams). Each spans 5.625 degrees of the wheel; degree_range holds the exact longitude band as JSONB.';

-- ============================================================================
-- CHANNELS (36 connections between two gates / two centers)
-- ============================================================================

CREATE TABLE hd_channels (
    id              SERIAL PRIMARY KEY,
    gate_a          INTEGER NOT NULL REFERENCES hd_gates(gate),
    gate_b          INTEGER NOT NULL REFERENCES hd_gates(gate),
    gates           INTEGER[] NOT NULL,   -- both gates, as stored in source
    center_a        TEXT NOT NULL REFERENCES hd_centers(id),
    center_b        TEXT NOT NULL REFERENCES hd_centers(id),
    centers         TEXT[] NOT NULL,      -- both centers, as stored in source
    name            TEXT NOT NULL,
    theme           TEXT NOT NULL,

    UNIQUE (gate_a, gate_b),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hd_channels_gate_a ON hd_channels(gate_a);
CREATE INDEX idx_hd_channels_gate_b ON hd_channels(gate_b);

COMMENT ON TABLE hd_channels IS 'The 36 channels. A channel is defined when both its gates are active, which in turn defines its two centers.';

-- ============================================================================
-- TYPES (5 energy types)
-- ============================================================================

CREATE TABLE hd_types (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    aura            TEXT NOT NULL,
    strategy        TEXT NOT NULL,
    signature       TEXT NOT NULL,
    not_self        TEXT NOT NULL,
    percentage      TEXT,
    descriptor      TEXT NOT NULL,
    determination_rule TEXT NOT NULL,     -- plain-language mechanical rule

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_types IS 'The 5 energy types. determination_rule encodes the defined-center condition that produces each type.';

-- ============================================================================
-- AUTHORITIES (7 decision-making authorities, in precedence order)
-- ============================================================================

CREATE TABLE hd_authorities (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    precedence_order INTEGER NOT NULL,    -- lower = checked first
    deciding_center TEXT REFERENCES hd_centers(id),  -- NULL for lunar/mental
    rule            TEXT NOT NULL,
    descriptor      TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_hd_authorities_precedence ON hd_authorities(precedence_order);

COMMENT ON TABLE hd_authorities IS 'The 7 inner authorities, applied in precedence_order (Emotional first, Mental/Environmental last).';

-- ============================================================================
-- LINES (6 universal line archetypes)
-- ============================================================================

CREATE TABLE hd_lines (
    line            INTEGER PRIMARY KEY CHECK (line BETWEEN 1 AND 6),
    name            TEXT NOT NULL,
    keyword         TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_lines IS 'The 6 lines. Each gate is divided into 6 lines of 0.9375 degrees. Personality Sun line over Design Sun line forms the Profile.';

-- ============================================================================
-- PROFILES (12 personality/design line combinations)
-- ============================================================================

CREATE TABLE hd_profiles (
    profile         TEXT PRIMARY KEY,     -- e.g. '1/3'
    name            TEXT NOT NULL,
    personality_line INTEGER NOT NULL REFERENCES hd_lines(line),
    design_line     INTEGER NOT NULL REFERENCES hd_lines(line),
    angle           TEXT NOT NULL CHECK (angle IN ('right','left','juxtaposition')),
    theme           TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_profiles IS 'The 12 profiles. profile = personality_line/design_line. angle maps to the incarnation-cross angle.';

-- ============================================================================
-- DEFINITION TYPES (how defined centers connect into groups)
-- ============================================================================

CREATE TABLE hd_definition_types (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    components      INTEGER NOT NULL,     -- count of connected components
    descriptor      TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_definition_types IS 'The 5 definition types, keyed by the number of connected components among defined centers (0..4).';

-- ============================================================================
-- PLANETARY ACTIVATIONS (the 13 bodies activated Personality + Design)
-- ============================================================================

CREATE TABLE hd_planetary_activations (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    sort_order      INTEGER NOT NULL,
    note            TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_planetary_activations IS 'The 13 bodies, each activated twice (Personality conscious + Design unconscious). The Design rule and derived rules live in hd_settings.';

-- ============================================================================
-- GATE WHEEL (the longitude -> gate mapping)
-- ============================================================================

CREATE TABLE hd_gate_wheel (
    id              INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),  -- single-row config
    gates_count     INTEGER NOT NULL,
    degrees_per_gate NUMERIC NOT NULL,
    degrees_per_line NUMERIC NOT NULL,
    lines_per_gate  INTEGER NOT NULL,
    offset_degrees  NUMERIC NOT NULL,     -- where Gate 25 begins (absolute longitude)
    offset_zodiac   TEXT NOT NULL,
    offset_note     TEXT NOT NULL,
    gate_order      INTEGER[] NOT NULL,   -- gate sequence around the wheel from Gate 25
    order_by_sign   JSONB NOT NULL,       -- approximate per-sign groupings (irregular)

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_gate_wheel IS 'Single-row wheel config: longitude L maps to gate via index = floor(((L - offset_degrees) mod 360) / degrees_per_gate); gate = gate_order[index].';

-- ============================================================================
-- INCARNATION CROSSES (192 named crosses: 64 Personality-Sun gates x 3 angles)
-- ============================================================================

CREATE TABLE hd_incarnation_crosses (
    personality_sun_gate INTEGER PRIMARY KEY REFERENCES hd_gates(gate),
    right_angle     TEXT NOT NULL,        -- Right Angle Cross name for this gate
    left_angle      TEXT NOT NULL,        -- Left Angle Cross name for this gate
    juxtaposition   TEXT NOT NULL,        -- Juxtaposition Cross name for this gate

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_incarnation_crosses IS 'The named incarnation crosses keyed by Personality Sun gate. Each gate yields a Right / Left / Juxtaposition cross name (192 names total over 64 rows).';

-- ============================================================================
-- SETTINGS (Human Design-specific derived rules and metadata, as JSONB)
-- ============================================================================

CREATE TABLE hd_settings (
    key             TEXT PRIMARY KEY,
    value           JSONB NOT NULL,
    description     TEXT NOT NULL,

    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE hd_settings IS 'Human Design config: planetary Design-calculation rule, derived activation rules, determination algorithms, and source metadata. Stored as JSONB.';

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================
-- Reference data: readable by all authenticated users; writable only by
-- service_role (migrations / seed). Mirrors the astrology idiom and adds an
-- explicit service_role ALL policy per table.

ALTER TABLE hd_centers ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_gates ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_channels ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_authorities ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_definition_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_planetary_activations ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_gate_wheel ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_incarnation_crosses ENABLE ROW LEVEL SECURITY;
ALTER TABLE hd_settings ENABLE ROW LEVEL SECURITY;

-- Read access for all authenticated users
CREATE POLICY "Authenticated read centers" ON hd_centers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read gates" ON hd_gates FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read channels" ON hd_channels FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read types" ON hd_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read authorities" ON hd_authorities FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read lines" ON hd_lines FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read profiles" ON hd_profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read definition_types" ON hd_definition_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read planetary_activations" ON hd_planetary_activations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read gate_wheel" ON hd_gate_wheel FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read incarnation_crosses" ON hd_incarnation_crosses FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated read settings" ON hd_settings FOR SELECT TO authenticated USING (true);

-- Full access for service_role (seed / migrations)
CREATE POLICY "Service role manage centers" ON hd_centers FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage gates" ON hd_gates FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage channels" ON hd_channels FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage types" ON hd_types FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage authorities" ON hd_authorities FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage lines" ON hd_lines FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage profiles" ON hd_profiles FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage definition_types" ON hd_definition_types FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage planetary_activations" ON hd_planetary_activations FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage gate_wheel" ON hd_gate_wheel FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage incarnation_crosses" ON hd_incarnation_crosses FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Service role manage settings" ON hd_settings FOR ALL TO service_role USING (true) WITH CHECK (true);

-- ============================================================================
-- END SCHEMA
-- ============================================================================
-- Next: run human_design_seed.sql to load values from human_design_data.json.
-- ============================================================================
