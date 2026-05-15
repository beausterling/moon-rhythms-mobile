-- Migration 0009 — chat / interaction domain schema.
-- 3 tables: chat_sessions, chat_messages, ai_responses + helper + RLS.
-- Per supabase_master_doc.md §3.4 and PHASE_1_HANDOFF.md §3.6.

-- ============================================================================
-- 1. ai_responses — log row for every AI generation (created before
--    chat_messages because chat_messages has an FK to ai_responses).
-- ============================================================================
CREATE TABLE public.ai_responses (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    session_id          UUID,   -- FK added after chat_sessions exists; see below.
    model_used          TEXT NOT NULL,
    prompt_version      TEXT NOT NULL,
    system_prompt       TEXT,
    citations           JSONB NOT NULL DEFAULT '[]'::jsonb,
    prompt_tokens       INTEGER NOT NULL,
    completion_tokens   INTEGER NOT NULL,
    cost_cents          INTEGER NOT NULL,
    latency_ms          INTEGER NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_responses_account ON public.ai_responses(account_id, created_at DESC);
CREATE INDEX idx_ai_responses_model   ON public.ai_responses(model_used);

-- ============================================================================
-- 2. chat_sessions — solo or relationship conversation thread.
-- ============================================================================
CREATE TABLE public.chat_sessions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES public.accounts(id) ON DELETE CASCADE,
    session_type        TEXT NOT NULL CHECK (session_type IN ('solo', 'relationship')),
    profile_id          UUID REFERENCES public.profiles(id)      ON DELETE CASCADE,
    relationship_id     UUID REFERENCES public.relationships(id) ON DELETE CASCADE,
    title               TEXT,
    last_message_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at          TIMESTAMPTZ,
    CHECK (
        (session_type = 'solo'         AND profile_id IS NOT NULL AND relationship_id IS NULL)
        OR
        (session_type = 'relationship' AND relationship_id IS NOT NULL AND profile_id IS NULL)
    )
);

CREATE INDEX idx_chat_sessions_account      ON public.chat_sessions(account_id, last_message_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_chat_sessions_profile      ON public.chat_sessions(profile_id);
CREATE INDEX idx_chat_sessions_relationship ON public.chat_sessions(relationship_id);

CREATE TRIGGER chat_sessions_set_updated_at
    BEFORE UPDATE ON public.chat_sessions
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Now that chat_sessions exists, wire ai_responses.session_id FK.
ALTER TABLE public.ai_responses
    ADD CONSTRAINT ai_responses_session_fk
    FOREIGN KEY (session_id) REFERENCES public.chat_sessions(id) ON DELETE SET NULL;

CREATE INDEX idx_ai_responses_session ON public.ai_responses(session_id);

-- ============================================================================
-- 3. chat_messages — individual messages within a session. Append-only.
-- ============================================================================
CREATE TABLE public.chat_messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content         TEXT NOT NULL,
    ai_response_id  UUID REFERENCES public.ai_responses(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_messages_session ON public.chat_messages(session_id, created_at);

-- ============================================================================
-- 4. Session-ownership helper for downstream policies / edge functions.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.user_owns_chat_session(p_session_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.chat_sessions
        WHERE id = p_session_id
          AND account_id = auth.uid()
          AND deleted_at IS NULL
    );
$$;

-- ============================================================================
-- RLS
-- ============================================================================

ALTER TABLE public.chat_sessions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_responses   ENABLE ROW LEVEL SECURITY;

-- chat_sessions: full CRUD by owner.
CREATE POLICY "Users read own chat_sessions"   ON public.chat_sessions FOR SELECT USING (account_id = auth.uid());
CREATE POLICY "Users insert own chat_sessions" ON public.chat_sessions FOR INSERT WITH CHECK (account_id = auth.uid());
CREATE POLICY "Users update own chat_sessions" ON public.chat_sessions FOR UPDATE USING (account_id = auth.uid());
CREATE POLICY "Users delete own chat_sessions" ON public.chat_sessions FOR DELETE USING (account_id = auth.uid());

-- chat_messages: read own; users may only insert role='user'.
--   Assistant messages are written by the chat-respond edge function
--   running with service-role bypass. No UPDATE / DELETE policies — chat is append-only.
CREATE POLICY "Users read own chat_messages" ON public.chat_messages
    FOR SELECT USING (public.user_owns_chat_session(session_id));

CREATE POLICY "Users insert own user messages" ON public.chat_messages
    FOR INSERT WITH CHECK (
        role = 'user' AND public.user_owns_chat_session(session_id)
    );

-- ai_responses: read own; writes service-role only.
CREATE POLICY "Users read own ai_responses" ON public.ai_responses
    FOR SELECT USING (account_id = auth.uid());
