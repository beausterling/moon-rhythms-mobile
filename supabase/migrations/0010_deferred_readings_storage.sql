-- ============================================================================
-- 0010_deferred_readings_storage
--
-- Promotes three of the §7 "Scaffolded futures" reading types from MVP-deferred
-- to first-class persisted readings. Each gets its own typed table mirroring
-- the `charts` table pattern (one row per profile, JSONB blob, upsert on
-- profile_id). Web `/api/save-reading.api.js` previously no-op'd these types
-- (lines 46–49) and `/api/readings.api.js` returned [] for them; this migration
-- gives those endpoints a place to write/read.
--
-- Future expansion paths (zero data migration required):
--   1. Interpretation embeddings: add `*_interpretations(reading_id, embedding,
--      content, ...)` tables that FK these reading rows 1:1.
--   2. Typed indexable columns: add e.g. `life_path int` / `type text` columns,
--      backfill from JSONB. Existing JSON-based readers untouched.
--   3. History: drop UNIQUE(profile_id), add calculated_at index.
--
-- Tables added:
--   - chinese_zodiac_readings (stable JSONB output)
--   - human_design_readings   (JSONB + calculation_version, since natalengine
--                              output was in flux during early 2026-04)
--   - numerology_readings     (stable JSONB output)
--
-- RLS pattern follows `charts` exactly (Option I from PHASE_1_MIGRATION_PLAN
-- §4.2): user-gated INSERT/UPDATE via public.user_owns_profile(). No DELETE
-- (rows are overwritten via UPSERT, never deleted by users).
-- ============================================================================

-- ============================================================================
-- chinese_zodiac_readings
-- ============================================================================
CREATE TABLE public.chinese_zodiac_readings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    data                JSONB NOT NULL,
    calculation_engine  TEXT NOT NULL DEFAULT 'lunar-javascript',
    calculation_version TEXT NOT NULL DEFAULT 'v1',
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chinese_zodiac_readings_profile  ON public.chinese_zodiac_readings(profile_id);
CREATE INDEX idx_chinese_zodiac_readings_data_gin ON public.chinese_zodiac_readings USING GIN (data jsonb_path_ops);

CREATE TRIGGER chinese_zodiac_readings_set_updated_at
    BEFORE UPDATE ON public.chinese_zodiac_readings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.chinese_zodiac_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own chinese_zodiac_readings"
    ON public.chinese_zodiac_readings FOR SELECT
    USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own chinese_zodiac_readings"
    ON public.chinese_zodiac_readings FOR INSERT
    WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own chinese_zodiac_readings"
    ON public.chinese_zodiac_readings FOR UPDATE
    USING (public.user_owns_profile(profile_id));
-- No DELETE: rows are overwritten via UPSERT.

-- ============================================================================
-- human_design_readings
--   `calculation_version` is meaningful here — natalengine output drifted
--   during 2026-04 development. Lets future readers branch on shape.
-- ============================================================================
CREATE TABLE public.human_design_readings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    data                JSONB NOT NULL,
    calculation_engine  TEXT NOT NULL DEFAULT 'natalengine',
    calculation_version TEXT NOT NULL DEFAULT 'v1',
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_human_design_readings_profile  ON public.human_design_readings(profile_id);
CREATE INDEX idx_human_design_readings_data_gin ON public.human_design_readings USING GIN (data jsonb_path_ops);

CREATE TRIGGER human_design_readings_set_updated_at
    BEFORE UPDATE ON public.human_design_readings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.human_design_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own human_design_readings"
    ON public.human_design_readings FOR SELECT
    USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own human_design_readings"
    ON public.human_design_readings FOR INSERT
    WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own human_design_readings"
    ON public.human_design_readings FOR UPDATE
    USING (public.user_owns_profile(profile_id));

-- ============================================================================
-- numerology_readings
-- ============================================================================
CREATE TABLE public.numerology_readings (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    data                JSONB NOT NULL,
    calculation_engine  TEXT NOT NULL DEFAULT 'pythagorean',
    calculation_version TEXT NOT NULL DEFAULT 'v1',
    calculated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_numerology_readings_profile  ON public.numerology_readings(profile_id);
CREATE INDEX idx_numerology_readings_data_gin ON public.numerology_readings USING GIN (data jsonb_path_ops);

CREATE TRIGGER numerology_readings_set_updated_at
    BEFORE UPDATE ON public.numerology_readings
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.numerology_readings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own numerology_readings"
    ON public.numerology_readings FOR SELECT
    USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own numerology_readings"
    ON public.numerology_readings FOR INSERT
    WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own numerology_readings"
    ON public.numerology_readings FOR UPDATE
    USING (public.user_owns_profile(profile_id));
