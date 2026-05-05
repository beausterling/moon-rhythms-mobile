# Supabase Migration Plan

Purpose: keep Moon Rhythms Mobile organized so every feature can move cleanly into Supabase without rewriting screens later.

## Rules

1. Screens never call Supabase directly.
   - Screens call feature services/hooks.
   - Feature services call `lib/db/*` or `lib/api.ts`.
2. Every persisted object gets a TypeScript type first.
   - Add/modify types in `lib/db/schema.ts` before wiring UI.
3. Every table change gets a SQL migration.
   - Store migrations in `supabase/migrations/`.
   - Never rely on dashboard-only schema changes.
4. Client-generated records use stable UUIDs.
   - Enables offline creation + later sync without duplicates.
5. User-owned rows include `user_id` and RLS policies.
   - Mobile app uses the anon key; service-role writes stay server-side only.
6. Offline-capable features write to local cache first, then sync.
   - Quizzes and readings should work offline and reconcile when network returns.

## Proposed Data Domains

### `profiles`
User profile data connected to `auth.users`.

### `birth_readings`
Saved natal / Human Design readings.

### `quiz_results`
Saved MBTI, Big Five, Enneagram, and DISC results.

### `notification_preferences`
Moon sign notification toggles and scheduling preferences.

### `sync_queue` (local-only first)
Local queue for offline writes waiting to sync. This should live in SQLite/AsyncStorage initially, not Supabase.

## App Layering

```txt
app/                 Expo Router screens only
components/          Reusable presentation components
features/            Feature-specific hooks, services, and UI glue
lib/api.ts           HTTP calls to moonrhythms.io API routes
lib/db/schema.ts     Canonical TypeScript persistence types
lib/db/client.ts     Supabase re-export / DB helper boundary
lib/db/*.ts          Database access functions by domain
supabase/migrations/ SQL schema history
```

## Migration Sequence

1. Keep using existing moonrhythms.io API routes for calculations.
2. Add typed DB access modules in `lib/db/` as features need persistence.
3. Mirror the desired schema in SQL migrations.
4. Test mobile auth against Supabase RLS locally/with dev project.
5. Once stable, generate Supabase types and replace hand-written DB row types if desired.

## Current Decision

Mobile remains a thin client:
- Astronomical calculations stay server-side.
- Supabase stores user-owned readings, quiz results, preferences, and profile data.
- Auth sessions persist through `expo-sqlite/localStorage/install`.
