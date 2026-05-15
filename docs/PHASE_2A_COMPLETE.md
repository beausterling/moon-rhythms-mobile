# Phase 2a — COMPLETE

**Date completed:** 2026-05-15
**Supabase project:** `worbycfxsaeqwzlckvah`
**Web deploy:** moonrhythms.io (Vercel, latest commit on `main`)
**Mobile repo:** moon-rhythms-mobile (this repo, latest on `master`)

Phase 2a of the Moon Rhythms Supabase build-out is fully delivered. A signed-up user can sign in at moonrhythms.io, save a birth chart, and have an AI conversation about themselves that is grounded in the cached profile summary AND the full structured chart facts (every degree, house, dignity, aspect). Cost-tracked, free-tier-gated, RLS-isolated.

## What's live

### Backend (all on Vercel as Next.js Pages API routes)

| Path | Purpose |
|------|---------|
| `lib/ai/anthropic.js` | `@anthropic-ai/sdk` client + model constants (`claude-opus-4-7`, `claude-sonnet-4-6`) |
| `lib/ai/openai.js` | `text-embedding-3-small` (1536d) via plain fetch |
| `lib/ai/llm-pricing.js` | Token → integer-cents conversion (Opus $15/$75, Sonnet $3/$15 per 1M) |
| `lib/ai/chartContext.js` | Joins chart JSONB to `astro_*` spine; outputs structured planet/house/aspect object |
| `lib/ai/prompts/profileSynthesis.v1.js` | Opus synthesis system prompt + chart-context formatter |
| `lib/ai/prompts/chatRespond.v1.js` | Sonnet chat system prompt with "Chart facts (authoritative)" block + strict grounding rule |
| `lib/ai/synthesizeProfile.js` | Shared synthesis logic (called from API route AND save-reading auto-trigger) |
| `lib/ai/freeTierGate.js` | 5 user messages per session per rolling 24h for free accounts |
| `pages/api/synthesize-profile-summary.api.js` | POST endpoint — Opus, idempotent, writes `profile_summaries` + logs `ai_responses` |
| `pages/api/chat-sessions.api.js` | GET / POST / PATCH / DELETE on chat_sessions |
| `pages/api/chat-messages.api.js` | GET messages by session_id (RLS-enforced) |
| `pages/api/chat-respond.api.js` | POST with SSE streaming. Loads summary + chart facts + RAG chunks + recent history → streams Sonnet → logs everything |
| `pages/api/save-reading.api.js` | Extended to auto-trigger synthesis on first chart save |

### Frontend

| Path | Purpose |
|------|---------|
| `pages/chat.deploy.js` | Two-pane chat UI with SSE stream consumer + self-heal on 409 |
| `components/Chat/ChatSidebar.jsx` | Session list / new chat / rename / delete |
| `components/Chat/MessageList.jsx` | Message thread with auto-scroll + streaming indicator |
| `components/Chat/MessageInput.jsx` | Multiline textarea, Cmd/Ctrl+Enter sends |
| `components/Chat/PaywallModal.jsx` | Rendered on 402 free-tier exceeded |
| `components/Navbar.js` | Adds "Chat" nav link for signed-in users |
| `pages/dashboard.deploy.js` | Adds "Talk to your chart" CTA card when a birth chart exists |
| `lib/supabase/legacyShape.js` | Exposes `profile_id` for chat session targeting |

### Route rename

- `/auth` → `/login`. File renamed (`pages/auth.deploy.js` → `pages/login.deploy.js`); 4 references updated (dashboard + chat redirects, mobile + desktop nav links). Supabase Auth `uri_allow_list` already wildcards `https://moonrhythms.io/**`, no Auth dashboard change needed.

### System prompts (v1)

Two prompts live, both versioned via `prompt_version` column for future regeneration jobs:

- **`profile_synthesis_v1`** — Opus, one-shot. ~600-word system instruction → ~500-word warm-but-grounded profile prose. Includes hardened "Aspect grounding rule" forbidding invention of aspects not in the chart's explicit list.
- **`chat_v1`** — Sonnet, per-message. ~700-word system. Now includes:
  1. The cached summary (for tone/themes)
  2. **Chart facts (authoritative)** — every planet's sign/degree/decan/house/dignity/retrograde, every house cusp, rising, moon phase, complete aspect list
  3. Retrieved knowledge chunks (RAG)
  4. Last 15 messages
  
  With a strict "Chart-facts grounding rule" telling the model the list is exhaustive and forbidding invented aspects, degrees, houses.

### Environment

`ANTHROPIC_API_KEY` saved to all 4 places:
- `~/.claude/secrets.env`
- `moon-rhythms/.env.local`
- `moon-rhythms-mobile/.env.local`
- Vercel Production + Development

`SUPABASE_SERVICE_ROLE_KEY` belatedly added to Vercel Prod + Dev (Phase 1 had it local-only — caught and fixed during Phase 2a verification).

## End-to-end verification

Beau (`beaujsterling@gmail.com`) tested the full loop on production:

| Step | Result |
|------|--------|
| Auto-synthesis on chart save | ✅ Opus row in `ai_responses`, summary in `profile_summaries` |
| `/chat` self-heal when summary missing | ✅ Page detects 409, calls synth, retries |
| SSE streaming chat | ✅ Tokens stream visibly word-by-word |
| Chart-grounded answers | ✅ Real chart data flows into prompt (input tokens jumped from ~1.5k → ~3.4k after Option A) |
| Cost logging | ✅ Every call writes `cost_cents`, `prompt_tokens`, `completion_tokens`, `latency_ms` |
| Anti-hallucination | ✅ The Mercury–Mars trine false claim was eliminated after prompt hardening + summary regeneration |

**Final tally (Beau's account):**

| Table | Rows |
|-------|------|
| `auth.users` | 1 |
| `accounts` | 1 |
| `profiles` (self) | 1 |
| `birth_data` | 1 |
| `charts` | 1 |
| `profile_summaries` | 1 (`profile_synthesis_v1`, Opus 4.7) |
| `chat_sessions` | 1 |
| `chat_messages` | 8 |
| `ai_responses` | 6 (2 Opus synthesis + 4 Sonnet chats) |
| `knowledge_chunks` | 31 |

**Cost so far:** under $0.30 total across all synthesis + chat traffic during Phase 2a development and verification.

## Bugs found and fixed during verification

1. **`SUPABASE_SERVICE_ROLE_KEY` missing from Vercel.** First chat-respond call returned 500 "SUPABASE_SERVICE_ROLE_KEY is not set". Phase 1 had only stored it locally. Added to Vercel Production + Development, redeployed.
2. **Opus hallucinated a Mercury–Mars trine** in the v1 synthesis prompt. The chart only contains Venus–Mars trine; the summary said "Mars in late Taurus in the third trines that Sagittarian Mercury beautifully." Root cause: synthesis prompt didn't explicitly forbid inventing aspects. Fixed by:
   - Adding a strict "Aspect grounding rule" section
   - Relabeling the aspect block in the prompt as "Complete aspect list — these are ALL the aspects this chart contains. No other aspects exist."
   - Deleting Beau's bad summary so the self-heal regenerated with the new prompt.
3. **Chat could repeat any summary error verbatim** because `chat-respond` saw only the cached summary, not the raw chart. Fixed by piping the full `chartContext` into every chat call (Option A — ~2k extra input tokens, ~$0.006/message) with the same strict grounding rule applied at the chat level.
4. **`/chat` self-heal didn't fire when an existing session was present.** The page only triggered synthesis on session-create, not on chat-respond 409. Added 409 handler in `handleSend` that auto-calls `/api/synthesize-profile-summary` and retries the send.

## What's deferred (Phase 2b / 2c / 3+)

These are explicitly NOT in Phase 2a:

- **Relationship synthesis (Phase 2b).** `synthesize-relationship-summary` edge function + `session_type='relationship'` chat support + paid-tier gate on creating `subject_type='other'` profiles.
- **Knowledge-chunk threshold tuning (Phase 2c).** Initial verification showed `match_threshold=0.7` returns 0 chunks for natural user questions against the Sepharial corpus. Either lower the threshold (try 0.5), grow the corpus, or both. Currently the AI is grounded by chart facts + cached summary alone — chunks are a no-op until the threshold or corpus changes.
- **Summary regeneration job (Phase 2c).** When prompt_version bumps to v2, a background loop will regenerate all stale summaries. Foundation already in place: `profile_summaries.prompt_version` column + `regenerate-summaries` function is the planned name.
- **Cost analytics view (Phase 2c).** A `view` over `ai_responses` aggregating $/day per account, $/model, etc.
- **Mobile integration (Phase 3).** Wire Expo app to consume these endpoints. See `docs/MOBILE_NEXT_BRIEF.md` for the immediate mobile work (Birth Matrix form, dashboard rework) which is a prerequisite.
- **Subscriptions (Phase 4).** RevenueCat + paywall UI + `subscriptions` table sync.

## Known minor cleanups (non-blocking)

- **PaywallModal Upgrade button is a stub** (`console.log('TODO Phase 4')`). Wire when Phase 4 ships.
- **Vercel Preview env keys.** `ANTHROPIC_API_KEY` is in Production + Development but not Preview (the Phase 1 `vercel env add` CLI quirk persists). Revisit when PR preview deploys become important.
- **Chat-message history limit is 15.** Tunable in `chat-respond.api.js`. May need to grow with usage; watch input_tokens trend in `ai_responses`.

## What "Phase 2a complete" means going forward

The AI conversation loop is live, end-to-end, in production, with grounded responses and proper cost tracking. The architecture is exactly what the master doc prescribes for the solo-chat MVP.

Anyone reading this later: when iterating prompts, **always bump `prompt_version`** so the regeneration system can sweep old summaries. When changing the chart-grounding rule, preserve the strict "don't invent" wording — that was the load-bearing fix for hallucinated aspects.

Phase 2b (relationships) is the natural next sub-phase, but the master doc allows shipping mobile (Phase 3) on solo-only too. Mobile work is currently blocked on `docs/MOBILE_NEXT_BRIEF.md` (Birth Matrix form + astrology-only dashboard) before AI chat integration can begin.
