#!/usr/bin/env node
/**
 * Phase 1.8 — Knowledge corpus seed.
 *
 * Loads sepharial_chunks_v1.json (31 modernized chunks), generates embeddings
 * via OpenAI text-embedding-3-small (1536d), upserts into public.knowledge_chunks
 * keyed on chunk_key. Idempotent: re-runs replace embeddings and bodies.
 *
 * Run from anywhere; the script resolves paths via import.meta.url.
 *
 *   node scripts/seed_knowledge_chunks.mjs
 *
 * Env required (read from process.env — load via `set -a; source .env.local; set +a` first):
 *   OPENAI_API_KEY
 *   EXPO_PUBLIC_SUPABASE_URL  (or NEXT_PUBLIC_SUPABASE_URL)
 *   SUPABASE_SERVICE_ROLE_KEY
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { createClient } from '@supabase/supabase-js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const REPO_ROOT = resolve(__dirname, '..');
const BUNDLE_PATH = resolve(REPO_ROOT, 'moon_rhythms_build_bundle/sepharial_chunks_v1.json');

const PROMPT_VERSION = 'voice_modernization_v1';
const EMBEDDING_MODEL = 'text-embedding-3-small';
// Cost rate (text-embedding-3-small, 2025 pricing): $0.020 per 1M tokens.
const COST_PER_TOKEN_USD = 0.000_000_020;

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const SUPABASE_URL =
    process.env.EXPO_PUBLIC_SUPABASE_URL ||
    process.env.NEXT_PUBLIC_SUPABASE_URL ||
    process.env.SUPABASE_URL;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

for (const [name, val] of Object.entries({ OPENAI_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY })) {
    if (!val) {
        console.error(`Missing env: ${name}`);
        console.error('Source your .env.local first:  set -a && source .env.local && source ~/.claude/secrets.env && set +a');
        process.exit(1);
    }
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
});

function deriveCategory(chunkKey) {
    if (chunkKey.startsWith('planet_'))    return 'planet';
    if (chunkKey.startsWith('sign_'))      return 'sign';
    if (chunkKey.startsWith('house_'))     return 'house';
    if (chunkKey.startsWith('aspect_'))    return 'aspect';
    if (chunkKey.startsWith('synastry_'))  return 'synastry';
    return 'framework';
}

async function embed(text) {
    const res = await fetch('https://api.openai.com/v1/embeddings', {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${OPENAI_API_KEY}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ input: text, model: EMBEDDING_MODEL }),
    });
    if (!res.ok) {
        const body = await res.text();
        throw new Error(`OpenAI embeddings failed (${res.status}): ${body}`);
    }
    const json = await res.json();
    return {
        embedding: json.data[0].embedding,
        promptTokens: json.usage.prompt_tokens,
        totalTokens: json.usage.total_tokens,
    };
}

async function main() {
    const rawBundle = readFileSync(BUNDLE_PATH, 'utf8');
    const { chunks } = JSON.parse(rawBundle);
    console.log(`Loaded ${chunks.length} chunks from ${BUNDLE_PATH}`);

    let totalTokens = 0;
    const categoryCounts = {};

    for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        const category = deriveCategory(chunk.chunk_key);
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        process.stdout.write(`[${String(i + 1).padStart(2, '0')}/${chunks.length}] ${chunk.chunk_key} (${category})  `);

        const { embedding, totalTokens: t } = await embed(chunk.body);
        totalTokens += t;

        const { error } = await supabase
            .from('knowledge_chunks')
            .upsert(
                {
                    chunk_key:      chunk.chunk_key,
                    title:          chunk.title,
                    body:           chunk.body,
                    embedding,
                    source_ref:     chunk.source_ref,
                    keywords:       chunk.keywords ?? [],
                    chunk_category: category,
                    prompt_version: PROMPT_VERSION,
                },
                { onConflict: 'chunk_key' }
            );

        if (error) {
            console.log('FAIL');
            console.error(error);
            process.exit(1);
        }
        console.log(`${t} tok`);
    }

    const estimatedCost = totalTokens * COST_PER_TOKEN_USD;
    console.log('');
    console.log('Done.');
    console.log(`Total tokens: ${totalTokens}`);
    console.log(`Estimated cost: $${estimatedCost.toFixed(6)}`);
    console.log('Category breakdown:', categoryCounts);
}

main().catch((err) => {
    console.error('Seed failed:', err);
    process.exit(1);
});
