# Claude Code Kickoff Prompt — Moon Rhythms Phase 0 Audit

**How to use this:** Open Claude Code in the `moon-rhythms-mobile` repo directory (in your terminal: `cd` into the repo, then run `claude`). Paste everything between the lines below as your first message.

---

You are going to help me build Moon Rhythms, an astrology mobile app focused on moon signs, self-awareness, and relationships. Before you write any code, I need you to run an audit and produce a report. After the report, you will stop and wait for me to review.

## Project context

**Mobile is the priority.** The mobile app is React Native (currently runs in Expo Go on iOS Simulator and renders a welcome screen). It lives at `Beausterling/moon-rhythms-mobile` — that's the repo you're working in now.

The web app at `Beausterling/moon-rhythms` exists at moonrhythms.io and has Swiss Ephemeris integrated and functioning. It is a secondary surface during MVP push — don't focus on it.

The Supabase database is shared between web and mobile. Auth is set up with Supabase Auth. Payments are NOT yet integrated.

A full master build document exists and will be added to the repo at `docs/master-build-doc.md` along with several design artifacts (deterministic data SQL files, knowledge chunk samples, etc.). I'll add those after you complete the audit. For now, you have what you need to do the audit work.

## Brand voice (apply to anything user-facing you ever produce)

- Modern, grounded, warm. Not mystical. No "cosmic," "the universe is telling you," "written in the stars," "vibrations," "energies."
- Practical and psychological. Astrological placements are patterns of behavior and tendency, not fate.
- Neutral on good/bad. No "malefic/benefic" or "evil aspects."
- Ungendered. Use "active/receptive" instead of "masculine/feminine signs."
- Knowledgeable friend, not fortune-teller.

## MVP definition

The mobile MVP is "Solo + Relationship Light":
- Solo: user signs up, enters birth data, sees their natal chart, chats with the AI about themselves
- Relationship Light: paid users can enter a partner's birth data and chat with the AI about that relationship in solo mode (the partner is never invited, never participates)

What's explicitly OUT of MVP: invited partner mode, group chats, proactive AI messages, quizzes beyond the chart, composite charts, web feature parity work, push notifications beyond auth, public sharing, in-app astrologer marketplace.

## Your task right now: audit only

Produce a markdown report titled `CURRENT_STATE.md` in the root of this mobile repo with findings organized by section. Do not write any other code, do not modify any files, do not start building anything. After producing the report, stop and tell me what you found.

### What to audit

#### 1. This mobile repository

- What's in `package.json`? Confirm Expo version, React Native version, key dependencies.
- Is this managed Expo, bare workflow, or Expo dev client?
- What navigation library is in use? (Expo Router, React Navigation, etc.)
- What's the file structure? (app/, src/, components/, screens/, etc.)
- What state management is in use, if any? (Zustand, Redux, Context only?)
- What's in the welcome screen I'm seeing? Is there any onboarding flow scaffolded?
- Is Supabase client integrated? Where are credentials stored?
- Is Swiss Ephemeris integrated on mobile? If yes, how? (Native module, edge function call, web wrapper?) — I'm not sure currently.
- Are there any existing API calls happening in the mobile app?
- What styling approach? (StyleSheet, NativeWind/Tailwind, styled-components?)
- What testing setup, if any? (Jest, Detox, none?)
- Are there any environment variable patterns set up? (`.env` files, EAS secrets?)
- What's the iOS bundle identifier? Android package name?
- What linting/formatting is configured? (ESLint, Prettier, etc.)

#### 2. The web repository (reference only)

You won't have direct access to the web repo unless I clone it for you, but if you can: take a quick look at `Beausterling/moon-rhythms` to understand:

- Framework (Next.js? Vite? Other?)
- How Swiss Ephemeris is integrated (direct import, edge function, separate service?) — this pattern needs to be documented so we can reuse it on mobile.
- Auth pattern in use
- Whether any AI chat integration exists

If you can't access the web repo, just note that in your report and I'll fill it in.

#### 3. Supabase audit

This is critical — Phase 1 of the build will create database schema, and we need to know what already exists. If you have Supabase CLI available or credentials, please:

- List all existing tables in the `public` schema with their columns, types, FKs, indexes
- List all RLS policies on each table
- List all edge functions and what they do
- List all database functions and triggers
- Confirm what extensions are enabled (specifically: is `pgvector` enabled? Is `pg_cron` enabled?)
- Confirm what auth providers are configured (Email, Google, Apple, etc.)
- Note whether migrations are tracked anywhere (Supabase CLI migrations folder, or only manual changes?)
- Count current users (just a count — no PII)
- Note the Supabase plan tier (Free, Pro, Team — affects rate limits)

If you don't have Supabase access yet, tell me what you need from me to gain access, and document that as the blocker.

#### 4. Integrations audit

- Is OpenAI / Anthropic / any LLM provider integrated anywhere? Where are API keys stored?
- Is Google Places API integrated? Where? Where's the key stored?
- Are there any other third-party services configured? (Sentry, PostHog, Mixpanel, RevenueCat, Stripe, etc.)

## Output format

Produce `CURRENT_STATE.md` in the root of the mobile repo with:

1. Executive summary (3-5 sentences: where we are right now)
2. Mobile repo findings (organized by the audit categories above)
3. Web repo findings (or "not accessible — needs Beau to clone or grant access")
4. Supabase findings (or list of blockers if access isn't available)
5. Integration findings
6. **Conflicts and questions** — anything you discovered that conflicts with the MVP plan I described above, or that you need me to clarify before next steps

After you produce the report, stop. Don't write any code. Don't start Phase 1. Don't make any changes to Supabase. Just tell me what you found and ask what I want to do next.

## Things to NOT do during this audit

- Do not modify any files in either repo
- Do not run any database migrations
- Do not deploy any edge functions
- Do not install any new dependencies
- Do not commit or push anything
- Do not assume what should be built — that's a separate conversation after the audit
- If you're unsure whether something belongs in the audit, include it. Over-report rather than under-report.

Begin the audit now.
