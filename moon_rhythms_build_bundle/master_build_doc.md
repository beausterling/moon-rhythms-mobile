# Moon Rhythms — Master Build Document

**Version:** v2.0  
**Last updated:** 2026-04-29  
**Owner:** Beau Sterling  
**For:** Claude Code (and any future engineering collaborator)

---

## How to use this document

This is a **living document** — the source of truth for Moon Rhythms development. Read it at the start of every session. Update it when decisions get made. Treat the **Decision Log** at the bottom as append-only history.

If you (Claude Code) are reading this for the first time in a session:

1. Read the entire document top to bottom before writing any code.
2. Run the **Audit Checklist** in Section 3 to understand the current state of the codebase.
3. Find the **Current Active Task** in Section 5 and confirm it's still what Beau wants before starting.
4. When you finish a task or learn something new, update the relevant section AND add an entry to the Decision Log.

If a section says "TBD" or "needs Beau's input," do not invent an answer. Ask Beau.

---

## 1. Project Overview

### What Moon Rhythms is

Moon Rhythms is an astrology app focused on **moon signs, self-awareness, and relationships**. The core differentiator is the *relationship* angle: helping couples (and other close pairs) understand each other's emotional operating systems through their charts.

### **THE PRIMARY PRODUCT IS THE MOBILE APP.**

The web app exists and works — it stays as a secondary surface. The mobile app gets all the build attention until the App Store launch. This is the single most important framing in this entire document.

- **Mobile app:** `Beausterling/moon-rhythms-mobile` — React Native, runs in Expo Go on iOS Simulator. Welcome screen renders. **This is what we're building toward MVP.**
- **Web app:** `Beausterling/moon-rhythms` — exists at moonrhythms.io, has Swiss Ephemeris integrated and functioning. **Maintain feature parity where possible but mobile leads.**

### Brand voice

- **Modern, grounded, warm.** Not mystical. No "cosmic," "the universe is telling you," or "written in the stars."
- **Practical and psychological.** Astrological placements are framed as patterns of behavior, tendency, emotional style — not fate.
- **Neutral on good/bad.** No "malefic/benefic" or "evil aspects." All placements have constructive and challenging expressions.
- **Ungendered.** No "the native," "his horoscope," or "masculine/feminine signs." Use "active/receptive."
- **Knowledgeable friend, not fortune-teller.**

### Customer segments (in priority order for MVP)

1. **Relationship-focused individuals** (partners, parents) — the primary commercial moat
2. **Emotionally intuitive individuals** seeking validation for mood patterns
3. **Mindful decision-makers** (entrepreneurs, creatives) optimizing energy and timing
4. **Spiritually skeptical but data-curious** users

---

## 2. The MVP — What We're Actually Shipping

### MVP definition: "Solo + Relationship Light"

The mobile MVP is the smallest version of Moon Rhythms that:
1. Validates whether the relationship-astrology angle resonates with users (the commercial hypothesis)
2. Can stand on its own in the App Store as a complete experience
3. Is shippable in weeks, not months

**MVP scope — what's IN:**

- Sign up / sign in (Supabase Auth, Google + Apple Sign In + email/password)
- Birth data collection (date, time, location with Google Places autocomplete)
- Natal chart calculation via Swiss Ephemeris (already working on web — port or share)
- Natal chart visualization (read-only, simple but professional)
- AI chat about self ("@advisor what does my Moon in Scorpio mean for me right now?")
- **Add a relationship** (paid feature — user enters partner's birth data; partner does NOT need to join)
- AI chat about the relationship in solo mode ("@advisor why does my partner shut down when I bring up money?")
- Free tier: 5 AI messages, basic profile, no relationships
- Paid tier: unlimited messages, multiple relationships, longer context, deeper synthesis
- Subscription paywall (annual plan with 3-day free trial)
- Settings (account, billing, sign out, delete account)

**MVP scope — what's OUT (build later):**

- Invited partner mode (partner joins the chat)
- Group/family relationships
- Proactive AI messages, transit alerts, daily check-ins
- Quizzes (the deeper psychological data beyond the chart)
- Composite charts
- Human Design integration
- Public sharing / social features
- Web feature parity (web app stays as it is during mobile MVP push)
- Push notifications for anything except sign-in verification
- In-app astrologer marketplace, custom GPTs, or any of the higher-tier ideas

### MVP success criteria

- Submitted to App Store within target timeline (Beau to confirm date)
- Approved by Apple on first or second submission
- 100 paying users within 30 days of launch
- 50%+ retention at day 7
- 30%+ retention at day 30
- Median user has at least one relationship added within their first paid week (validates the moat)

### Path to MVP — phase-by-phase build order

This is the recommended sequence. Each phase ships something testable.

**Phase 0 — Audit and reconciliation** (current)
Run the audit, produce `CURRENT_STATE.md`, identify gaps.

**Phase 1 — Database foundation**
Deploy the deterministic spine. Build the user-data tables. Wire up Supabase Auth properly. **This is the second priority Beau called out.**

**Phase 2 — Mobile auth and onboarding**
Sign up flow, birth data collection, account creation. End state: a user can create an account in the mobile app and have their birth data persist.

**Phase 3 — Chart calculation pipeline**
Swiss Ephemeris integration on mobile (or shared edge function with web). Profile synthesis after birth data is entered. End state: a user with birth data has a synthesized profile in the database within seconds of signup.

**Phase 4 — Solo AI chat**
Knowledge corpus loaded, RAG retrieval working, edge function for AI assembly, mobile chat UI. End state: a user can ask the AI about themselves and get a personalized response with citations.

**Phase 5 — Subscriptions**
RevenueCat or App Store IAP integration. Free vs paid gates. End state: a user can subscribe and see expanded features.

**Phase 6 — Add a relationship (solo mode)**
Paid users can enter a partner's birth data. AI advisor knows about both people. End state: a paid user can ask the AI relationship questions and get advice based on both charts.

**Phase 7 — Polish and submit**
Onboarding optimization, paywall A/B testing, App Store assets, privacy policy, submission. End state: app live in App Store.

Each phase needs Beau's go-ahead before the next one starts. Don't rush phases. A solid Phase 1 makes Phases 2-7 dramatically faster.

---

## 3. Audit Checklist (RUN THIS FIRST)

Before doing anything in this document, Claude Code MUST audit the current state and report findings to Beau. Don't write code until this is done.

### 3.1 Mobile repository audit (PRIMARY)

For `Beausterling/moon-rhythms-mobile`:

- [ ] What's in `package.json`? Confirm Expo version, React Native version, key dependencies.
- [ ] Is this a managed Expo project, bare workflow, or Expo dev client?
- [ ] What navigation library is in use? (Expo Router, React Navigation, etc.)
- [ ] What's the file structure? (app/, src/, components/, screens/, etc.)
- [ ] What state management is in use, if any? (Zustand, Redux, Context only?)
- [ ] What's in the welcome screen Beau is seeing? Is there any onboarding flow scaffolded?
- [ ] Is Supabase client integrated? Where are credentials stored?
- [ ] Is Swiss Ephemeris integrated on mobile? If yes, how? (Native module, edge function call, web wrapper?) Beau wasn't sure.
- [ ] Are there any existing API calls happening in the mobile app?
- [ ] What styling approach? (StyleSheet, NativeWind/Tailwind, styled-components?)
- [ ] What testing setup, if any? (Jest, Detox, none?)
- [ ] Are there any environment variable patterns set up? (.env files, EAS secrets?)
- [ ] What's the iOS bundle identifier? Android package name? (Important for App Store / Play Store later.)
- [ ] What linting/formatting is configured? (ESLint, Prettier, etc.)

### 3.2 Web repository audit (SECONDARY — for reference only)

For `Beausterling/moon-rhythms`:

- [ ] Confirm framework (Next.js? Vite? Other?)
- [ ] How is Swiss Ephemeris integrated? (Direct import, edge function, separate service?) Beau confirmed it works — **document the pattern so we can reuse it on mobile.**
- [ ] What chart calculation logic exists and where?
- [ ] What auth pattern is in use? (Supabase client SDK, custom?)
- [ ] What pages currently exist?
- [ ] Is there any AI chat integration? If yes, document it.

### 3.3 Supabase audit (CRITICAL)

This is what Phase 1 will build on. Be thorough.

- [ ] List all existing tables in the `public` schema. For each: column names, types, FKs, indexes.
- [ ] List all RLS policies on each table.
- [ ] List all edge functions. For each: what does it do, what does it call, what does it return.
- [ ] List all database functions/triggers.
- [ ] What extensions are enabled? Specifically: is `pgvector` enabled? Is `pg_cron` enabled?
- [ ] What auth providers are configured? (Email, Google, Apple, etc.)
- [ ] Are there migrations tracked anywhere? (Supabase CLI migrations folder, or only manual changes via dashboard?)
- [ ] How many users currently exist? (Just count — no PII export.)
- [ ] What's the current Supabase plan? (Free, Pro, Team — affects rate limits and features.)

### 3.4 Integrations audit

- [ ] Is OpenAI / Anthropic / any LLM provider integrated anywhere? Where are API keys stored?
- [ ] Is Google Places API integrated? Where? Where's the key stored?
- [ ] Are there any other third-party services configured? (Sentry, PostHog, Mixpanel, etc.)

### 3.5 Output of audit

After completing the audit, produce a markdown report titled `CURRENT_STATE.md` in the root of the **mobile repo** with the findings, organized by section. Then **stop and ask Beau** for direction before proceeding to any actual development work.

If anything in the audit reveals a conflict with this document's "target state" architecture, flag it explicitly. We'd rather find conflicts now than after writing code.

---

## 4. Architecture (Target State)

This describes where we're going. Section 2 tells you what slice to build for MVP; this section gives you the full picture so you understand how the slice fits.

### 4.1 The data domains

Moon Rhythms has three conceptually separate data domains. Don't mix them:

- **User domain** — accounts, charts, quiz responses, individual profile data, subscriptions
- **Knowledge domain** — astrological reference data (deterministic tables) and interpretive content (RAG chunks)
- **Interaction domain** — relationships between users, chat threads, AI responses

### 4.2 The deterministic spine

Reference data (planets, signs, houses, aspects, dignities, decans, lunar phases) lives in dedicated `astro_*` tables. These are seeded once and read-only at runtime. They are NOT in the RAG vector database — they're structured lookups.

Files that define this layer (already designed, ready to deploy):
- `deterministic_data.json` — single source of truth, ~56KB
- `deterministic_schema.sql` — Postgres schema with 15 tables, FKs, indexes, RLS
- `deterministic_data_seed.sql` — idempotent seed script
- `user_preferences_schema.sql` — user override capability (defaults all hardcoded for MVP, but the override pipe is in place)

Defaults locked in for MVP: **Placidus house system, tropical zodiac, modern rulerships (Pluto rules Scorpio, Neptune rules Pisces, Uranus rules Aquarius), true node, mean Lilith, major aspects only.**

These defaults are encoded in the `astro_app_settings` table. User overrides are supported by the schema but not exposed in any UI for MVP.

### 4.3 The user data tables (Phase 1 priority)

These tables don't exist yet. Phase 1 builds them. Schema design — to be implemented as a migration:

```
public.users
  Mirrors auth.users with app-specific fields. Uses Supabase Auth's UUID.
  - id (UUID, PK, references auth.users)
  - email
  - first_name (required)
  - last_name (optional)
  - plan_tier ('free' | 'paid')
  - astro_preferences (JSONB, for the override system)
  - created_at, updated_at, deleted_at

public.charts
  A user's natal chart. One per user for self; others for relationships.
  - id (UUID, PK)
  - user_id (FK to public.users, nullable for partner-only charts)
  - owned_by_user_id (FK — for partner charts owned by a paid user)
  - subject_label ('self' | 'partner' | 'parent' | 'child' | 'other')
  - subject_name (string, the name of the person this chart is for)
  - birth_date (date)
  - birth_time (time, nullable if unknown)
  - birth_time_unknown (boolean — flag for chart confidence)
  - birth_location_label (string — the human-readable location)
  - birth_latitude, birth_longitude (numeric)
  - birth_timezone (string — IANA timezone)
  - utc_offset_minutes (integer — computed)
  - raw_chart_json (JSONB — full Swiss Ephemeris output)
  - calculated_at, created_at, updated_at

public.user_profile_chunks
  Synthesized text describing this user's astrology. Pre-computed.
  - id (UUID, PK)
  - user_id (FK to public.users)
  - tier ('moon_emotional_os' | 'relational_style' | etc.)
  - chunk_key (e.g., 'moon_saturn_square')
  - chunk_text (the synthesized text)
  - embedding (vector(1536) — for hybrid retrieval later)
  - source_refs_json (JSONB — which raw data produced this chunk)
  - prompt_version (string — which synthesis prompt produced this)
  - generated_at

public.relationships
  A connection between a paid user and another person (with or without their own account).
  - id (UUID, PK)
  - owner_user_id (FK to public.users — the paid user)
  - partner_user_id (FK to public.users, nullable if partner hasn't signed up)
  - partner_chart_id (FK to public.charts)
  - relationship_label (string — 'partner', 'mom', 'best friend', etc.)
  - settings_json (JSONB)
  - created_at, updated_at, deleted_at

public.relationship_profile_chunks
  Synthesized synastry text per relationship.
  - id (UUID, PK)
  - relationship_id (FK)
  - chunk_key, chunk_text, embedding, source_refs_json, prompt_version, generated_at

public.chat_messages
  All messages in any chat (solo or relationship).
  - id (UUID, PK)
  - relationship_id (FK, nullable for solo chats)
  - user_id (FK — whose chat this is, even for solo)
  - sender_type ('user' | 'ai')
  - sender_user_id (FK, nullable if AI)
  - content (text)
  - created_at

public.ai_responses
  Logging table for every AI generation. Crucial for cost tracking and citations.
  - id (UUID, PK)
  - message_id (FK to chat_messages — the AI message this corresponds to)
  - model_used (string)
  - prompt_version (string)
  - retrieved_chunks_json (JSONB)
  - prompt_tokens, completion_tokens (integers)
  - cost_cents (integer)
  - latency_ms (integer)
  - created_at

public.ai_response_citations
  Which chunks informed which response — drives the "N insights" UI.
  - id (UUID, PK)
  - ai_response_id (FK)
  - chunk_source ('user_profile' | 'relationship_profile' | 'knowledge')
  - chunk_id (UUID — refers to whichever chunks table)
  - rank (integer — order of relevance)

public.subscriptions
  Subscription state. Synced from RevenueCat or App Store webhooks.
  - id (UUID, PK)
  - user_id (FK)
  - status ('active' | 'expired' | 'cancelled' | 'trial')
  - product_id (string)
  - started_at, expires_at, cancelled_at
  - source ('apple' | 'google' | 'stripe' | 'admin')
  - external_id (string — RevenueCat customer ID or similar)
```

RLS policies for all of these: a user can only read/write rows where they own the relevant FK. Partner data accessed via `relationships` table joins, with explicit policies that allow paid users to read their owned partners' charts.

### 4.4 The interpretive layer (RAG)

Astrological interpretations (what Moon in Leo *means*, what Saturn square Mars *feels like*) live in a `public.knowledge_chunks` table with pgvector embeddings.

```
public.knowledge_chunks
  - id (UUID, PK)
  - chunk_key (string, unique — e.g., 'planet_mars_nature')
  - title (string)
  - body (text)
  - embedding (vector(1536))
  - source_ref (string — citation to original PD source)
  - keywords (text[])
  - chunk_category (string — 'planet', 'sign', 'house', 'aspect', 'framework', 'synastry')
  - prompt_version (string — which modernization prompt produced this)
  - created_at, updated_at
```

For MVP we use a **hybrid retrieval model**: full user profile is always included in AI context (since it's small), and RAG retrieval is used only for the larger knowledge corpus. Document this in code comments where retrieval happens.

The corpus starts with the existing 31 chunks in `sepharial_chunks_v1.json`. Don't expand it without Beau's review — chunk quality is a product decision.

### 4.5 The AI assembly pipeline

When a user asks the AI a question, the edge function does:

1. Receive the message via authenticated request
2. Look up the user's profile chunks (full set, since it's small)
3. If a relationship chat: look up the partner's profile + the synastry profile
4. Embed the user's question
5. Pull top-N matching chunks from `knowledge_chunks` via pgvector cosine similarity
6. Pull recent chat history (last ~15 messages) and rolling memory summary (if exists)
7. Assemble: system prompt + retrieved context + question
8. Call the LLM with structured output requesting `{response, citations}`
9. Stream response back to client
10. Insert `chat_messages` row, `ai_responses` row, and `ai_response_citations` rows
11. Client UI renders the response and the "N insights" chip

### 4.6 The relationship chat feature (the commercial moat)

For MVP, only **solo relationship mode** is built. The full design has three modes (solo, invited, dual-paid) but we are explicitly NOT building invited mode for MVP.

In solo relationship mode:
- The paid user enters their partner's birth data (and optionally a name/label)
- A chart is calculated for the partner and stored in `public.charts`
- A relationship row links the paid user to that partner chart
- A synastry profile is synthesized (one-time AI call to produce the relationship interpretation)
- The paid user can chat with the AI about that relationship
- The partner is never notified, never has access, doesn't need to know the app exists

This delivers the product's commercial value (relationship advice) without requiring the friction of partner onboarding. Once we know the relationship advisor experience is loved, we earn the right to build invited mode.

---

## 5. Current Active Task

**This is the only thing Claude Code should be working on right now. Do not work on anything else without Beau's explicit approval.**

### Active task: Audit and reconciliation (Phase 0)

**Goal:** Produce `CURRENT_STATE.md` in the root of the **mobile repo** documenting what exists today across mobile, web, and Supabase, then stop and wait for Beau.

**Why first:** This document was written without access to the actual codebase or Supabase project. Before any of the design artifacts get applied, we need to know what's already built, what's already in Supabase, and where the gaps are. Building blindly risks duplicating, conflicting with, or destroying existing work.

**Steps:**

1. Run the full Audit Checklist in Section 3.
2. Produce `CURRENT_STATE.md` in the mobile repo root with findings, organized by section (mobile repo, web repo, Supabase, integrations).
3. Identify any conflicts between this document's target architecture and what already exists.
4. Stop. Ask Beau to review before proceeding to Phase 1.

### Next probable task (DO NOT START until Phase 0 is approved)

**Phase 1 — Database foundation.** This is what Beau called out as the second priority. The likely first sub-tasks within Phase 1:

- **1a:** Deploy `deterministic_schema.sql` and `deterministic_data_seed.sql` to Supabase
- **1b:** Deploy `user_preferences_schema.sql`
- **1c:** Create the user-domain tables described in Section 4.3 (`public.users`, `public.charts`, etc.)
- **1d:** Set up RLS policies on all new tables
- **1e:** Create the `public.knowledge_chunks` table and load the 31 starter chunks

Sub-tasks within Phase 1 should be individual migrations that get committed to the mobile repo (or wherever the team standardizes migrations — confirm in audit).

---

## 6. Mobile-Specific Build Conventions

Rules that apply to anything Claude Code builds in the mobile app.

### 6.1 Performance is a feature

A 2-second loading state on mobile feels like 5 seconds on web. Design every interaction for instant feedback:

- **Optimistic UI:** When a user sends a chat message, render it immediately, then reconcile with the server response.
- **Skeleton states:** Never show a blank screen during loading. Always show structure with placeholder content.
- **Debounce expensive operations:** Birth-data validation, location autocomplete, and chart recalculation all need debouncing.
- **Cache aggressively where safe:** A user's natal chart doesn't change. Cache it locally after first calculation. Profile chunks are similarly stable.

### 6.2 Network awareness

- **Detect connectivity:** Use Expo's `NetInfo` to know when the user is offline. Surface gracefully — never crash on no-network.
- **Queue actions when offline:** If a user sends a chat message while offline, queue it. Send when reconnected. Show a clear "queued" indicator.
- **Minimize round trips:** A flow that takes 3 API calls on web should be re-architected to take 1 on mobile when possible. Edge functions can do compound operations server-side.

### 6.3 Edge function design for mobile

- **One round trip per user action.** If sending a chat message requires (a) saving the message, (b) running retrieval, (c) calling the LLM, and (d) saving the response — do all of that in one edge function call. Don't make the client orchestrate.
- **Stream where you can.** LLM responses should stream token-by-token to the mobile client. Users perceive streaming responses as 2-3x faster than waiting for completion.
- **Return only what's needed.** Don't return raw chart JSON to the client — return only the summary fields needed for that screen.

### 6.4 Local storage strategy

- **What gets stored locally on the device:**
  - Auth tokens (via Supabase's session storage)
  - User's own birth data, chart, and profile chunks (cached after first load — they don't change)
  - Most recent chat threads and last 50 messages per thread (for instant load)
  - User preferences

- **What does NOT get stored locally:**
  - Other people's data (partner charts, etc.) — fetch fresh
  - Knowledge corpus chunks — too large, fetched on demand via edge functions
  - AI response history beyond the recent cache

- **Storage tool:** Use Expo's `SecureStore` for tokens, `AsyncStorage` (with MMKV if performance is needed later) for other cached data.

### 6.5 Auth and session handling

- Supabase JS client handles most of this, but be careful with:
  - Session refresh on app foreground (Supabase doesn't auto-refresh in mobile background)
  - Sign out clearing all local cache (don't leak previous user's data into next user's session)
  - Apple Sign In integration follows Apple's specific UX requirements

### 6.6 No web fallback rendering

This is a native app, not a webview wrapper. Don't render webviews for any core feature. The chart visualization should be SVG via React Native SVG. The chat UI should be native components. If a feature is too complex to do natively, scope it down — don't fall back to a webview.

### 6.7 App Store readiness from day one

Every screen needs to be App Store-presentable. That means:
- No "Lorem ipsum" placeholders
- No console errors visible to users
- No crashes on the iOS Simulator with default settings
- No "[object Object]" appearing anywhere
- All copy follows brand voice rules
- All images have @2x and @3x assets if needed

---

## 7. General Build Conventions

Rules that apply across mobile, web, and backend.

### 7.1 Database changes

- All schema changes go through proper migration files. Never edit the database directly through the Supabase dashboard for schema changes. Migrations get committed to the repo.
- Use the format `migrations/YYYYMMDDHHMMSS_description.sql` or whatever Supabase CLI convention the audit reveals.
- Every new table gets RLS policies before anything goes to production. Default-deny is safer than default-allow.
- Reference data tables (the `astro_*` tables) are read-only for the application. Only seeded via migrations.

### 7.2 Edge functions

- Every edge function that calls an LLM logs: which model was used, prompt version, prompt token count, completion token count, retrieved chunks, latency, and approximate cost. This goes in `public.ai_responses`.
- Every edge function returns structured errors. Never let raw exceptions reach the client.
- Edge functions should be small and single-purpose. If a function is doing five things, split it.
- Edge functions should accept a typed request body and return a typed response. Use TypeScript end-to-end.

### 7.3 AI prompt management

- System prompts live in version-controlled files in the repo, not as inline strings in edge functions. This makes them diffable.
- Every system prompt has a `prompt_version` field. When a prompt changes, the version increments. AI responses log which version they used.
- The voice modernization prompt (for chunk generation) is in `prompts/voice_modernization_v1.md`. Match this convention for other prompts.

### 7.4 Privacy

- A user's quiz responses are private. They never appear verbatim in shared chat output. The AI may use them as background understanding but never quote them.
- Citations expose insight counts ("2 insights") not insight content for partner data unless that partner has explicitly shared.
- Birth data of a partner who hasn't created an account is owned by the inviting paid user. If the partner later creates an account and claims their profile, control transfers to them.

### 7.5 Voice consistency

Apply the voice rules from Section 1 to **every** user-facing string:
- AI chat responses
- Onboarding copy
- Settings descriptions
- Error messages
- Email/notification copy
- Marketing-adjacent strings

If a string sounds like it came from a generic horoscope app, rewrite it.

### 7.6 Cost discipline

We are pre-revenue. Every LLM call is real money.

- Default to a smaller model (Claude Haiku or GPT-4o-mini) for casual chat unless quality demands more.
- Use the premium model (Claude Opus or GPT-4o) only for the `@advisor` mediation moments — those are rare and high-stakes.
- Pre-synthesize anything you can. A user profile written once and reused across thousands of AI calls is dramatically cheaper than reading raw chart data every time.
- Cap chat context at ~15 recent messages + rolling summary. Don't send 1,000-message histories.

### 7.7 Don't go off-script

This document defines the architecture. If you (Claude Code) think a different approach would be better, stop and discuss with Beau before implementing it. Architectural drift in early-stage products is how they end up unshippable.

---

## 8. Out of Scope for MVP

These came up in design conversations but are explicitly NOT MVP. Don't build them. Don't even prepare for them. They live in the roadmap, not the codebase.

- **Invited partner mode** (the partner joins the chat) — Phase 8+
- **Proactive AI messages** (daily check-ins, transit alerts, conflict detection)
- **Group chats** with more than two humans
- **Quizzes** beyond the chart itself (the deeper psychological data layer)
- **Composite charts** (the third-chart-from-two-people calculation)
- **Asteroids** beyond Chiron and Black Moon Lilith (Ceres, Pallas, Juno, Vesta)
- **Vedic / sidereal mode** (the override exists in the schema but no UI surfaces it)
- **Human Design integration** (has copyright concerns)
- **Public sharing** of charts or anything social-feed style
- **In-app astrologer marketplace** or commissioned readings
- **Web feature parity** during the MVP push (web app stays at its current state)
- **Push notifications** for anything except sign-in verification
- **AI image generation** of charts/avatars
- **Custom GPTs per user** as a user-facing feature (we may use them internally for synthesis)

If a user requests one of these, log it as feedback. Don't pivot to building it.

---

## 9. Public Domain Corpus Status

A working corpus pipeline exists as design artifacts. None of it has been deployed yet.

**Files that exist (in this conversation's outputs, not yet in repo):**
- `public_domain_astrology_corpus.md` — research scouting report
- `voice_modernization_prompt.md` — prompt spec for converting PD text to chunks
- `sepharial_raw_extracted.md` — extracted source material from Sepharial (1920)
- `sepharial_chunks_v1.json` — 31 sample modernized chunks ready for embedding

**Status of the corpus:**
- Sample batch (31 chunks) is hand-written by Beau and Claude using the modernization prompt. Quality is acceptable for v1.
- The full Sepharial book has been extracted but only ~30% has been chunked.
- Alan Leo's *Astrology for All* (the highest-value PD source) has NOT been ingested. This is a post-MVP effort.
- Relationship/synastry content is essentially absent from PD sources. This is where commissioned astrologer content will be needed for the relationship advisor to feel rich. Plan to budget for this once MVP is shipped.

**What Claude Code should do with the corpus during MVP:**
- During Phase 1: load the existing 31 chunks into the `public.knowledge_chunks` table once it exists.
- Generate embeddings for those 31 chunks via OpenAI `text-embedding-3-small`.
- Do NOT scrape any modern websites for additional content. This was discussed and rejected for IP reasons.
- Do NOT add new chunks without Beau's review.

---

## 10. Open Questions Beau Owes Answers To

These need decisions before later work proceeds. Listed in roughly the order they'll come up.

1. **LLM provider for the @advisor tier.** Claude Opus, GPT-4o, or test both? Cost vs quality call. Decide before Phase 4.
2. **Payments processor.** RevenueCat for cross-platform subscription management is strongly recommended for mobile. Stripe direct works but iOS in-app purchase rules require Apple's IAP for subscriptions consumed in-app. Decide before Phase 5.
3. **Pricing model.** Annual subscription with 3-day free trial was discussed. Confirm exact pricing tiers before Phase 5.
4. **Brand name lock-in.** "Moon Rhythms" is current. "MoonMynd" was being explored. Lock this before App Store assets get built (Phase 7).
5. **App Store target submission date.** Drives every prior phase's pace.
6. **Apple Developer account status.** Is the account set up? Beau enrolled? Bundle identifier reserved?
7. **Astrologer hire for synastry content.** Budget allocated? When does this get sourced? Important for v2 feature richness, not blocking MVP.
8. **Analytics tooling.** PostHog, Mixpanel, Amplitude, or just App Store Analytics? Decide before Phase 7.
9. **Crash reporting.** Sentry recommended — confirm before Phase 7.

---

## 11. Decision Log

Append-only history of architectural and product decisions. Newest at the top.

### 2026-04-29 — v2.0: Mobile-first reframe

- Reframed the entire document around mobile being the priority. Web app stays as-is during MVP push.
- Defined MVP scope as "Solo + Relationship Light": solo natal chat + paid users can add a relationship in solo mode (no partner participation). Invited partner mode is post-MVP.
- Defined seven-phase build path: Audit → Database Foundation → Mobile Auth/Onboarding → Chart Pipeline → Solo AI Chat → Subscriptions → Relationship Mode → Polish/Submit.
- Specified the user data tables (`public.users`, `public.charts`, `public.relationships`, `public.chat_messages`, `public.ai_responses`, etc.) for Phase 1 build.
- Added mobile-specific build conventions (performance, network awareness, local caching, edge function design for mobile).
- Added mobile-specific success criteria and App Store readiness rules.

### 2026-04-29 — v1.0: Initial document creation

- Created this master document as the source of truth for Claude Code collaboration.
- Locked in MVP defaults: Placidus, tropical zodiac, modern rulerships, true node, mean Lilith, major aspects only.
- Locked in the hybrid RAG approach: full user profile in context, RAG only for knowledge corpus.
- Decided against scraping any modern astrology websites for content. PD only + commissioned writing.
- Decided to build user preference override capability into the schema even though no UI exposes it for MVP.
- Decided the relationship chat feature is the commercial moat and gets priority over general-astrology features.
- Voice rules locked in: no mystical language, no benefic/malefic framing, ungendered, practical/psychological.
- Citations decided as a UI feature: "N insights" chips that reveal underlying chunks on tap.

### Pending entries

(Claude Code adds entries here as decisions get made during implementation.)

---

## 12. Reference Files Inventory

These design artifacts live separately and should be read by Claude Code as needed during specific tasks. They are NOT yet in the repos. Beau will need to import them.

| File | Purpose | When to read it |
|------|---------|-----------------|
| `deterministic_data.json` | Source of truth for all astrological reference data | Phase 1 |
| `deterministic_schema.sql` | Postgres schema for the deterministic tables | Phase 1 |
| `deterministic_data_seed.sql` | Seeds the `astro_*` tables | Phase 1 |
| `user_preferences_schema.sql` | User override capability | Phase 1 |
| `sepharial_chunks_v1.json` | 31 starter knowledge chunks | Phase 1 (last sub-task) |
| `voice_modernization_prompt.md` | Spec for generating new chunks from PD sources | Post-MVP |
| `public_domain_astrology_corpus.md` | Research on PD sources | Post-MVP |
| `sepharial_raw_extracted.md` | Raw source text from Sepharial 1920 | Post-MVP |

**Recommended import location in the mobile repo:**

```
/docs/
  master-build-doc.md          (this document)
  current-state.md              (created by audit)
/data/
  deterministic_data.json
  sepharial_chunks_v1.json
/supabase/migrations/           (or wherever the audit reveals migrations live)
  YYYYMMDDHHMMSS_astro_schema.sql
  YYYYMMDDHHMMSS_astro_seed.sql
  YYYYMMDDHHMMSS_user_prefs.sql
  YYYYMMDDHHMMSS_user_data_tables.sql
  YYYYMMDDHHMMSS_knowledge_chunks.sql
/prompts/
  voice_modernization_v1.md
/research/
  public_domain_astrology_corpus.md
  sepharial_raw_extracted.md
```

This is a suggestion. If the existing repo has different conventions, follow those.

---

## End of document

If anything in this document is unclear, contradictory, or incomplete, tell Beau. Don't guess. Don't fill in blanks with assumptions.
