-- Migration 0008 — new auth signup trigger.
-- On INSERT into auth.users, create one accounts row AND one self profile row.
-- SECURITY DEFINER so it can write to public.* under the row-owner's identity.
-- The empty display_name + first_name placeholders are filled by onboarding via /api/profile PUT.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_first_name TEXT;
BEGIN
    -- raw_user_meta_data may carry a first_name from OAuth providers
    -- (Google, Apple). Fallback to '' so NOT NULL holds; onboarding overwrites.
    v_first_name := COALESCE(NEW.raw_user_meta_data ->> 'first_name', '');

    INSERT INTO public.accounts (
        id, email, first_name, plan_tier, astro_preferences,
        created_at, updated_at
    )
    VALUES (
        NEW.id,
        NEW.email,
        v_first_name,
        'free',
        '{}'::jsonb,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.profiles (
        id, account_id, subject_type, display_name, relationship_label,
        created_at, updated_at
    )
    VALUES (
        gen_random_uuid(),
        NEW.id,
        'self',
        v_first_name,
        NULL,
        NOW(),
        NOW()
    );
    -- No ON CONFLICT: the partial unique index
    --   (account_id) WHERE subject_type='self' AND deleted_at IS NULL
    -- should hard-fail on a duplicate trigger fire so we see it in logs
    -- rather than silently skipping.

    RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
