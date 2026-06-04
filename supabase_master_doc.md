# Moon Rhythms — Supabase Backend Architecture (Master Document)

**Version:** v1.0  
**Last updated:** 2026-04-29  
**For:** Claude Code (and any future engineering collaborator)  
**Supersedes:** Database sections of earlier `master-build-doc.md`. The earlier document remains valid for product strategy, voice rules, and phase planning. THIS document is the authoritative reference for the database, schema, and AI assembly.

---

## How to use this document

Read this entire document before writing any SQL, edge functions, or schema migrations. It's organized as:

1. **The product context** — what we're building and why
2. **The architectural principles** — the rules that everything else follows from
3. **The complete schema** — every table, every column, every relationship
4. **The AI assembly pipeline** — how data flows when a user chats with the AI
5. **The implementation plan** — phase-by-phase build order
6. **Decisions made** — locked-in choices with reasoning
7. **Scaffolded futures** — features we're NOT building, but the schema accommodates

If anything in this document conflicts with `master-build-doc.md` or `CLAUDE.md` files in either repo, **this document wins for database/backend concerns**. Flag the conflict to Beau so the older doc can be updated.

---

## 1. Product context

Moon Rhythms is a mobile-first astrology app focused on **moon signs, self-awareness, and relationships**. The commercial moat is the relationship-astrology angle: helping users understand themselves and one other person (a partner, parent, friend) through their charts and an AI advisor.

**MVP definition:** Solo + Relationship Light.

- Solo: user signs up → enters birth data → sees their natal chart → chats with the AI about themselves
- Relationship Light: paid users can add one or more partner profiles. The partner does not need to consent or join. The AI advisor uses both charts to advise the user about that relationship.

**Out of MVP scope (do not build):** invited partner mode (where the partner actually joins), group chats, transit notifications, quizzes, composite charts, daily check-ins, proactive AI messages. _(Human Design, numerology, and Chinese zodiac were originally in this list but have since been BUILT — storage live as of migration 0010, 2026-05-16. See §7.)_

**Out of MVP scope but scaffolded:** the schema includes documented future-table shapes for the still-deferred features so they can be added cleanly later. Do not create empty tables for these — just understand they're coming and don't design choices that would make them harder later. _(Some originally-scaffolded features — Human Design, numerology, Chinese zodiac — have since been built; see §7 for their live shapes.)_

**Tech stack:**

- **Mobile:** React Native via Expo SDK 54 (managed workflow), Expo Router, NativeWind v4, TypeScript strict
- **Web:** Next.js (existing at moonrhythms.io)
- **Database:** Supabase shared between mobile and web
- **Calculations:** Already exists as web API endpoints. The web app uses `ephemeris` (Moshier Swiss Ephemeris pure JS), `circular-natal-horoscope-js` (houses/aspects with custom orbs), and `natalengine` (Human Design, deferred). Mobile calls these endpoints rather than reinventing.
- **Auth:** Supabase Auth (email/password + Google + Apple)
- **LLM:** Claude (Anthropic) for both summary synthesis and chat responses. Use `claude-opus-4-7` for synthesis (one-time, quality-critical), `claude-sonnet-4-6` for chat (frequent, cost-conscious).
- **Embeddings:** OpenAI `text-embedding-3-small` (1536 dimensions)
- **Vector DB:** pgvector extension in Supabase Postgres (no separate service)

---

## 2. Architectural principles

These rules govern every design decision below. If you find yourself wanting to violate one, stop and ask Beau.

### 2.1 Separation of concerns: three data domains

The database has three conceptually distinct domains. Don't mix them.

- **User domain:** accounts, profiles (the people users care about), birth data, charts, AI-generated summaries
- **Knowledge domain:** astrological reference data (deterministic facts) and interpretive content (RAG chunks)
- **Interaction domain:** chat sessions, chat messages, AI response logs, citations

A query that needs to join across all three is a sign you're building something the architecture didn't anticipate. Stop and check.

### 2.2 Deterministic vs interpretive: the AI never invents astrology

The AI never decides what astrological facts mean from scratch. It reads structured truth (Saturn rules Capricorn, Aries is fire, this user has Moon in Cancer at 8°) from deterministic tables, and pulls interpretive context from curated knowledge chunks. Its job is to combine these into a personalized, conversational response — not to generate astrology from its training data.

This is why we have both `astro_*` tables (the spine of reference facts) and `knowledge_chunks` (the interpretive corpus). Both layers are essential. Don't skip either.

### 2.3 Pre-synthesize once, retrieve forever

Computation that produces stable text (a user's astrological/psychological summary, a relationship's synastry summary) happens ONCE at creation time. It's stored as text. Every subsequent AI call reads it as cached context.

Re-synthesis happens only when:
- The user's underlying data changes (rare — birth data is essentially fixed)
- The synthesis prompt or model is intentionally upgraded (handled via background job, see Section 4.7)

Never regenerate a summary inside a chat request. Never send raw chart JSON to a chat-time LLM call.

### 2.4 JSONB for calculated chart data; columns for things you query

The full output of Swiss Ephemeris lives in a JSONB column. Don't normalize planets, houses, and aspects into separate tables. If you ever need cross-user queries on chart data ("all users with Moon in Cancer"), Postgres can query JSONB efficiently with GIN indexes — fast enough for any analytics use case at MVP scale.

Columns are for things accessed frequently in joins or used as foreign keys (profile_id, account_id, plan_tier, etc.). JSONB is for shaped data you read whole.

### 2.5 Single calculation source for MVP

The web API at `moonrhythms.io/api/` already calculates charts via Moshier Swiss Ephemeris. The mobile app calls these endpoints. We do not build a second calculation path. Calculations are stable; the calculation engine and version are recorded with each chart for future-proofing, but there is only one source.

### 2.6 RLS is non-negotiable

Every user-data table has Row Level Security enabled and explicit policies. Reference tables (`astro_*`, `knowledge_chunks`) have RLS too — they're publicly readable but writes are service-role-only.

Default-deny is safer than default-allow. If a table doesn't have an explicit policy for an operation, that operation should fail.

### 2.7 Cost discipline

We're pre-revenue. Every LLM call is real money.

- Default to `claude-sonnet-4-6` for chat
- Use `claude-opus-4-7` only for one-time synthesis (summaries) and the most quality-critical moments
- Pre-synthesize aggressively. A summary written once and reused across thousands of chat calls is dramatically cheaper than reading raw chart JSON every message.
- Every LLM call gets logged to `ai_responses` with token count, model, and cost. This is non-negotiable. Without it we're flying blind on unit economics.

### 2.8 No premature normalization

The MVP schema is intentionally small. Tables for features we're not building (transits, quizzes, notifications) are documented in Section 7 but not created. Don't create empty tables. They add migration weight, complicate RLS thinking, and create false expectations. _(Human Design, numerology, and Chinese zodiac were once in this "not created" list but have since been built — migration 0010, 2026-05-16. The rule still holds for the remaining deferred features.)_

---

## 3. The complete schema

This is every table that gets built for MVP. Twelve tables, plus the existing `astro_*` deterministic spine (already designed in earlier artifacts, deploy unchanged).

### 3.1 Schema overview

```
DETERMINISTIC SPINE (already designed, deploy via prior migrations)
  astro_planets, astro_signs, astro_houses, astro_aspects,
  astro_dignities, astro_decans, astro_lunar_phases,
  astro_elements, astro_modalities, astro_house_systems,
  astro_app_settings, astro_synastry_patterns,
  astro_moon_compatibility, astro_transit_significance,
  astro_points
  + astro_overridable_preferences, astro_preference_changes
    (user override capability — deploy but no UI surfaces it for MVP)

USER DOMAIN (MVP builds these)
  accounts                  account-level data, plan tier, settings
  profiles                  a person (self or other) the user cares about
  birth_data                raw birth inputs attached to a profile
  charts                    calculated chart JSONB per profile
  profile_summaries         AI-synthesized text per profile
  relationships             link between two profiles
  relationship_summaries    AI-synthesized synastry text
  subscriptions             paid status synced from RevenueCat/IAP

KNOWLEDGE DOMAIN (MVP builds the chunks table; corpus is incrementally loaded)
  knowledge_chunks          interpretive content with pgvector embeddings

INTERACTION DOMAIN (MVP builds these)
  chat_sessions             a conversation thread
  chat_messages             individual messages in a session
  ai_responses              logging + citations for AI generations
```

Twelve user-facing tables. That's the entire MVP schema.

### 3.2 User domain tables (detailed)

#### `public.accounts`

The application-level account record. Mirrors `auth.users` for app-specific fields. **There is one account per Supabase auth user.**

```sql
CREATE TABLE public.accounts (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT NOT NULL,
    first_name      TEXT NOT NULL,
    last_name       TEXT,
    plan_tier       TEXT NOT NULL DEFAULT 'free' CHECK (plan_tier IN ('free', 'paid')),
    astro_preferences JSONB NOT NULL DEFAULT '{}'::JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_accounts_plan_tier ON public.accounts(plan_tier);
```

**Notes:**
- `plan_tier` is the source of truth for free vs paid. Synced from `subscriptions` table via trigger or webhook handler.
- `astro_preferences` JSONB is for the user override system. Empty `{}` for all MVP users; never surfaced in UI.
- `deleted_at` is for soft-delete (App Store / GDPR compliance). Hard-delete jobs run after a grace period.

#### `public.profiles`

A person whose chart the user cares about. The account owner is themselves a profile (their "self" profile). Partners, parents, etc. are additional profiles owned by the same account.

```sql
CREATE TABLE public.profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    subject_type    TEXT NOT NULL CHECK (subject_type IN ('self', 'other')),
    display_name    TEXT NOT NULL,
    relationship_label TEXT,  -- 'partner', 'mom', 'friend', etc. NULL for self.
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_profiles_account ON public.profiles(account_id) WHERE deleted_at IS NULL;
CREATE UNIQUE INDEX idx_profiles_one_self_per_account 
  ON public.profiles(account_id) 
  WHERE subject_type = 'self' AND deleted_at IS NULL;
```

**Notes:**
- Each account has exactly ONE `self` profile (enforced by unique index).
- Free users can create only the `self` profile. Paid users can create additional `other` profiles. Enforce in application logic AND RLS.
- The original paying user owns all profile data they enter, full stop. If the partner ever signs up for their own account, they create a separate independent account with no link to existing profile data. (No claiming/transfer in MVP.)

#### `public.birth_data`

Raw birth inputs attached to a profile. Separated from `charts` because birth data is *input*, chart is *output*. If we ever recalculate (better engine, different config), we keep birth_data stable.

```sql
CREATE TABLE public.birth_data (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    birth_date      DATE NOT NULL,
    birth_time      TIME,                              -- NULL if time unknown
    birth_time_known BOOLEAN NOT NULL DEFAULT TRUE,
    birth_time_confidence TEXT NOT NULL DEFAULT 'exact' 
      CHECK (birth_time_confidence IN ('exact', 'approximate', 'unknown')),
    birth_location_label TEXT NOT NULL,                -- 'Portland, Oregon, USA'
    birth_latitude  NUMERIC(10, 7) NOT NULL,
    birth_longitude NUMERIC(10, 7) NOT NULL,
    birth_timezone  TEXT NOT NULL,                     -- IANA timezone, e.g. 'America/Los_Angeles'
    utc_offset_minutes INTEGER NOT NULL,               -- computed at birth moment
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

**Notes:**
- `UNIQUE` on `profile_id`: one set of birth data per profile.
- When `birth_time_known = false`, downstream chart calculation skips house cusps and ascendant/midheaven. The chart record will reflect this.
- The web app already has a flow for unknown-birth-time. Mobile should match it.

#### `public.charts`

The calculated chart for a profile. JSONB-first per architectural principle 2.4.

```sql
CREATE TABLE public.charts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- The actual chart data
    chart_data      JSONB NOT NULL,
    
    -- Configuration captured at calculation time
    zodiac_system   TEXT NOT NULL DEFAULT 'tropical',
    house_system    TEXT NOT NULL DEFAULT 'placidus',
    calculation_engine TEXT NOT NULL DEFAULT 'moshier-ephemeris',
    calculation_version TEXT NOT NULL DEFAULT 'v1',
    has_houses      BOOLEAN NOT NULL DEFAULT TRUE,     -- FALSE if birth time unknown
    
    -- Timestamps
    calculated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_charts_profile ON public.charts(profile_id);

-- GIN index for JSONB queries (e.g., 'all profiles with Moon in Cancer')
CREATE INDEX idx_charts_data_gin ON public.charts USING GIN (chart_data jsonb_path_ops);
```

**Notes:**
- `chart_data` JSONB shape mirrors what the web app's `/api/SwissEphemerisChart` returns. Keep it identical so web and mobile share the same downstream parsing logic.
- `has_houses = FALSE` is the signal to the AI synthesis prompt to avoid interpreting house placements or rising sign.
- We are NOT versioning chart calculations (per Q19 — single source for MVP). But we record the engine/version anyway for future-proofing.

#### `public.profile_summaries`

The AI-synthesized text describing a profile. **This is the key architectural piece for AI personalization** — generated once at chart creation, reused on every chat message.

```sql
CREATE TABLE public.profile_summaries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id      UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- The text
    summary_text    TEXT NOT NULL,
    summary_structured JSONB,                          -- Optional: structured sections for future UI display
    
    -- Provenance — critical for the regeneration system
    prompt_version  TEXT NOT NULL,                     -- 'v1', 'v2', etc.
    model_used      TEXT NOT NULL,                     -- 'claude-opus-4-7'
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profile_summaries_profile ON public.profile_summaries(profile_id);
CREATE INDEX idx_profile_summaries_prompt_version ON public.profile_summaries(prompt_version);
```

**Notes:**
- One summary per profile. Updated only when the underlying chart changes OR when a regeneration job runs.
- `summary_text` is the canonical version sent to the AI on every chat call. Free-form prose, brand-voice-modernized.
- `summary_structured` is optional and reserved for a future "Your Profile" UI feature (a polished user-visible artifact). For MVP, leave NULL — internal only.
- `prompt_version` is what powers the upgrade flow. When the synthesis prompt improves, bump the version and run the background regeneration job (see Section 4.7).

#### `public.relationships`

Links two profiles. For MVP: always between a `self` profile and an `other` profile owned by the same account.

```sql
CREATE TABLE public.relationships (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    
    -- The two profiles in this relationship
    profile_a_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    profile_b_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    
    -- Metadata
    relationship_label TEXT NOT NULL,                  -- 'romantic partner', 'parent', etc.
    notes           TEXT,                              -- user's own notes
    
    -- Timestamps
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    
    -- For MVP: enforce that profile_a is the account's self profile
    -- Application logic handles this; check constraint as defense in depth
    CHECK (profile_a_id != profile_b_id)
);

CREATE INDEX idx_relationships_account ON public.relationships(account_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_relationships_profile_a ON public.relationships(profile_a_id);
CREATE INDEX idx_relationships_profile_b ON public.relationships(profile_b_id);
```

**Notes:**
- MVP convention: `profile_a_id` is always the account's `self` profile. `profile_b_id` is the `other` profile. Enforce in application code.
- Relationships are gated to paid users — enforce in application logic before insert.

#### `public.relationship_summaries`

Same pattern as `profile_summaries` but for the synastry analysis between two profiles in a relationship.

```sql
CREATE TABLE public.relationship_summaries (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    relationship_id UUID NOT NULL UNIQUE REFERENCES public.relationships(id) ON DELETE CASCADE,
    
    summary_text    TEXT NOT NULL,
    summary_structured JSONB,
    
    prompt_version  TEXT NOT NULL,
    model_used      TEXT NOT NULL,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_relationship_summaries_relationship ON public.relationship_summaries(relationship_id);
CREATE INDEX idx_relationship_summaries_prompt_version ON public.relationship_summaries(prompt_version);
```

#### `public.subscriptions`

Subscription state synced from RevenueCat or App Store IAP webhooks. Source of truth for `accounts.plan_tier`.

```sql
CREATE TABLE public.subscriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    
    status          TEXT NOT NULL CHECK (status IN ('trial', 'active', 'expired', 'cancelled', 'grace_period')),
    product_id      TEXT NOT NULL,                     -- the SKU
    source          TEXT NOT NULL CHECK (source IN ('apple', 'google', 'stripe', 'admin')),
    external_id     TEXT NOT NULL,                     -- RevenueCat customer/subscription ID
    
    started_at      TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    cancelled_at   TIMESTAMPTZ,
    
    raw_webhook_payload JSONB,                         -- last webhook payload for debugging
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    UNIQUE (source, external_id)
);

CREATE INDEX idx_subscriptions_account ON public.subscriptions(account_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
```

**Trigger:** On INSERT or UPDATE of `subscriptions`, sync the corresponding `accounts.plan_tier`:

```sql
CREATE OR REPLACE FUNCTION sync_account_plan_tier()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_sync_account_plan_tier
AFTER INSERT OR UPDATE ON public.subscriptions
FOR EACH ROW EXECUTE FUNCTION sync_account_plan_tier();
```

### 3.3 Knowledge domain tables

#### `public.knowledge_chunks`

The interpretive content corpus. Each row is a curated chunk of astrological interpretation (e.g., "planet_mars_nature", "house_07_partnership"). Retrieved at chat time via pgvector cosine similarity.

```sql
-- Ensure pgvector is enabled
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE public.knowledge_chunks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_key       TEXT NOT NULL UNIQUE,              -- 'planet_mars_nature'
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    embedding       VECTOR(1536),                      -- OpenAI text-embedding-3-small
    
    -- Metadata
    source_ref      TEXT NOT NULL,                     -- 'Sepharial, 1920, Ch. I'
    keywords        TEXT[] NOT NULL DEFAULT '{}',
    chunk_category  TEXT NOT NULL CHECK (chunk_category IN (
        'planet', 'sign', 'house', 'aspect', 'framework', 'synastry'
    )),
    prompt_version  TEXT NOT NULL,                     -- 'voice_modernization_v1'
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_knowledge_chunks_category ON public.knowledge_chunks(chunk_category);
CREATE INDEX idx_knowledge_chunks_keywords ON public.knowledge_chunks USING GIN (keywords);

-- HNSW index for fast cosine similarity search
CREATE INDEX idx_knowledge_chunks_embedding 
  ON public.knowledge_chunks USING hnsw (embedding vector_cosine_ops);
```

**RPC function for retrieval:**

```sql
CREATE OR REPLACE FUNCTION match_knowledge_chunks(
    query_embedding VECTOR(1536),
    match_threshold FLOAT DEFAULT 0.7,
    match_count INT DEFAULT 5,
    filter_category TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    chunk_key TEXT,
    title TEXT,
    body TEXT,
    similarity FLOAT
) LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    SELECT 
        kc.id,
        kc.chunk_key,
        kc.title,
        kc.body,
        1 - (kc.embedding <=> query_embedding) AS similarity
    FROM public.knowledge_chunks kc
    WHERE 
        (filter_category IS NULL OR kc.chunk_category = filter_category)
        AND 1 - (kc.embedding <=> query_embedding) > match_threshold
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;
```

**Notes:**
- Initial seed: load the 31 chunks from `sepharial_chunks_v1.json` (already designed). Generate embeddings via OpenAI in a separate edge function run after the table exists.
- Future growth: incrementally add chunks from PD sources and (later) commissioned writing. Don't try to populate the entire corpus at MVP launch — 31 chunks is enough to validate the retrieval pattern works end-to-end.
- `prompt_version` lets us regenerate chunks later if we improve the voice modernization prompt.

### 3.4 Interaction domain tables

#### `public.chat_sessions`

A conversation thread. A session is either solo (chatting about yourself) or relationship (chatting about a relationship).

```sql
CREATE TABLE public.chat_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    
    session_type    TEXT NOT NULL CHECK (session_type IN ('solo', 'relationship')),
    
    -- Exactly one of these is set per session
    profile_id      UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    relationship_id UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    
    title           TEXT,                              -- optional, can be AI-generated from first message
    
    last_message_at TIMESTAMPTZ,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,
    
    CHECK (
        (session_type = 'solo' AND profile_id IS NOT NULL AND relationship_id IS NULL)
        OR
        (session_type = 'relationship' AND relationship_id IS NOT NULL AND profile_id IS NULL)
    )
);

CREATE INDEX idx_chat_sessions_account ON public.chat_sessions(account_id, last_message_at DESC) 
  WHERE deleted_at IS NULL;
CREATE INDEX idx_chat_sessions_profile ON public.chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_relationship ON public.chat_sessions(relationship_id);
```

#### `public.chat_messages`

Individual messages in a session. Append-only for MVP — no editing or deletion of individual messages.

```sql
CREATE TABLE public.chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    
    role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content         TEXT NOT NULL,
    
    -- For assistant messages: link to the ai_responses log row
    ai_response_id  UUID REFERENCES public.ai_responses(id) ON DELETE SET NULL,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_session ON public.chat_messages(session_id, created_at);
```

**Notes:**
- `role = 'system'` is reserved for future use (e.g., system messages that mark events like "user added a new relationship"). For MVP only 'user' and 'assistant' are written.

#### `public.ai_responses`

The logging table for every AI generation. **Non-negotiable per architectural principle 2.7** — without this we have no visibility into costs or what context drove a response.

```sql
CREATE TABLE public.ai_responses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    
    -- Context
    session_id      UUID REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
    
    -- The generation
    model_used      TEXT NOT NULL,                     -- 'claude-sonnet-4-6'
    prompt_version  TEXT NOT NULL,                     -- 'chat_v1'
    system_prompt   TEXT,                              -- the final assembled system prompt (truncated for storage; keep first ~2000 chars for debug)
    
    -- The retrieval context (denormalized snapshot for debugging)
    citations       JSONB NOT NULL DEFAULT '[]'::JSONB,  -- [{source: 'profile_summary', id: ...}, {source: 'knowledge_chunk', chunk_key: 'planet_mars_nature', similarity: 0.81}, ...]
    
    -- Cost tracking
    prompt_tokens   INTEGER NOT NULL,
    completion_tokens INTEGER NOT NULL,
    cost_cents      INTEGER NOT NULL,                  -- approximate, integer cents
    latency_ms      INTEGER NOT NULL,
    
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_responses_account ON public.ai_responses(account_id, created_at DESC);
CREATE INDEX idx_ai_responses_session ON public.ai_responses(session_id);
CREATE INDEX idx_ai_responses_model ON public.ai_responses(model_used);
```

**Notes:**
- `citations` JSONB is the structured record of what context the AI saw. Drives the "N insights" UI chip in chat: count items in this array, render that many tappable references.
- Storing the system_prompt (truncated) is for debugging. When a user reports a weird AI response, we can see exactly what context produced it.

### 3.5 RLS policies (every table)

```sql
-- ============================================================================
-- USER DOMAIN RLS
-- ============================================================================

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own account" ON public.accounts
  FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users insert own account" ON public.accounts
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users update own account" ON public.accounts
  FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users delete own account" ON public.accounts
  FOR DELETE USING (auth.uid() = id);

-- ----------------------------------------------------------------------------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profiles" ON public.profiles
  FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own profiles" ON public.profiles
  FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own profiles" ON public.profiles
  FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own profiles" ON public.profiles
  FOR DELETE USING (account_id = auth.uid());

-- ----------------------------------------------------------------------------

ALTER TABLE public.birth_data ENABLE ROW LEVEL SECURITY;

-- Helper: does this user own the given profile?
CREATE OR REPLACE FUNCTION public.user_owns_profile(p_profile_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = p_profile_id AND account_id = auth.uid()
  );
$$;

CREATE POLICY "Users read own birth_data" ON public.birth_data
  FOR SELECT USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users insert own birth_data" ON public.birth_data
  FOR INSERT WITH CHECK (public.user_owns_profile(profile_id));
CREATE POLICY "Users update own birth_data" ON public.birth_data
  FOR UPDATE USING (public.user_owns_profile(profile_id));
CREATE POLICY "Users delete own birth_data" ON public.birth_data
  FOR DELETE USING (public.user_owns_profile(profile_id));

-- ----------------------------------------------------------------------------

ALTER TABLE public.charts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own charts" ON public.charts
  FOR SELECT USING (public.user_owns_profile(profile_id));
-- Writes are service-role only (charts are written by the calculation edge function)

-- ----------------------------------------------------------------------------

ALTER TABLE public.profile_summaries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own profile_summaries" ON public.profile_summaries
  FOR SELECT USING (public.user_owns_profile(profile_id));
-- Writes are service-role only (summaries are written by the synthesis edge function)

-- ----------------------------------------------------------------------------

ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own relationships" ON public.relationships
  FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own relationships" ON public.relationships
  FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own relationships" ON public.relationships
  FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own relationships" ON public.relationships
  FOR DELETE USING (account_id = auth.uid());

-- ----------------------------------------------------------------------------

ALTER TABLE public.relationship_summaries ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.user_owns_relationship(p_relationship_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.relationships
    WHERE id = p_relationship_id AND account_id = auth.uid()
  );
$$;

CREATE POLICY "Users read own relationship_summaries" ON public.relationship_summaries
  FOR SELECT USING (public.user_owns_relationship(relationship_id));
-- Writes service-role only

-- ----------------------------------------------------------------------------

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own subscriptions" ON public.subscriptions
  FOR SELECT USING (account_id = auth.uid());
-- All writes service-role only (synced from webhooks)

-- ============================================================================
-- KNOWLEDGE DOMAIN RLS
-- ============================================================================

ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users read knowledge_chunks" ON public.knowledge_chunks
  FOR SELECT TO authenticated USING (TRUE);
-- All writes service-role only

-- ============================================================================
-- INTERACTION DOMAIN RLS
-- ============================================================================

ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own chat_sessions" ON public.chat_sessions
  FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own chat_sessions" ON public.chat_sessions
  FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own chat_sessions" ON public.chat_sessions
  FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own chat_sessions" ON public.chat_sessions
  FOR DELETE USING (account_id = auth.uid());

-- ----------------------------------------------------------------------------

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.user_owns_chat_session(p_session_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.chat_sessions
    WHERE id = p_session_id AND account_id = auth.uid()
  );
$$;

CREATE POLICY "Users read own chat_messages" ON public.chat_messages
  FOR SELECT USING (public.user_owns_chat_session(session_id));
CREATE POLICY "Users insert own chat_messages" ON public.chat_messages
  FOR INSERT WITH CHECK (
    role = 'user' AND public.user_owns_chat_session(session_id)
  );
-- assistant messages are service-role only
-- No UPDATE or DELETE policies — chat is append-only

-- ----------------------------------------------------------------------------

ALTER TABLE public.ai_responses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own ai_responses" ON public.ai_responses
  FOR SELECT USING (account_id = auth.uid());
-- All writes service-role only
```

---

## 4. The AI assembly pipeline

This section walks through what happens, end to end, when a user sends a chat message. Implement edge functions to match this flow.

### 4.1 Sign-up → first chart calculation → summary synthesis

Happens once per profile when birth data is entered.

1. Mobile collects birth data from the user.
2. Mobile POSTs to a Supabase edge function `calculate-chart`:
   - Edge function calls the existing web API at `moonrhythms.io/api/SwissEphemerisChart` (or replicates the calculation directly if we want to remove the web dependency).
   - Receives the chart JSONB.
   - Inserts a row into `public.charts`.
3. The edge function then calls (or asynchronously triggers) `synthesize-profile-summary`:
   - Loads the chart from `public.charts`.
   - Loads relevant deterministic context from `astro_*` tables (e.g., joins dignities, decans for each placement).
   - Builds the synthesis prompt with the chart data and structured context.
   - Calls `claude-opus-4-7` once.
   - Stores result in `public.profile_summaries` with `prompt_version = 'v1'`, `model_used = 'claude-opus-4-7'`.

The whole flow should complete in well under 10 seconds. The mobile app shows a "preparing your chart" state.

### 4.2 Adding a partner profile → relationship → synastry summary

Paid users only.

1. Mobile collects partner's birth data + relationship label.
2. Same `calculate-chart` flow runs for the partner profile (creates profile, birth_data, chart, profile_summary rows for the partner).
3. After the partner's chart is calculated, mobile POSTs to `create-relationship`:
   - Inserts a `relationships` row linking the user's `self` profile (`profile_a_id`) and the partner profile (`profile_b_id`).
   - Triggers `synthesize-relationship-summary`:
     - Loads both charts and both profile_summaries.
     - Loads relevant synastry patterns from `astro_synastry_patterns` and `astro_moon_compatibility`.
     - Builds the synastry synthesis prompt.
     - Calls `claude-opus-4-7`.
     - Stores result in `public.relationship_summaries`.

### 4.3 Sending a chat message (the core loop)

Every user chat message hits this flow.

```
User message → edge function `chat-respond` → LLM → response → user
```

Detailed steps inside `chat-respond`:

1. **Authenticate** the user, get their `account_id`.
2. **Identify or create the session.**
   - If `session_id` in request body, verify ownership via RLS.
   - If no session, create a new `chat_sessions` row.
3. **Determine session context.**
   - For solo sessions: load the user's `profile_summaries.summary_text` for the linked profile.
   - For relationship sessions: load both profile summaries + the `relationship_summaries.summary_text`.
4. **Insert the user message** into `chat_messages` (role='user').
5. **Embed the user message.**
   ```typescript
   const embedding = await openai.embeddings.create({
     model: "text-embedding-3-small",
     input: userMessage,
   });
   ```
6. **Retrieve knowledge chunks.**
   ```typescript
   const chunks = await supabase.rpc('match_knowledge_chunks', {
     query_embedding: embedding.data[0].embedding,
     match_threshold: 0.7,
     match_count: 5,
   });
   ```
7. **Load recent chat history** — last 15 messages from `chat_messages` for this session, ordered by created_at.
8. **Assemble the system prompt** using the template:
   ```
   You are Moon Rhythms' personal astrology guide.
   [...voice rules...]
   
   # Who you're talking to
   [profile_summary.summary_text]
   
   # (If relationship session) About this relationship
   [partner profile_summary]
   [relationship_summary.summary_text]
   
   # Relevant astrological context for this question
   [knowledge_chunks concatenated]
   
   # Recent conversation
   [recent messages formatted]
   ```
9. **Call Claude** with streaming enabled.
   - Default model: `claude-sonnet-4-6`.
   - Premium model (`claude-opus-4-7`) reserved for future @advisor-style escalation features.
10. **Stream the response** back to the mobile client.
11. **Log the AI response** to `public.ai_responses` with full citations array:
    ```json
    {
      "citations": [
        {"source": "profile_summary", "profile_id": "..."},
        {"source": "relationship_summary", "relationship_id": "..."},
        {"source": "knowledge_chunk", "chunk_key": "planet_mars_nature", "similarity": 0.84},
        ...
      ]
    }
    ```
12. **Insert the assistant message** into `chat_messages` (role='assistant', ai_response_id linked).
13. **Update** `chat_sessions.last_message_at`.

### 4.4 Cost tracking

Every call to `chat-respond` must populate `ai_responses` with token counts and cost. Approximate cost calculation (update as Anthropic pricing changes):

```typescript
const costCents = (
  (response.usage.input_tokens * SONNET_INPUT_RATE) +
  (response.usage.output_tokens * SONNET_OUTPUT_RATE)
) * 100;
```

Pricing constants live in `lib/llm-pricing.ts`, version-controlled.

### 4.5 Free tier vs paid tier enforcement

Enforce in `chat-respond` BEFORE making the LLM call:

- Free users: max 5 messages per chat_session per day (or whatever the final policy is — confirm with Beau).
- Free users: max 1 chat_session at a time (their solo session). Cannot create relationship sessions.
- Paid users: unlimited.

When the gate is hit, return a structured error the mobile client renders as a paywall prompt.

### 4.6 Streaming response handling

Mobile client expects Server-Sent Events from `chat-respond`. Standard SSE format:

```
event: token
data: {"content": "Sounds"}

event: token
data: {"content": " like"}

event: done
data: {"message_id": "..."}
```

This makes the chat feel responsive (~50ms per token vs 5+ seconds for a full response).

### 4.7 Summary regeneration job

When the synthesis prompt or model is upgraded, run this background job. Implementation: a Supabase edge function triggered manually (initially) or on a cron.

Pseudocode:

```typescript
// 1. Pick the current target version
const TARGET_PROMPT_VERSION = 'v2';
const TARGET_MODEL = 'claude-opus-4-7';

// 2. Find profiles still on an older version
const staleProfiles = await supabase
  .from('profile_summaries')
  .select('profile_id')
  .neq('prompt_version', TARGET_PROMPT_VERSION);

// 3. Regenerate each (in batches to respect rate limits)
for (const batch of chunk(staleProfiles, 10)) {
  await Promise.all(batch.map(async ({ profile_id }) => {
    const chart = await loadChart(profile_id);
    const newSummary = await synthesizeProfileSummary(chart, TARGET_PROMPT_VERSION);
    await supabase
      .from('profile_summaries')
      .update({
        summary_text: newSummary,
        prompt_version: TARGET_PROMPT_VERSION,
        model_used: TARGET_MODEL,
        generated_at: new Date().toISOString(),
      })
      .eq('profile_id', profile_id);
  }));
  await sleep(1000); // rate limit buffer
}
```

Same pattern for `relationship_summaries`.

---

## 5. Implementation plan

Build in this order. Each phase ships something testable.

### Phase 1A: Deterministic spine (~2 hours)

**Goal:** Deploy the already-designed `astro_*` reference tables.

1. Verify `pgvector` extension is enabled in Supabase (Database → Extensions).
2. Apply the existing migration files (already designed in this conversation's artifacts):
   - `deterministic_schema.sql`
   - `deterministic_data_seed.sql`
   - `user_preferences_schema.sql`
3. Run validation queries from the seed file's footer.
4. **Reconciliation note:** If Supabase already has tables that conflict (per the existing `moon-rhythms` web schema), STOP and ask Beau. The web app's existing `profiles` and `birth_charts` tables need to be reconciled with the new schema — see Section 5.2 below.

### Phase 1B: Reconciliation with existing web schema

**This is critical and must happen before Phase 1C.** The web app already has `profiles`, `birth_charts`, and `chart_cache` tables. We need to migrate or coexist.

**Required action by Claude Code:** before creating any new user-domain tables, READ the existing `supabase/migrations/` directory in the moon-rhythms-mobile repo and the moon-rhythms web repo. Identify exactly what columns exist on the current `profiles` and `birth_charts` tables.

**Decision Beau owes:** does the web app continue to use the old schema while the new schema is built alongside (eventually deprecating the old), OR do we migrate the web app's existing rows into the new shape immediately?

For MVP velocity: I recommend building the new schema alongside the old (use the new `public.accounts`, `public.profiles`, `public.birth_data`, etc. tables). The web app keeps using its existing tables until we're ready to migrate it. The mobile app uses ONLY the new schema.

Claude Code: do NOT rename or drop the existing `profiles` and `birth_charts` tables. Build the new schema with the names specified in Section 3 (which are distinct from the existing names: `accounts` is new, `profiles` already exists — see naming conflict below).

**Naming conflict to resolve:** the web app has a `profiles` table tied directly to `auth.users.id`. The new schema needs a different `profiles` table tied to `accounts.id` with `subject_type`. These can't both be named `profiles`.

**Resolution options for Beau to pick:**

- **Option A:** Rename the web app's existing `profiles` table to `account_profiles` (or similar) via migration. Update web app code. Then the new mobile schema uses `profiles` as designed.
- **Option B:** Keep web's `profiles` as-is. Name the new mobile profiles table `subject_profiles` or `astro_profiles`. The naming is uglier but no web app changes required.

Recommended: Option A, but it requires a coordinated migration on the web app. Beau must decide.

### Phase 1C: User domain tables (~3 hours)

Create migrations for:
- `public.accounts`
- `public.profiles` (per the naming decision above)
- `public.birth_data`
- `public.charts`
- `public.profile_summaries`
- `public.relationships`
- `public.relationship_summaries`
- `public.subscriptions` + the plan_tier sync trigger

Apply all RLS policies as specified in Section 3.5. Use the helper functions (`user_owns_profile`, `user_owns_relationship`).

### Phase 1D: Knowledge corpus table (~1 hour)

- Create `public.knowledge_chunks`.
- Create the `match_knowledge_chunks` RPC function.
- Load the 31 starter chunks from `sepharial_chunks_v1.json` (already designed). Initially WITHOUT embeddings (NULL).
- Create a separate edge function `embed-knowledge-chunks` that iterates over rows with NULL embeddings, calls OpenAI for each, and updates the row. Run this once after the seed.

### Phase 1E: Interaction domain tables (~1 hour)

- `public.chat_sessions`
- `public.chat_messages`
- `public.ai_responses`
- All RLS policies.

### Phase 2: Edge functions for AI assembly (~1 week)

Build these edge functions in this order:

1. **`calculate-chart`** — accepts birth data, calls calculation engine, returns/stores chart. Calls existing web API at moonrhythms.io/api/SwissEphemerisChart.
2. **`synthesize-profile-summary`** — accepts profile_id, generates summary, stores in profile_summaries.
3. **`synthesize-relationship-summary`** — accepts relationship_id, generates synastry summary.
4. **`chat-respond`** — the core chat assembly function (Section 4.3).
5. **`embed-knowledge-chunks`** — utility for adding embeddings to chunks.
6. **`regenerate-summaries`** — the background regeneration job (Section 4.7).

### Phase 3: Mobile integration (~1-2 weeks)

Mobile app wires up the edge functions:

1. Sign-up flow uses Supabase Auth, creates `accounts` row.
2. Birth data form calls `calculate-chart`, then triggers `synthesize-profile-summary` (or chains them in one edge function).
3. Chart visualization renders from the cached chart JSONB.
4. Solo chat UI streams from `chat-respond`.
5. "Add a partner" flow (paid only) creates a new profile + relationship + triggers synastry synthesis.
6. Relationship chat UI uses the same `chat-respond` function with `session_type='relationship'`.

### Phase 4: Subscriptions (~3 days)

- Integrate RevenueCat SDK in the mobile app (recommended).
- Add webhook endpoint at `supabase/functions/revenuecat-webhook` to sync `subscriptions` table.
- Verify the plan_tier trigger correctly updates accounts.
- Build the paywall UI.

### Phase 5: Polish + App Store submission (~1 week)

Beyond schema scope. See `master-build-doc.md`.

---

## 6. Decisions made (locked-in)

These are the locked decisions from extensive design conversation with Beau. If Claude Code disagrees with any of these, stop and ask.

| Decision | Locked value |
|---|---|
| Primary product | Mobile app, solo + relationship light |
| First paid product | Solo astrology chat unlocks unlimited messages; relationship features paid-only |
| MVP scope | Solo chat + relationship light (one partner profile, no synastry chat between two humans, no group chats) |
| Zodiac system | Tropical |
| House system | Placidus |
| Rulerships | Modern (Pluto rules Scorpio, etc.) |
| Lunar node | True node |
| Black Moon Lilith | Mean apogee |
| Aspects | Major only (conjunction, opposition, trine, square, sextile) |
| Birth time unknown handling | Reuse web app's existing flow; chart records `has_houses=false`; AI synthesis skips house interpretation |
| Calculation engine | Moshier Swiss Ephemeris via existing web API at moonrhythms.io/api |
| Chart storage | JSONB, not normalized |
| AI for synthesis | claude-opus-4-7 (quality-critical, one-time) |
| AI for chat | claude-sonnet-4-6 (cost-conscious, frequent) |
| Embeddings | OpenAI text-embedding-3-small (1536 dimensions) |
| Vector index | pgvector HNSW |
| Profile summaries | Pre-synthesized, stored, version-tagged for regeneration |
| Profile summaries visible to users | NO for MVP (internal only). Future feature: a polished "Your Astrological Profile" UI |
| Knowledge corpus | 31 starter chunks from Sepharial. Incremental growth via PD sources + commissioned content. No scraping of modern sites |
| Chat history | Stored permanently. No long-term memory curation in MVP (scaffolded for later) |
| Profile deletion | Soft delete (`deleted_at`). Hard delete after grace period. Cascades to charts and relationships. |
| When a relationship is deleted | Soft delete the relationship. Chat sessions about it become orphaned but readable. Confirm with Beau before deciding to also delete chat sessions. |
| Partner consent | Not required. Partners do not have accounts. The paid user owns all data they enter. If partner later signs up, they get an independent account. |
| Free tier limit | 5 chat messages per day in solo mode (confirm exact number with Beau) |
| Paid tier | Unlimited messages, multiple profiles/relationships |
| Subscription model | Annual subscription with 3-day free trial (confirm pricing with Beau) |
| Payments | RevenueCat for cross-platform |

---

## 7. Scaffolded futures (NOT BUILT for MVP)

These features are not built. Don't create empty tables for them. But the schema is designed so they slot in cleanly. Document for future engineers (and future-Beau).

### Quizzes (deferred)

When built, will require:
- `quizzes` (the quiz definitions — MBTI, Big Five, Enneagram, DISC, etc.)
- `quiz_questions` (questions per quiz)
- `quiz_responses` (a user's answers to one quiz)
- `quiz_profile_chunks` (synthesized text from quiz results, parallel to profile_summaries)

Tied to `profiles.id`. Doesn't change existing tables.

### Human Design (BUILT — 2026-05-16, migration 0010)

Storage live. Calculation via `natalengine` (web `pages/api/human-design.api.js`, ESM-only — dynamic import on Vercel). Custom union-find definition override on top of library output. Bodygraph render via web `components/BodyGraph.js`.

Table:
- `human_design_readings(id, profile_id UNIQUE, data jsonb, calculation_engine='natalengine', calculation_version='v1', calculated_at, created_at, updated_at)` — one row per profile, upsert on profile_id.
- RLS mirrors `charts`: read/insert/update gated by `user_owns_profile()`, no delete (rows overwritten via UPSERT).

Interpretation embeddings still deferred — when built, add `human_design_interpretations(reading_id FK → human_design_readings.id, embedding vector, content text, …)` without touching reading rows.

Mobile: not yet consumed; web detail page at `/human-design-display`.

### Numerology (BUILT — 2026-05-16, migration 0010)

Storage live. Calculation via web `pages/api/numerology.api.js` (Pythagorean, in `lib/numerology.js`).

Table:
- `numerology_readings(id, profile_id UNIQUE, data jsonb, calculation_engine='pythagorean', calculation_version='v1', calculated_at, created_at, updated_at)` — one row per profile, upsert on profile_id.
- Same RLS pattern as `human_design_readings`.

Interpretation embeddings still deferred.

Mobile: not yet consumed; web detail page at `/numerology-display`.

### Chinese zodiac (BUILT — 2026-05-16, migration 0010)

Storage live. Calculation via web `pages/api/chinese-zodiac.api.js` (four pillars + animal/element via `lunar-javascript`).

Table:
- `chinese_zodiac_readings(id, profile_id UNIQUE, data jsonb, calculation_engine='lunar-javascript', calculation_version='v1', calculated_at, created_at, updated_at)` — one row per profile, upsert on profile_id.
- Same RLS pattern.

Interpretation embeddings still deferred.

Mobile: not yet consumed; web detail page at `/chinese-zodiac-display`.

### Transit notifications (deferred)

When built, will require:
- `notification_preferences` (per account)
- `notification_events` (a log of sent notifications)
- A scheduled job that runs daily/hourly to compute moon transits and trigger notifications for users with relevant natal placements

Transits themselves are NOT stored — they're computed on demand. The existing web `/api/moon-position` endpoint is the calculation source.

### Long-term chat memory (deferred)

When built, will require:
- `chat_memory_items` (curated facts about the user, extracted from chat history)

Different from `chat_messages` — memory items are facts ("user mentioned that her partner is in therapy") that the AI uses across sessions, not raw messages.

### Group / multi-person chats (far future)

Would require refactoring `chat_sessions` to support multiple linked profiles and rethinking RLS. Out of scope for MVP and Phase 2.

### Invited partner mode (post-MVP)

When the partner can actually sign up and join the chat. Requires:
- A `profile_claim_invites` table for the invitation flow
- A migration path for an "owned by paid user" profile to become "owned by the partner who claimed it"
- Reworked RLS to allow partner read access to relationship data with consent records

This is a significant additional system. Build only after solo + relationship light has validated the moat.

---

## 8. What to do RIGHT NOW (Claude Code)

If you're reading this for the first time, your task is:

1. **Read this entire document.**
2. **Investigate the current state of the Supabase project.** Specifically:
   - List all tables in `public` schema with their columns and types.
   - List all migration files in both `moon-rhythms` (web) and `moon-rhythms-mobile` (mobile) repos under `supabase/migrations/`.
   - Note any tables that overlap with the schema in Section 3 of this document (especially `profiles`, `birth_charts`).
3. **Produce a report** in `docs/CURRENT_SUPABASE_STATE.md` in the mobile repo with the findings.
4. **In the same report**, propose a reconciliation approach. Specifically address the `profiles` naming conflict described in Section 5.2.
5. **Stop and wait for Beau's review.** Do not create new tables, do not run migrations, do not modify the existing schema.

After Beau reviews and approves the reconciliation approach, the next step is Phase 1A (deterministic spine deployment).

---

## End of document

If anything in this document is unclear, contradictory, or insufficient, ask Beau before making assumptions. The cost of a wrong assumption at the foundation layer is much higher than the cost of one clarifying question.
