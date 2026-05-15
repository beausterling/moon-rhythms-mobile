-- Migration 0003 — astro_* deterministic reference schema
-- 17 read-only reference tables that hold the structured grammar of Western astrology.
-- Seeded by migration 0004; never written by application code at runtime.
-- All tables have RLS enabled with public-read policies (no writes from authenticated role).
-- Per supabase_master_doc.md §3.1 and PHASE_1_HANDOFF.md §3.1.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. astro_planets
-- ============================================================================
CREATE TABLE public.astro_planets (
    id                          TEXT PRIMARY KEY,
    name                        TEXT NOT NULL,
    glyph                       TEXT NOT NULL,
    type                        TEXT NOT NULL CHECK (type IN ('luminary', 'personal_planet', 'social_planet', 'transpersonal_planet')),
    archetype                   TEXT NOT NULL,
    function_text               TEXT NOT NULL,
    is_personal                 BOOLEAN NOT NULL DEFAULT FALSE,
    is_social                   BOOLEAN NOT NULL DEFAULT FALSE,
    is_transpersonal            BOOLEAN NOT NULL DEFAULT FALSE,
    avg_speed_per_day_degrees   NUMERIC,
    orbit_years                 NUMERIC,
    discovery_year              INTEGER,
    modern_keywords             TEXT[] NOT NULL DEFAULT '{}',
    sort_order                  INTEGER NOT NULL,
    user_facing                 BOOLEAN NOT NULL DEFAULT TRUE,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 2. astro_points (non-planetary chart points)
-- ============================================================================
CREATE TABLE public.astro_points (
    id                  TEXT PRIMARY KEY,
    name                TEXT NOT NULL,
    alternate_names     TEXT[] NOT NULL DEFAULT '{}',
    glyph               TEXT,
    type                TEXT NOT NULL CHECK (type IN ('lunar_node', 'centaur', 'calculated_point', 'chart_angle', 'arabic_part')),
    archetype           TEXT NOT NULL,
    function_text       TEXT NOT NULL,
    modern_keywords     TEXT[] NOT NULL DEFAULT '{}',
    calculation_method  TEXT,
    is_house_cusp       INTEGER,
    always_opposite     TEXT REFERENCES public.astro_points(id) DEFERRABLE INITIALLY DEFERRED,
    user_facing         BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INTEGER NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 3. astro_signs
-- ============================================================================
CREATE TABLE public.astro_signs (
    id                          TEXT PRIMARY KEY,
    name                        TEXT NOT NULL,
    glyph                       TEXT NOT NULL,
    symbol                      TEXT NOT NULL,
    ordinal                     INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 12),
    element                     TEXT NOT NULL CHECK (element IN ('fire', 'earth', 'air', 'water')),
    modality                    TEXT NOT NULL CHECK (modality IN ('cardinal', 'fixed', 'mutable')),
    polarity                    TEXT NOT NULL CHECK (polarity IN ('active', 'receptive')),
    ruler                       TEXT NOT NULL REFERENCES public.astro_planets(id),
    traditional_ruler           TEXT REFERENCES public.astro_planets(id),
    approximate_dates           TEXT NOT NULL,
    season_northern_hemisphere  TEXT,
    archetype                   TEXT NOT NULL,
    modern_keywords             TEXT[] NOT NULL DEFAULT '{}',
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_signs_element  ON public.astro_signs(element);
CREATE INDEX idx_signs_modality ON public.astro_signs(modality);
CREATE INDEX idx_signs_ruler    ON public.astro_signs(ruler);

-- ============================================================================
-- 4. astro_dignities (many-to-many: planet × sign × dignity_type)
-- ============================================================================
CREATE TABLE public.astro_dignities (
    id              SERIAL PRIMARY KEY,
    planet_id       TEXT NOT NULL REFERENCES public.astro_planets(id),
    sign_id         TEXT NOT NULL REFERENCES public.astro_signs(id),
    dignity_type    TEXT NOT NULL CHECK (dignity_type IN ('rulership', 'exaltation', 'detriment', 'fall', 'traditional_rulership')),
    UNIQUE (planet_id, sign_id, dignity_type)
);

CREATE INDEX idx_dignities_planet ON public.astro_dignities(planet_id);
CREATE INDEX idx_dignities_sign   ON public.astro_dignities(sign_id);
CREATE INDEX idx_dignities_type   ON public.astro_dignities(dignity_type);

-- ============================================================================
-- 5. astro_houses
-- ============================================================================
CREATE TABLE public.astro_houses (
    ordinal                         INTEGER PRIMARY KEY CHECK (ordinal BETWEEN 1 AND 12),
    name                            TEXT NOT NULL,
    alternate_names                 TEXT[] NOT NULL DEFAULT '{}',
    polarity                        TEXT NOT NULL CHECK (polarity IN ('angular', 'succedent', 'cadent')),
    weight                          TEXT NOT NULL CHECK (weight IN ('high', 'medium', 'low')),
    associated_sign                 TEXT NOT NULL REFERENCES public.astro_signs(id),
    associated_planet               TEXT NOT NULL REFERENCES public.astro_planets(id),
    associated_planet_traditional   TEXT REFERENCES public.astro_planets(id),
    cusp_is_chart_angle             TEXT,
    domain                          TEXT NOT NULL,
    modern_keywords                 TEXT[] NOT NULL DEFAULT '{}',
    created_at                      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_houses_polarity ON public.astro_houses(polarity);

-- ============================================================================
-- 6. astro_aspects
-- ============================================================================
CREATE TABLE public.astro_aspects (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    alternate_names TEXT[] NOT NULL DEFAULT '{}',
    glyph           TEXT,
    degrees         NUMERIC NOT NULL CHECK (degrees BETWEEN 0 AND 180),
    default_orb     NUMERIC NOT NULL CHECK (default_orb > 0),
    valence         TEXT NOT NULL,
    polarity        TEXT NOT NULL CHECK (polarity IN ('harmonious', 'challenging', 'neutral')),
    description     TEXT NOT NULL,
    is_major        BOOLEAN NOT NULL,
    synastry_orb    NUMERIC,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_aspects_is_major ON public.astro_aspects(is_major);

-- ============================================================================
-- 7. astro_elements
-- ============================================================================
CREATE TABLE public.astro_elements (
    id                      TEXT PRIMARY KEY,
    name                    TEXT NOT NULL,
    archetype               TEXT NOT NULL,
    modern_keywords         TEXT[] NOT NULL DEFAULT '{}',
    compatible_elements     TEXT[] NOT NULL DEFAULT '{}',
    challenging_elements    TEXT[] NOT NULL DEFAULT '{}',
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 8. astro_modalities
-- ============================================================================
CREATE TABLE public.astro_modalities (
    id              TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    archetype       TEXT NOT NULL,
    function_text   TEXT NOT NULL,
    modern_keywords TEXT[] NOT NULL DEFAULT '{}',
    season_marker   TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 9. astro_lunar_phases
-- ============================================================================
CREATE TABLE public.astro_lunar_phases (
    id                  TEXT PRIMARY KEY,
    name                TEXT NOT NULL,
    alternate_names     TEXT[] NOT NULL DEFAULT '{}',
    ordinal             INTEGER NOT NULL UNIQUE CHECK (ordinal BETWEEN 1 AND 8),
    sun_moon_angle_min  NUMERIC NOT NULL CHECK (sun_moon_angle_min >= 0 AND sun_moon_angle_min < 360),
    sun_moon_angle_max  NUMERIC NOT NULL CHECK (sun_moon_angle_max > 0 AND sun_moon_angle_max <= 360),
    archetype           TEXT NOT NULL,
    function_text       TEXT NOT NULL,
    modern_keywords     TEXT[] NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (sun_moon_angle_max > sun_moon_angle_min)
);

-- ============================================================================
-- 10. astro_decans
-- ============================================================================
CREATE TABLE public.astro_decans (
    id              SERIAL PRIMARY KEY,
    sign_id         TEXT NOT NULL REFERENCES public.astro_signs(id),
    decan_number    INTEGER NOT NULL CHECK (decan_number BETWEEN 1 AND 3),
    degree_start    NUMERIC NOT NULL CHECK (degree_start >= 0 AND degree_start < 30),
    degree_end      NUMERIC NOT NULL CHECK (degree_end > 0 AND degree_end <= 30),
    sub_ruler       TEXT NOT NULL REFERENCES public.astro_planets(id),
    flavor          TEXT NOT NULL,
    UNIQUE (sign_id, decan_number),
    CHECK (degree_end > degree_start)
);

CREATE INDEX idx_decans_sign      ON public.astro_decans(sign_id);
CREATE INDEX idx_decans_sub_ruler ON public.astro_decans(sub_ruler);

-- ============================================================================
-- 11. astro_house_systems
-- ============================================================================
CREATE TABLE public.astro_house_systems (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    method      TEXT NOT NULL,
    best_for    TEXT,
    limitation  TEXT,
    is_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_house_systems_one_default ON public.astro_house_systems(is_default) WHERE is_default = TRUE;

-- ============================================================================
-- 12. astro_synastry_patterns
-- ============================================================================
CREATE TABLE public.astro_synastry_patterns (
    id              SERIAL PRIMARY KEY,
    pattern_key     TEXT NOT NULL UNIQUE,
    pattern_type    TEXT NOT NULL CHECK (pattern_type IN ('high_significance', 'challenging', 'harmonious')),
    description     TEXT NOT NULL,
    weight          INTEGER NOT NULL DEFAULT 1 CHECK (weight BETWEEN 1 AND 10),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 13. astro_moon_compatibility
-- ============================================================================
CREATE TABLE public.astro_moon_compatibility (
    id              SERIAL PRIMARY KEY,
    element_a       TEXT NOT NULL REFERENCES public.astro_elements(id),
    element_b       TEXT NOT NULL REFERENCES public.astro_elements(id),
    compatibility   TEXT NOT NULL CHECK (compatibility IN ('high', 'moderate', 'challenging')),
    description     TEXT NOT NULL,
    UNIQUE (element_a, element_b)
);

CREATE INDEX idx_moon_compat ON public.astro_moon_compatibility(element_a, element_b);

-- ============================================================================
-- 14. astro_transit_significance
-- ============================================================================
CREATE TABLE public.astro_transit_significance (
    id                  SERIAL PRIMARY KEY,
    transit_pattern     TEXT NOT NULL UNIQUE,
    significance        TEXT NOT NULL CHECK (significance IN ('highest', 'moderate', 'low')),
    description         TEXT NOT NULL,
    user_alert_default  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 15. astro_app_settings
-- ============================================================================
CREATE TABLE public.astro_app_settings (
    key         TEXT PRIMARY KEY,
    value       JSONB NOT NULL,
    description TEXT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 16. astro_overridable_preferences (catalog of which app_settings may be overridden by users)
-- ============================================================================
CREATE TABLE public.astro_overridable_preferences (
    key                 TEXT PRIMARY KEY,
    label               TEXT NOT NULL,
    description         TEXT NOT NULL,
    valid_values        JSONB NOT NULL,
    advanced_user_only  BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order          INTEGER NOT NULL DEFAULT 100,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- 17. astro_preference_changes (append-only log; user_id FK added later when accounts exists)
-- ============================================================================
CREATE TABLE public.astro_preference_changes (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL,
    preference_key  TEXT NOT NULL REFERENCES public.astro_overridable_preferences(key),
    old_value       JSONB,
    new_value       JSONB NOT NULL,
    source          TEXT NOT NULL CHECK (source IN ('user_action', 'admin', 'system_migration', 'rollback')),
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pref_changes_user_time ON public.astro_preference_changes(user_id, changed_at DESC);
CREATE INDEX idx_pref_changes_key       ON public.astro_preference_changes(preference_key);

-- ============================================================================
-- Helper SQL functions
-- ============================================================================

-- Get the effective value for a user preference: the user's override if set,
-- otherwise the global default from astro_app_settings.
-- Wraps the accounts lookup in BEGIN/EXCEPTION so it works even before
-- public.accounts exists (deterministic schema is deployed before user schema).
CREATE OR REPLACE FUNCTION public.get_effective_preference(
    p_user_id UUID,
    p_preference_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    v_override JSONB;
    v_default JSONB;
BEGIN
    BEGIN
        EXECUTE format(
            'SELECT astro_preferences -> %L FROM public.accounts WHERE id = %L',
            p_preference_key, p_user_id
        ) INTO v_override;
    EXCEPTION
        WHEN undefined_table THEN
            v_override := NULL;
    END;

    IF v_override IS NOT NULL THEN
        RETURN v_override;
    END IF;

    SELECT value INTO v_default
    FROM public.astro_app_settings
    WHERE key = p_preference_key;

    RETURN v_default;
END;
$$;

-- Validate + write a user preference override, log the change.
CREATE OR REPLACE FUNCTION public.set_user_preference(
    p_user_id UUID,
    p_preference_key TEXT,
    p_new_value JSONB,
    p_source TEXT DEFAULT 'user_action'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_valid_values JSONB;
    v_old_value JSONB;
BEGIN
    SELECT valid_values INTO v_valid_values
    FROM public.astro_overridable_preferences
    WHERE key = p_preference_key;

    IF v_valid_values IS NULL THEN
        RAISE EXCEPTION 'Unknown preference key: %', p_preference_key;
    END IF;

    IF NOT (v_valid_values @> p_new_value OR v_valid_values @> jsonb_build_array(p_new_value)) THEN
        RAISE EXCEPTION 'Value % is not in valid_values for preference %', p_new_value, p_preference_key;
    END IF;

    BEGIN
        EXECUTE format(
            'SELECT astro_preferences -> %L FROM public.accounts WHERE id = %L',
            p_preference_key, p_user_id
        ) INTO v_old_value;

        EXECUTE format(
            'UPDATE public.accounts SET astro_preferences = astro_preferences || jsonb_build_object(%L, %L::jsonb), updated_at = NOW() WHERE id = %L',
            p_preference_key, p_new_value::text, p_user_id
        );
    EXCEPTION
        WHEN undefined_table THEN
            RAISE EXCEPTION 'public.accounts does not exist yet — apply user-domain migration first';
    END;

    INSERT INTO public.astro_preference_changes (user_id, preference_key, old_value, new_value, source)
    VALUES (p_user_id, p_preference_key, v_old_value, p_new_value, p_source);

    RETURN TRUE;
END;
$$;

-- Remove a user's preference override (revert to global default).
CREATE OR REPLACE FUNCTION public.reset_user_preference(
    p_user_id UUID,
    p_preference_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_old_value JSONB;
BEGIN
    BEGIN
        EXECUTE format(
            'SELECT astro_preferences -> %L FROM public.accounts WHERE id = %L',
            p_preference_key, p_user_id
        ) INTO v_old_value;

        EXECUTE format(
            'UPDATE public.accounts SET astro_preferences = astro_preferences - %L, updated_at = NOW() WHERE id = %L',
            p_preference_key, p_user_id
        );
    EXCEPTION
        WHEN undefined_table THEN
            RAISE EXCEPTION 'public.accounts does not exist yet';
    END;

    INSERT INTO public.astro_preference_changes (user_id, preference_key, old_value, new_value, source)
    VALUES (p_user_id, p_preference_key, v_old_value, 'null'::jsonb, 'user_action');

    RETURN TRUE;
END;
$$;

-- ============================================================================
-- Convenience views
-- ============================================================================

CREATE OR REPLACE VIEW public.v_planet_dignities AS
SELECT
    p.id AS planet_id,
    p.name AS planet_name,
    p.glyph AS planet_glyph,
    s.id AS sign_id,
    s.name AS sign_name,
    s.glyph AS sign_glyph,
    d.dignity_type
FROM public.astro_dignities d
JOIN public.astro_planets p ON p.id = d.planet_id
JOIN public.astro_signs   s ON s.id = d.sign_id
ORDER BY p.sort_order, d.dignity_type;

CREATE OR REPLACE VIEW public.v_signs_full AS
SELECT
    s.*,
    e.archetype AS element_archetype,
    m.archetype AS modality_archetype,
    p.name AS ruler_name,
    p.glyph AS ruler_glyph,
    tp.name AS traditional_ruler_name,
    tp.glyph AS traditional_ruler_glyph
FROM public.astro_signs s
JOIN public.astro_elements   e  ON e.id  = s.element
JOIN public.astro_modalities m  ON m.id  = s.modality
JOIN public.astro_planets    p  ON p.id  = s.ruler
LEFT JOIN public.astro_planets tp ON tp.id = s.traditional_ruler;

CREATE OR REPLACE VIEW public.v_houses_full AS
SELECT
    h.*,
    s.name  AS associated_sign_name,
    s.glyph AS associated_sign_glyph,
    p.name  AS associated_planet_name,
    p.glyph AS associated_planet_glyph
FROM public.astro_houses h
JOIN public.astro_signs   s ON s.id = h.associated_sign
JOIN public.astro_planets p ON p.id = h.associated_planet;

-- ============================================================================
-- RLS — every astro_* table is publicly readable; writes service-role only.
-- ============================================================================
ALTER TABLE public.astro_planets               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_points                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_signs                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_dignities             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_houses                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_aspects               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_elements              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_modalities            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_lunar_phases          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_decans                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_house_systems         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_synastry_patterns     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_moon_compatibility    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_transit_significance  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_app_settings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_overridable_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.astro_preference_changes    ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read astro_planets"               ON public.astro_planets               FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_points"                ON public.astro_points                FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_signs"                 ON public.astro_signs                 FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_dignities"             ON public.astro_dignities             FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_houses"                ON public.astro_houses                FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_aspects"               ON public.astro_aspects               FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_elements"              ON public.astro_elements              FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_modalities"            ON public.astro_modalities            FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_lunar_phases"          ON public.astro_lunar_phases          FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_decans"                ON public.astro_decans                FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_house_systems"         ON public.astro_house_systems         FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_synastry_patterns"     ON public.astro_synastry_patterns     FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_moon_compatibility"    ON public.astro_moon_compatibility    FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_transit_significance"  ON public.astro_transit_significance  FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_app_settings"          ON public.astro_app_settings          FOR SELECT USING (TRUE);
CREATE POLICY "Public read astro_overridable_preferences" ON public.astro_overridable_preferences FOR SELECT USING (TRUE);

-- astro_preference_changes: users see their own; writes are service-role-only (via the helpers).
CREATE POLICY "Users read own preference changes" ON public.astro_preference_changes
  FOR SELECT USING (user_id = auth.uid());
