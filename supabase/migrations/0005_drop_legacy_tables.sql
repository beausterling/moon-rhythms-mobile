-- Migration 0005 — destroy the legacy schema completely.
-- Beau authorized full destruction on 2026-05-15: "delete auth too, just start from scratch."
-- After this runs, there is no legacy data, no legacy auth user, no legacy trigger.
-- Next signup via the app will hit the new handle_new_user trigger from migration 0008.

-- 1. Remove the legacy signup trigger before its dependencies disappear.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

-- 2. Remove the legacy updated_at trigger and its function (the new schema
--    defines its own equivalent in migration 0006).
DROP TRIGGER IF EXISTS on_profile_updated ON public.profiles;
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;

-- 3. Drop legacy user-data tables (CASCADE catches any orphan FKs/policies).
DROP TABLE IF EXISTS public.readings CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 4. Wipe auth.users. Supabase's internal auth schema cascades through
--    auth.identities, auth.sessions, auth.refresh_tokens, etc.
DELETE FROM auth.users;
