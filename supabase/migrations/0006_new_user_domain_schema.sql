-- Migration 0006 — new user-domain schema.
-- 8 tables, helper functions, sync trigger, updated_at trigger, full RLS.
-- Per supabase_master_doc.md §3.2 and PHASE_1_HANDOFF.md §3.3.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. Generic updated_at trigger function (reused across every table that
--    has an updated_at column).
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- ============================================================================
-- 2. accounts — one per auth.users row.
-- ============================================================================
CREATE TABLE public.accounts (
    id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email               TEXT NOT NULL,
    first_name          TEXT NOT NULL,
    last_name           TEXT,
    plan_tier           TEXT NOT NULL DEFAULT 'free' CHECK (plan_tier IN ('free', 'paid')),
    astro_preferences   JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_accounts_plan_tier ON public.accounts(plan_tier);

CREATE TRIGGER accounts_set_updated_at
    BEFORE UPDATE ON public.accounts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 3. profiles — a person whose chart the account cares about.
--    One 'self' profile per account; additional 'other' profiles are paid-tier.
-- ============================================================================
CREATE TABLE public.profiles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    subject_type        TEXT NOT NULL CHECK (subject_type IN ('self', 'other')),
    display_name        TEXT NOT NULL,
    relationship_label  TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ
);

CREATE INDEX idx_profiles_account ON public.profiles(account_id) WHERE deleted_at IS NULL;

-- Exactly one self profile per account (excluding soft-deleted).
CREATE UNIQUE INDEX idx_profiles_one_self_per_account
    ON public.profiles(account_id)
    WHERE subject_type = 'self' AND deleted_at IS NULL;

CREATE TRIGGER profiles_set_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 4. birth_data — raw inputs attached 1:1 to a profile.
-- ============================================================================
CREATE TABLE public.birth_data (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id              UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    birth_date              DATE NOT NULL,
    birth_time              TIME,
    birth_time_known        BOOLEAN NOT NULL DEFAULT TRUE,
    birth_time_confidence   TEXT NOT NULL DEFAULT 'exact' CHECK (birth_time_confidence IN ('exact', 'approximate', 'unknown')),
    birth_location_label    TEXT NOT NULL,
    birth_latitude          NUMERIC(10, 7) NOT NULL,
    birth_longitude         NUMERIC(10, 7) NOT NULL,
    birth_timezone          TEXT NOT NULL,
    utc_offset_minutes      INTEGER NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER birth_data_set_updated_at
    BEFORE UPDATE ON public.birth_data
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 5. charts — calculated chart JSONB, 1:1 with profile.
-- ============================================================================
CREATE TABLE public.charts (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id              UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    chart_data              JSONB NOT NULL,
    zodiac_system           TEXT NOT NULL DEFAULT 'tropical',
    house_system            TEXT NOT NULL DEFAULT 'placidus',
    calculation_engine      TEXT NOT NULL DEFAULT 'moshier-ephemeris',
    calculation_version     TEXT NOT NULL DEFAULT 'v1',
    has_houses              BOOLEAN NOT NULL DEFAULT TRUE,
    calculated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_charts_profile  ON public.charts(profile_id);
CREATE INDEX idx_charts_data_gin ON public.charts USING GIN (chart_data jsonb_path_ops);

CREATE TRIGGER charts_set_updated_at
    BEFORE UPDATE ON public.charts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 6. profile_summaries — AI-synthesized text per profile, regenerated by job.
-- ============================================================================
CREATE TABLE public.profile_summaries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id          UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    summary_text        TEXT NOT NULL,
    summary_structured  JSONB,
    prompt_version      TEXT NOT NULL,
    model_used          TEXT NOT NULL,
    generated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_summaries_profile        ON public.profile_summaries(profile_id);
CREATE INDEX idx_profile_summaries_prompt_version ON public.profile_summaries(prompt_version);

CREATE TRIGGER profile_summaries_set_updated_at
    BEFORE UPDATE ON public.profile_summaries
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 7. relationships — links two profiles owned by the same account.
--    MVP convention: profile_a is the self profile; profile_b is the 'other'.
-- ============================================================================
CREATE TABLE public.relationships (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    profile_a_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    profile_b_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    relationship_label  TEXT NOT NULL,
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    CHECK (profile_a_id != profile_b_id)
);

CREATE INDEX idx_relationships_account   ON public.relationships(account_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_relationships_profile_a ON public.relationships(profile_a_id);
CREATE INDEX idx_relationships_profile_b ON public.relationships(profile_b_id);

CREATE TRIGGER relationships_set_updated_at
    BEFORE UPDATE ON public.relationships
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 8. relationship_summaries — AI synastry summary per relationship.
-- ============================================================================
CREATE TABLE public.relationship_summaries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relationship_id     UUID NOT NULL UNIQUE REFERENCES public.relationships(id) ON DELETE CASCADE,
    summary_text        TEXT NOT NULL,
    summary_structured  JSONB,
    prompt_version      TEXT NOT NULL,
    model_used          TEXT NOT NULL,
    generated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_relationship_summaries_relationship   ON public.relationship_summaries(relationship_id);
CREATE INDEX idx_relationship_summaries_prompt_version ON public.relationship_summaries(prompt_version);

CREATE TRIGGER relationship_summaries_set_updated_at
    BEFORE UPDATE ON public.relationship_summaries
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 9. subscriptions — synced from RevenueCat / IAP webhooks.
-- ============================================================================
CREATE TABLE public.subscriptions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id              UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    status                  TEXT NOT NULL CHECK (status IN ('trial', 'active', 'expired', 'cancelled', 'grace_period')),
    product_id              TEXT NOT NULL,
    source                  TEXT NOT NULL CHECK (source IN ('apple', 'google', 'stripe', 'admin')),
    external_id             TEXT NOT NULL,
    started_at              TIMESTAMPTZ NOT NULL,
    expires_at              TIMESTAMPTZ,
    cancelled_at            TIMESTAMPTZ,
    raw_webhook_payload     JSONB,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (source, external_id)
);

CREATE INDEX idx_subscriptions_account ON public.subscriptions(account_id);
CREATE INDEX idx_subscriptions_status  ON public.subscriptions(status);

CREATE TRIGGER subscriptions_set_updated_at
    BEFORE UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 10. plan_tier sync trigger — keep accounts.plan_tier in sync with subs status.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.sync_account_plan_tier()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.accounts
    SET plan_tier = CASE
        WHEN NEW.status IN ('trial', 'active', 'grace_period') THEN 'paid'
        ELSE 'free'
    END,
    updated_at = NOW()
    WHERE id = NEW.account_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_sync_account_plan_tier
    AFTER INSERT OR UPDATE ON public.subscriptions
    FOR EACH ROW EXECUTE FUNCTION public.sync_account_plan_tier();

-- ============================================================================
-- 11. Ownership helper functions.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.user_owns_profile(p_profile_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = p_profile_id
          AND account_id = auth.uid()
          AND deleted_at IS NULL
    );
$$;

CREATE OR REPLACE FUNCTION public.user_owns_relationship(p_relationship_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.relationships
        WHERE id = p_relationship_id
          AND account_id = auth.uid()
          AND deleted_at IS NULL
    );
$$;

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.accounts                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.birth_data               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.charts                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_summaries        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationships            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.relationship_summaries   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions            ENABLE ROW LEVEL SECURITY;

-- accounts -------------------------------------------------------------------
CREATE POLICY "Users read own account"   ON public.accounts FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users insert own account" ON public.accounts FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own account" ON public.accounts FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users delete own account" ON public.accounts FOR DELETE USING (auth.uid() = id);

-- profiles -------------------------------------------------------------------
CREATE POLICY "Users read own profiles"   ON public.profiles FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own profiles" ON public.profiles FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own profiles" ON public.profiles FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own profiles" ON public.profiles FOR DELETE USING (account_id = auth.uid());

-- birth_data -----------------------------------------------------------------
CREATE POLICY "Users read own birth_data"   ON public.birth_data FOR SELECT USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own birth_data" ON public.birth_data FOR INSERT WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own birth_data" ON public.birth_data FOR UPDATE USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users delete own birth_data" ON public.birth_data FOR DELETE USING (public.user_owns_profile(profile_id));

-- charts ---------------------------------------------------------------------
-- Option I (per PHASE_1_MIGRATION_PLAN.md §4.2): user-authenticated writes
-- are allowed, gated by user_owns_profile(). This matches existing web
-- /api/save-reading behavior and avoids needing edge functions for Phase 1.
-- Revisit in Phase 2 when summary synthesis lands and chart writes can move
-- to service-role-only.
CREATE POLICY "Users read own charts"   ON public.charts FOR SELECT USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own charts" ON public.charts FOR INSERT WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own charts" ON public.charts FOR UPDATE USING (public.user_owns_profile(profile_id));
-- No DELETE: charts are overwritten via UPSERT, never deleted by users.

-- profile_summaries ----------------------------------------------------------
CREATE POLICY "Users read own profile_summaries" ON public.profile_summaries
    FOR SELECT USING (public.user_owns_profile(profile_id));
-- Writes service-role only (synthesized by edge function).

-- relationships --------------------------------------------------------------
CREATE POLICY "Users read own relationships"   ON public.relationships FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own relationships" ON public.relationships FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own relationships" ON public.relationships FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own relationships" ON public.relationships FOR DELETE USING (account_id = auth.uid());

-- relationship_summaries -----------------------------------------------------
CREATE POLICY "Users read own relationship_summaries" ON public.relationship_summaries
    FOR SELECT USING (public.user_owns_relationship(relationship_id));
-- Writes service-role only.

-- subscriptions --------------------------------------------------------------
CREATE POLICY "Users read own subscriptions" ON public.subscriptions
    FOR SELECT USING (account_id = auth.uid());
-- Writes service-role only (synced from webhooks).
