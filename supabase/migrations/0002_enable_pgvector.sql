-- Migration 0002 — enable pgvector
-- Required for the knowledge_chunks.embedding column (migration 0006_knowledge_corpus_schema.sql).
-- Idempotent: safe to re-run.

CREATE EXTENSION IF NOT EXISTS vector;
