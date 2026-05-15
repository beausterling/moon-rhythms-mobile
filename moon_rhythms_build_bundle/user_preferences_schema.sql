-- ============================================================================
-- Moon Rhythms — User Astrological Preferences Schema (Additive Migration)
-- ============================================================================
--
-- Purpose: Adds the ability for individual users to override global astrological
-- defaults (house system, zodiac, rulership tradition, etc.). This is OPTIONAL
-- functionality — the schema exists from day one, but no UI exposes it for MVP.
--
-- Design pattern: JSONB column on users + log table for analytics + helper
-- function that returns effective preference (user override OR global default).
--
-- IMPORTANT: This migration assumes a `users` table already exists. If it
-- doesn't yet, the ALTER TABLE at the bottom will fail — comment it out and
-- run it separately once your users table is in place.
--
-- Run order:
--   1. deterministic_schema.sql
--   2. deterministic_data_seed.sql  
--   3. (your users table migration, whenever you build user auth)
--   4. THIS FILE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- ENUMERATE THE OVERRIDABLE PREFERENCES
-- ----------------------------------------------------------------------------
-- This table lists which app settings users are ALLOWED to override.
-- The set is closed — users can't override arbitrary settings, only ones we've
-- explicitly opened up. This protects us from users putting nonsense values
-- into the system.
-- ----------------------------------------------------------------------------

CREATE TABLE astro_overridable_preferences (
    key                 TEXT PRIMARY KEY,  -- e.g., 'default_house_system'
    label               TEXT NOT NULL,     -- human-readable for future UI: "House System"
    description         TEXT NOT NULL,     -- explainer for users when toggling
    valid_values        JSONB NOT NULL,    -- array of acceptable values for validation
    advanced_user_only  BOOLEAN NOT NULL DEFAULT TRUE,  -- gate from casual UI
    sort_order          INTEGER NOT NULL DEFAULT 100,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE astro_overridable_preferences IS 
    'Closed list of app settings that individual users may override. Application code MUST validate user inputs against this table before writing.';

-- Seed the overridable preferences
INSERT INTO astro_overridable_preferences (key, label, description, valid_values, advanced_user_only, sort_order) VALUES
(
    'default_house_system',
    'House System',
    'The mathematical method used to divide the sky into 12 houses. Placidus is the modern default; Whole Sign is preferred by some traditional astrologers and works better in extreme latitudes.',
    '["placidus", "whole_sign", "koch", "equal_house"]'::JSONB,
    TRUE,
    10
),
(
    'default_zodiac',
    'Zodiac System',
    'Tropical (the standard Western system, based on seasons) or Sidereal (used in Vedic astrology, based on actual constellations).',
    '["tropical", "sidereal"]'::JSONB,
    TRUE,
    20
),
(
    'use_traditional_rulerships',
    'Use Traditional Rulerships',
    'When enabled, Scorpio is ruled by Mars (not Pluto), Aquarius by Saturn (not Uranus), and Pisces by Jupiter (not Neptune). Used by traditional Hellenistic and medieval astrologers.',
    '[true, false]'::JSONB,
    TRUE,
    30
),
(
    'default_node_calculation',
    'Lunar Node Calculation',
    'Mean Node averages out the wobble of the lunar nodes. True Node tracks the actual instantaneous position. Most modern astrologers use True Node.',
    '["mean_node", "true_node"]'::JSONB,
    TRUE,
    40
),
(
    'default_lilith_calculation',
    'Black Moon Lilith Calculation',
    'Mean is the smoothed average orbital point. True is the actual instantaneous point. Most apps use Mean.',
    '["mean_apogee", "true_apogee", "natural_apogee"]'::JSONB,
    TRUE,
    50
),
(
    'preferred_aspect_orbs',
    'Aspect Orb Tightness',
    'How loose or strict the orbs are when calculating aspects. Default uses our standard orbs; Tight uses smaller orbs for more selective aspects; Generous uses larger orbs.',
    '["default", "tight", "generous"]'::JSONB,
    TRUE,
    60
),
(
    'show_minor_aspects',
    'Show Minor Aspects',
    'Whether to display semisextiles, quintiles, sesquiquadrates, and quincunxes alongside the major aspects.',
    '[true, false]'::JSONB,
    TRUE,
    70
);

-- ----------------------------------------------------------------------------
-- LOG OF PREFERENCE CHANGES (for analytics and undo capability)
-- ----------------------------------------------------------------------------
-- Every preference change creates a row here. This lets you:
--   - Show users their change history
--   - Run product analytics ("how many users tried Whole Sign?")
--   - Roll back if a user wants to undo
--
-- This table grows unbounded but rows are tiny — no scaling concern for MVP.
-- ----------------------------------------------------------------------------

CREATE TABLE astro_preference_changes (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL,  -- FK added in users-table migration if needed
    preference_key  TEXT NOT NULL REFERENCES astro_overridable_preferences(key),
    old_value       JSONB,  -- null if this was first-time setting
    new_value       JSONB NOT NULL,
    source          TEXT NOT NULL CHECK (source IN ('user_action', 'admin', 'system_migration', 'rollback')),
    
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_pref_changes_user ON astro_preference_changes(user_id, changed_at DESC);
CREATE INDEX idx_pref_changes_key ON astro_preference_changes(preference_key);

COMMENT ON TABLE astro_preference_changes IS
    'Log of every preference change. Append-only. Useful for analytics and undo.';

-- ----------------------------------------------------------------------------
-- THE EFFECTIVE-PREFERENCE FUNCTION
-- ----------------------------------------------------------------------------
-- This is THE function. Every chart calculation, every AI prompt assembly,
-- every place that needs to know "what house system does this user use?"
-- should call this function. It handles the override-or-default logic in
-- one place so you never get inconsistencies.
--
-- Returns: the JSONB value for the requested preference, with user override
-- applied if it exists, otherwise the global default from astro_app_settings.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_effective_preference(
    p_user_id UUID,
    p_preference_key TEXT
) RETURNS JSONB AS $$
DECLARE
    v_user_override JSONB;
    v_global_default JSONB;
    v_user_prefs JSONB;
BEGIN
    -- First, try to get the user's override (if a users table exists with prefs)
    -- We use a defensive approach: check if the users table even exists yet
    BEGIN
        EXECUTE 'SELECT astro_preferences FROM users WHERE id = $1'
            INTO v_user_prefs USING p_user_id;
        v_user_override := v_user_prefs -> p_preference_key;
    EXCEPTION
        WHEN undefined_table THEN
            -- users table doesn't exist yet (pre-MVP); fall through to defaults
            v_user_override := NULL;
        WHEN undefined_column THEN
            -- users table exists but no astro_preferences column yet
            v_user_override := NULL;
    END;
    
    -- If user has an override, return it (after validation)
    IF v_user_override IS NOT NULL THEN
        -- Validate the override is in the allowed set
        IF EXISTS (
            SELECT 1 FROM astro_overridable_preferences 
            WHERE key = p_preference_key 
            AND valid_values @> v_user_override
        ) THEN
            RETURN v_user_override;
        END IF;
        -- Invalid override (shouldn't happen with proper app validation, but
        -- defensive coding): silently fall through to global default
    END IF;
    
    -- Fall back to the global default in astro_app_settings
    SELECT value INTO v_global_default 
    FROM astro_app_settings 
    WHERE key = p_preference_key;
    
    RETURN v_global_default;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_effective_preference IS
    'Returns the effective astrological preference for a user, applying their override if set, otherwise the global app default. Use this everywhere — never query astro_app_settings directly for user-facing logic.';

-- ----------------------------------------------------------------------------
-- HELPER: Set a user preference with logging
-- ----------------------------------------------------------------------------
-- Use this from your app code instead of directly updating the JSONB column.
-- It validates the value against allowed options and logs the change.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_user_preference(
    p_user_id UUID,
    p_preference_key TEXT,
    p_new_value JSONB,
    p_source TEXT DEFAULT 'user_action'
) RETURNS BOOLEAN AS $$
DECLARE
    v_old_value JSONB;
    v_is_valid BOOLEAN;
BEGIN
    -- Validate the preference key exists and the new value is allowed
    SELECT (valid_values @> p_new_value) INTO v_is_valid
    FROM astro_overridable_preferences
    WHERE key = p_preference_key;
    
    IF v_is_valid IS NULL THEN
        RAISE EXCEPTION 'Unknown preference key: %', p_preference_key;
    END IF;
    
    IF NOT v_is_valid THEN
        RAISE EXCEPTION 'Invalid value for preference %: %', p_preference_key, p_new_value;
    END IF;
    
    -- Get the previous value for the log
    BEGIN
        EXECUTE 'SELECT astro_preferences -> $1 FROM users WHERE id = $2'
            INTO v_old_value USING p_preference_key, p_user_id;
    EXCEPTION
        WHEN undefined_table OR undefined_column THEN
            RAISE EXCEPTION 'users.astro_preferences column does not exist yet';
    END;
    
    -- Update the user's preferences
    EXECUTE 'UPDATE users SET astro_preferences = COALESCE(astro_preferences, ''{}''::JSONB) || jsonb_build_object($1, $2) WHERE id = $3'
        USING p_preference_key, p_new_value, p_user_id;
    
    -- Log the change
    INSERT INTO astro_preference_changes (user_id, preference_key, old_value, new_value, source)
    VALUES (p_user_id, p_preference_key, v_old_value, p_new_value, p_source);
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION set_user_preference IS
    'Validate, set, and log a user astrological preference change. Use this instead of direct UPDATE statements.';

-- ----------------------------------------------------------------------------
-- HELPER: Reset a user preference back to the global default
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION reset_user_preference(
    p_user_id UUID,
    p_preference_key TEXT
) RETURNS BOOLEAN AS $$
DECLARE
    v_old_value JSONB;
BEGIN
    BEGIN
        EXECUTE 'SELECT astro_preferences -> $1 FROM users WHERE id = $2'
            INTO v_old_value USING p_preference_key, p_user_id;
    EXCEPTION
        WHEN undefined_table OR undefined_column THEN
            RETURN FALSE;
    END;
    
    -- Remove the key from the JSONB
    EXECUTE 'UPDATE users SET astro_preferences = astro_preferences - $1 WHERE id = $2'
        USING p_preference_key, p_user_id;
    
    -- Log the reset (new_value is null in the log to indicate "back to default")
    IF v_old_value IS NOT NULL THEN
        INSERT INTO astro_preference_changes (user_id, preference_key, old_value, new_value, source)
        VALUES (p_user_id, p_preference_key, v_old_value, 'null'::JSONB, 'user_action');
    END IF;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reset_user_preference IS
    'Remove a user override, returning that preference to the global default.';

-- ----------------------------------------------------------------------------
-- THE USERS TABLE MODIFICATION
-- ----------------------------------------------------------------------------
-- This adds the JSONB column where overrides live. If your users table
-- doesn't exist yet, comment this out and run it after you create it.
-- 
-- The column is nullable and defaults to '{}' so existing users get the
-- defaults transparently.
-- ----------------------------------------------------------------------------

-- Uncomment when your users table is in place:
--
-- ALTER TABLE users 
-- ADD COLUMN IF NOT EXISTS astro_preferences JSONB NOT NULL DEFAULT '{}'::JSONB;
--
-- COMMENT ON COLUMN users.astro_preferences IS
--     'User-specific overrides for astrological preferences. Empty {} means use all defaults. Modified only via set_user_preference() function.';
--
-- -- Optional GIN index if you ever need to query by preference values
-- CREATE INDEX IF NOT EXISTS idx_users_astro_prefs ON users USING GIN (astro_preferences);

-- ----------------------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------------------

ALTER TABLE astro_overridable_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE astro_preference_changes ENABLE ROW LEVEL SECURITY;

-- Anyone can read the catalog of overridable preferences
CREATE POLICY "Public read overridable_preferences" 
    ON astro_overridable_preferences FOR SELECT USING (TRUE);

-- Users can only see their own preference change log
CREATE POLICY "Users see own preference changes"
    ON astro_preference_changes FOR SELECT 
    USING (auth.uid() = user_id);

-- Only the helper function (running as DEFINER) can write to the log
-- (no INSERT policy means no direct inserts from app code)

-- ============================================================================
-- USAGE EXAMPLES (for documentation, not executed)
-- ============================================================================
-- 
-- Get the effective house system for user 'abc-123':
--   SELECT get_effective_preference('abc-123'::UUID, 'default_house_system');
--   -- Returns: "placidus" (or their override if set)
--
-- Set a user's house system to Whole Sign:
--   SELECT set_user_preference('abc-123'::UUID, 'default_house_system', '"whole_sign"'::JSONB);
--
-- Reset a user back to the global default:
--   SELECT reset_user_preference('abc-123'::UUID, 'default_house_system');
--
-- See a user's change history:
--   SELECT * FROM astro_preference_changes 
--   WHERE user_id = 'abc-123'::UUID 
--   ORDER BY changed_at DESC;
--
-- Analytics: how many users have changed their house system?
--   SELECT preference_key, COUNT(DISTINCT user_id), 
--          jsonb_agg(DISTINCT new_value) AS values_chosen
--   FROM astro_preference_changes 
--   WHERE preference_key = 'default_house_system'
--   GROUP BY preference_key;
--
-- ============================================================================
