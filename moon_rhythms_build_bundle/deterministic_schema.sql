-- ============================================================================
-- Moon Rhythms — Deterministic Astrological Reference Schema
-- ============================================================================
-- 
-- Purpose: Postgres/Supabase schema for the deterministic astrological reference
-- data. This is the SPINE of Moon Rhythms — every chart calculation, every AI
-- prompt assembly, and every RAG chunk references these tables.
--
-- This schema is for STRUCTURED LOOKUP data only. Interpretive content goes in
-- the separate `knowledge_chunks` table with pgvector embeddings.
--
-- All tables in this schema are READ-ONLY for the application. They're seeded
-- once from deterministic_data.json and never updated by user actions.
--
-- Naming convention: prefix all tables with `astro_` to namespace them clearly
-- and avoid collision with user-data tables.
-- ============================================================================

-- Enable required extensions (run as superuser; Supabase has these available)
-- CREATE EXTENSION IF NOT EXISTS pgvector;  -- for the chunks table later

-- ============================================================================
-- PLANETS
-- ============================================================================

CREATE TABLE astro_planets (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    glyph           TEXT NOT NULL,
    type            TEXT NOT NULL CHECK (type IN ('luminary', 'personal_planet', 'social_planet', 'transpersonal_planet')),
    archetype       TEXT NOT NULL,
    function_text   TEXT NOT NULL,  -- "function" is reserved in PG
    is_personal     BOOLEAN NOT NULL DEFAULT FALSE,
    is_social       BOOLEAN NOT NULL DEFAULT FALSE,
    is_transpersonal BOOLEAN NOT NULL DEFAULT FALSE,
    avg_speed_per_day_degrees NUMERIC,
    orbit_years     NUMERIC,
    discovery_year  INTEGER,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    sort_order      INTEGER NOT NULL,
    
    -- Display metadata for the app
    user_facing     BOOLEAN NOT NULL DEFAULT TRUE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_planets IS 'The 10 planetary bodies used in Moon Rhythms charts. Read-only seed data.';

-- ============================================================================
-- ADDITIONAL CHART POINTS (nodes, asteroids, angles, arabic parts)
-- ============================================================================

CREATE TABLE astro_points (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    alternate_names TEXT[] DEFAULT '{}',
    glyph           TEXT,
    type            TEXT NOT NULL CHECK (type IN ('lunar_node', 'centaur', 'calculated_point', 'chart_angle', 'arabic_part')),
    archetype       TEXT NOT NULL,
    function_text   TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    
    -- Calculation metadata
    calculation_method TEXT,
    is_house_cusp   INTEGER, -- if this point is also a house cusp
    always_opposite TEXT REFERENCES astro_points(id) DEFERRABLE INITIALLY DEFERRED,
    
    user_facing     BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order      INTEGER NOT NULL,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_points IS 'Non-planetary points: nodes, Chiron, Lilith, chart angles, and Part of Fortune.';

-- ============================================================================
-- SIGNS
-- ============================================================================

CREATE TABLE astro_signs (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    glyph           TEXT NOT NULL,
    symbol          TEXT NOT NULL,  -- e.g., "the ram"
    ordinal         INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 12),
    element         TEXT NOT NULL CHECK (element IN ('fire', 'earth', 'air', 'water')),
    modality        TEXT NOT NULL CHECK (modality IN ('cardinal', 'fixed', 'mutable')),
    polarity        TEXT NOT NULL CHECK (polarity IN ('active', 'receptive')),
    ruler           TEXT NOT NULL REFERENCES astro_planets(id),
    traditional_ruler TEXT REFERENCES astro_planets(id),
    approximate_dates TEXT NOT NULL,  -- e.g., "March 20 - April 19"
    season_northern_hemisphere TEXT,
    archetype       TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_signs_element ON astro_signs(element);
CREATE INDEX idx_signs_modality ON astro_signs(modality);
CREATE INDEX idx_signs_ruler ON astro_signs(ruler);

COMMENT ON TABLE astro_signs IS 'The 12 zodiac signs with classifications and rulers.';

-- ============================================================================
-- DIGNITIES (planet relationships to signs: rulership, exaltation, detriment, fall)
-- ============================================================================

-- This is a separate table because some planets have multiple sign-relationships
-- and some signs have multiple planets in dignity. Many-to-many requires a join table.

CREATE TABLE astro_dignities (
    id              SERIAL PRIMARY KEY,
    planet_id       TEXT NOT NULL REFERENCES astro_planets(id),
    sign_id         TEXT NOT NULL REFERENCES astro_signs(id),
    dignity_type    TEXT NOT NULL CHECK (dignity_type IN ('rulership', 'exaltation', 'detriment', 'fall', 'traditional_rulership')),
    
    UNIQUE (planet_id, sign_id, dignity_type)
);

CREATE INDEX idx_dignities_planet ON astro_dignities(planet_id);
CREATE INDEX idx_dignities_sign ON astro_dignities(sign_id);
CREATE INDEX idx_dignities_type ON astro_dignities(dignity_type);

COMMENT ON TABLE astro_dignities IS 'Many-to-many: which planets are strong/weak in which signs. Used by AI to weight interpretations.';

-- ============================================================================
-- HOUSES
-- ============================================================================

CREATE TABLE astro_houses (
    ordinal         INTEGER PRIMARY KEY CHECK (ordinal BETWEEN 1 AND 12),
    name            TEXT NOT NULL,
    alternate_names TEXT[] DEFAULT '{}',
    polarity        TEXT NOT NULL CHECK (polarity IN ('angular', 'succedent', 'cadent')),
    weight          TEXT NOT NULL CHECK (weight IN ('high', 'medium', 'low')),
    associated_sign TEXT NOT NULL REFERENCES astro_signs(id),
    associated_planet TEXT NOT NULL REFERENCES astro_planets(id),
    associated_planet_traditional TEXT REFERENCES astro_planets(id),
    cusp_is_chart_angle TEXT,  -- 'ascendant', 'imum_coeli', 'descendant', 'midheaven', or null
    domain          TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_houses_polarity ON astro_houses(polarity);

COMMENT ON TABLE astro_houses IS 'The 12 houses with life-domain mappings. Angular houses (1,4,7,10) carry highest weight.';

-- ============================================================================
-- ASPECTS
-- ============================================================================

CREATE TABLE astro_aspects (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    alternate_names TEXT[] DEFAULT '{}',
    glyph           TEXT,
    degrees         NUMERIC NOT NULL CHECK (degrees >= 0 AND degrees <= 180),
    default_orb     NUMERIC NOT NULL CHECK (default_orb > 0),
    valence         TEXT NOT NULL,  -- 'merging', 'cooperative', 'frictional', 'flowing', 'polarizing', etc.
    polarity        TEXT NOT NULL CHECK (polarity IN ('harmonious', 'challenging', 'neutral')),
    description     TEXT NOT NULL,
    is_major        BOOLEAN NOT NULL,
    
    -- Synastry-specific orb (often tighter than natal)
    synastry_orb    NUMERIC,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_aspects_is_major ON astro_aspects(is_major);

COMMENT ON TABLE astro_aspects IS 'Major and minor aspects with degrees, default orbs, and valence labels.';

-- ============================================================================
-- ELEMENTS
-- ============================================================================

CREATE TABLE astro_elements (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    archetype       TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    compatible_elements TEXT[] NOT NULL DEFAULT '{}',
    challenging_elements TEXT[] NOT NULL DEFAULT '{}',
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_elements IS 'The four classical elements. Used for compatibility analysis.';

-- ============================================================================
-- MODALITIES
-- ============================================================================

CREATE TABLE astro_modalities (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    archetype       TEXT NOT NULL,
    function_text   TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    season_marker   TEXT,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_modalities IS 'Cardinal, Fixed, Mutable.';

-- ============================================================================
-- LUNAR PHASES
-- ============================================================================

CREATE TABLE astro_lunar_phases (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    alternate_names TEXT[] DEFAULT '{}',
    ordinal         INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 8),
    sun_moon_angle_min NUMERIC NOT NULL CHECK (sun_moon_angle_min >= 0 AND sun_moon_angle_min < 360),
    sun_moon_angle_max NUMERIC NOT NULL CHECK (sun_moon_angle_max > 0 AND sun_moon_angle_max <= 360),
    archetype       TEXT NOT NULL,
    function_text   TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    
    CHECK (sun_moon_angle_max > sun_moon_angle_min),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_lunar_phases IS 'The 8 lunar phases. Critical for Moon Rhythms.';

-- ============================================================================
-- DECANS (3 sub-divisions per sign)
-- ============================================================================

CREATE TABLE astro_decans (
    id              SERIAL PRIMARY KEY,
    sign_id         TEXT NOT NULL REFERENCES astro_signs(id),
    decan_number    INTEGER NOT NULL CHECK (decan_number BETWEEN 1 AND 3),
    degree_start    NUMERIC NOT NULL CHECK (degree_start >= 0 AND degree_start < 30),
    degree_end      NUMERIC NOT NULL CHECK (degree_end > 0 AND degree_end <= 30),
    sub_ruler       TEXT NOT NULL REFERENCES astro_planets(id),
    flavor          TEXT NOT NULL,  -- one-line interpretive flavor
    
    UNIQUE (sign_id, decan_number),
    CHECK (degree_end > degree_start)
);

CREATE INDEX idx_decans_sign ON astro_decans(sign_id);
CREATE INDEX idx_decans_sub_ruler ON astro_decans(sub_ruler);

COMMENT ON TABLE astro_decans IS '36 decans (12 signs × 3). Each is a 10° subdivision with a sub-ruler.';

-- ============================================================================
-- HOUSE SYSTEMS (mathematical methods for dividing the sky)
-- ============================================================================

CREATE TABLE astro_house_systems (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    method          TEXT NOT NULL,
    best_for        TEXT,
    limitation      TEXT,
    is_default      BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enforce only one default
CREATE UNIQUE INDEX idx_house_systems_one_default 
    ON astro_house_systems(is_default) WHERE is_default = TRUE;

COMMENT ON TABLE astro_house_systems IS 'Placidus (default), Whole Sign, Koch, Equal House.';

-- ============================================================================
-- SYNASTRY FRAMEWORK (rules for two-chart comparison)
-- ============================================================================

CREATE TABLE astro_synastry_patterns (
    id              SERIAL PRIMARY KEY,
    pattern_key     TEXT NOT NULL UNIQUE,
    pattern_type    TEXT NOT NULL CHECK (pattern_type IN ('high_significance', 'challenging', 'harmonious')),
    description     TEXT NOT NULL,
    weight          INTEGER NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 10),  -- AI's weight in interpretation
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_synastry_patterns IS 'Patterns the AI should weight when interpreting two-chart compatibility.';

-- ============================================================================
-- MOON SIGN COMPATIBILITY MATRIX
-- ============================================================================

CREATE TABLE astro_moon_compatibility (
    id              SERIAL PRIMARY KEY,
    element_a       TEXT NOT NULL REFERENCES astro_elements(id),
    element_b       TEXT NOT NULL REFERENCES astro_elements(id),
    compatibility   TEXT NOT NULL CHECK (compatibility IN ('high', 'moderate', 'challenging')),
    description     TEXT NOT NULL,
    
    UNIQUE (element_a, element_b)
);

CREATE INDEX idx_moon_compat_elements ON astro_moon_compatibility(element_a, element_b);

COMMENT ON TABLE astro_moon_compatibility IS 'Element-based moon-sign compatibility heuristic. Quick first-pass before deeper synastry.';

-- ============================================================================
-- TRANSIT SIGNIFICANCE (which transits to alert users about)
-- ============================================================================

CREATE TABLE astro_transit_significance (
    id              SERIAL PRIMARY KEY,
    transit_pattern TEXT NOT NULL UNIQUE,
    significance    TEXT NOT NULL CHECK (significance IN ('highest', 'moderate', 'low')),
    description     TEXT NOT NULL,
    user_alert_default BOOLEAN NOT NULL DEFAULT FALSE,  -- should this trigger a notification by default?
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_transit_significance IS 'Which transits matter enough to surface to users.';

-- ============================================================================
-- APPLICATION SETTINGS (Moon Rhythms-specific defaults)
-- ============================================================================

CREATE TABLE astro_app_settings (
    key             TEXT PRIMARY KEY,
    value           JSONB NOT NULL,
    description     TEXT NOT NULL,
    
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_app_settings IS 'Moon Rhythms-specific configuration: default house system, voice rules, supported planets.';

-- ============================================================================
-- VIEWS — for common queries the AI/app will run
-- ============================================================================

-- "Get all dignities for a planet" — used by the AI when interpreting a placement
CREATE VIEW v_planet_dignities AS
SELECT 
    p.id AS planet_id,
    p.name AS planet_name,
    s.id AS sign_id,
    s.name AS sign_name,
    d.dignity_type
FROM astro_dignities d
JOIN astro_planets p ON p.id = d.planet_id
JOIN astro_signs s ON s.id = d.sign_id
ORDER BY p.sort_order, d.dignity_type;

-- "Sign with all its classifications" — used everywhere
CREATE VIEW v_signs_full AS
SELECT 
    s.*,
    e.archetype AS element_archetype,
    e.modern_keywords AS element_keywords,
    m.archetype AS modality_archetype,
    p.name AS ruler_name,
    p.glyph AS ruler_glyph,
    p.archetype AS ruler_archetype
FROM astro_signs s
JOIN astro_elements e ON e.id = s.element
JOIN astro_modalities m ON m.id = s.modality
JOIN astro_planets p ON p.id = s.ruler
ORDER BY s.ordinal;

-- "Houses with their associated planet/sign" — used for chart interpretation
CREATE VIEW v_houses_full AS
SELECT 
    h.*,
    s.name AS associated_sign_name,
    s.element AS associated_sign_element,
    s.modality AS associated_sign_modality,
    p.name AS associated_planet_name
FROM astro_houses h
JOIN astro_signs s ON s.id = h.associated_sign
JOIN astro_planets p ON p.id = h.associated_planet
ORDER BY h.ordinal;

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================
-- These tables are reference data — readable by all authenticated users,
-- not writable by anyone except via migrations.

ALTER TABLE astro_planets ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_signs ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_houses ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_aspects ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_elements ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_modalities ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_lunar_phases ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_decans ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_house_systems ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_dignities ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_synastry_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_moon_compatibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_transit_significance ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_app_settings ENABLE ROW LEVEL SECURITY;

-- Read access for all authenticated users
CREATE POLICY "Public read planets" ON astro_planets FOR SELECT USING (true);
CREATE POLICY "Public read points" ON astro_points FOR SELECT USING (true);
CREATE POLICY "Public read signs" ON astro_signs FOR SELECT USING (true);
CREATE POLICY "Public read houses" ON astro_houses FOR SELECT USING (true);
CREATE POLICY "Public read aspects" ON astro_aspects FOR SELECT USING (true);
CREATE POLICY "Public read elements" ON astro_elements FOR SELECT USING (true);
CREATE POLICY "Public read modalities" ON astro_modalities FOR SELECT USING (true);
CREATE POLICY "Public read lunar_phases" ON astro_lunar_phases FOR SELECT USING (true);
CREATE POLICY "Public read decans" ON astro_decans FOR SELECT USING (true);
CREATE POLICY "Public read house_systems" ON astro_house_systems FOR SELECT USING (true);
CREATE POLICY "Public read dignities" ON astro_dignities FOR SELECT USING (true);
CREATE POLICY "Public read synastry" ON astro_synastry_patterns FOR SELECT USING (true);
CREATE POLICY "Public read moon_compat" ON astro_moon_compatibility FOR SELECT USING (true);
CREATE POLICY "Public read transit_sig" ON astro_transit_significance FOR SELECT USING (true);
CREATE POLICY "Public read settings" ON astro_app_settings FOR SELECT USING (true);

-- ============================================================================
-- END SCHEMA
-- ============================================================================
-- 
-- Next steps:
-- 1. Run this migration on your Supabase project
-- 2. Run the seed script (separate file: deterministic_data_seed.sql) to load
--    data from deterministic_data.json into these tables
-- 3. Reference these tables in your edge functions when assembling AI prompts
--    or running chart calculations
--
-- ============================================================================
