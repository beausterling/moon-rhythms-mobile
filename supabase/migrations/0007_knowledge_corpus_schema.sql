-- Migration 0007 — knowledge_chunks (interpretive corpus for RAG)
-- Table is created empty. Corpus is loaded in Phase 1.8 by an edge function
-- that reads sepharial_chunks_v1.json + generates embeddings via OpenAI.
-- Per supabase_master_doc.md §3.3 and PHASE_1_HANDOFF.md §3.4.

-- pgvector is enabled in migration 0002. Keep this redundant to make the
-- migration runnable standalone in fresh environments.
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE public.knowledge_chunks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_key       TEXT NOT NULL UNIQUE,
    title           TEXT NOT NULL,
    body            TEXT NOT NULL,
    embedding       VECTOR(1536),

    source_ref      TEXT NOT NULL,
    keywords        TEXT[] NOT NULL DEFAULT '{}',
    chunk_category  TEXT NOT NULL CHECK (chunk_category IN (
        'planet', 'sign', 'house', 'aspect', 'framework', 'synastry'
    )),
    prompt_version  TEXT NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_knowledge_chunks_category ON public.knowledge_chunks(chunk_category);
CREATE INDEX idx_knowledge_chunks_keywords ON public.knowledge_chunks USING GIN (keywords);
CREATE INDEX idx_knowledge_chunks_embedding
    ON public.knowledge_chunks USING hnsw (embedding vector_cosine_ops);

-- Cosine-similarity retrieval RPC.
CREATE OR REPLACE FUNCTION public.match_knowledge_chunks(
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
)
LANGUAGE plpgsql
STABLE
AS $$
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
        AND kc.embedding IS NOT NULL
        AND 1 - (kc.embedding <=> query_embedding) > match_threshold
    ORDER BY kc.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- updated_at trigger reuse — function defined in 0006.
CREATE TRIGGER knowledge_chunks_set_updated_at
    BEFORE UPDATE ON public.knowledge_chunks
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: authenticated users may read; writes are service-role only.
ALTER TABLE public.knowledge_chunks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated read knowledge_chunks" ON public.knowledge_chunks
    FOR SELECT TO authenticated USING (TRUE);

-- TODO Phase 1.8: load sepharial_chunks_v1.json + generate embeddings via
-- OpenAI text-embedding-3-small (1536d). Until then the table stays empty,
-- match_knowledge_chunks returns zero rows, and the AI chat pipeline falls
-- back to the structured astro_* spine alone.
