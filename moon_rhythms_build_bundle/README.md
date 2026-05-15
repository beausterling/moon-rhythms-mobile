# Moon Rhythms — Build Artifacts Bundle

**What this is:** All design artifacts, schemas, prompts, and reference data produced for Moon Rhythms during architecture/design sessions. This is the complete output of the design phase — ready to be imported into the codebase.

**Status:** None of these have been deployed to Supabase or committed to the repos yet. They are inputs to Phase 1 of the build, not deployed artifacts.

---

## Files in this bundle

### Start here

| File | What it is |
|------|------------|
| `claude_code_kickoff_prompt.md` | The prompt to paste into Claude Code to start the Phase 0 audit. Self-contained — Claude Code doesn't need anything else for the audit step. |
| `master_build_doc.md` | The master build document. Add this to the mobile repo at `docs/master-build-doc.md` after the audit is complete. |

### Database — deterministic spine (Phase 1)

| File | What it is |
|------|------------|
| `deterministic_data.json` | Single source of truth for all astrological reference data: planets, signs, houses, aspects, dignities, decans, lunar phases, synastry rules. ~56KB. Validated end-to-end. |
| `deterministic_schema.sql` | Postgres schema for the deterministic tables. 15 tables with FKs, indexes, RLS policies. Tested against fresh Postgres 16. |
| `deterministic_data_seed.sql` | Idempotent seed script that loads `deterministic_data.json` into the schema. Safe to re-run after edits. |
| `user_preferences_schema.sql` | User override capability. All defaults are hardcoded for MVP (Placidus, tropical zodiac, modern rulerships) but the override pipe is in place for the future. |

### Knowledge corpus — RAG layer (Phase 1, end)

| File | What it is |
|------|------------|
| `sepharial_chunks_v1.json` | 31 modernized astrological interpretation chunks, ready for embedding and ingestion into a `knowledge_chunks` table. Voice-edited from public domain Sepharial 1920 source. |
| `voice_modernization_prompt.md` | The prompt spec for converting public domain text into chunks that match Moon Rhythms' brand voice. Use post-MVP for Alan Leo and other PD source ingestion. |
| `sepharial_raw_extracted.md` | Raw interpretive content extracted from Sepharial 1920 before modernization. Reference material for the chunk pipeline. |
| `structured_facts.json` | Reference document showing which Sepharial content is *structured fact* (goes in deterministic tables) vs *interpretive content* (goes in RAG corpus). Architectural reference. |
| `public_domain_astrology_corpus.md` | Research scouting report on public domain astrology sources (Alan Leo, Sepharial, Raphael, Ptolemy, etc.). Coverage map showing what PD covers well vs poorly. |

---

## How to use this bundle

### Step 1: Run the audit

1. `cd` into your `moon-rhythms-mobile` repo locally
2. Run `claude` to open Claude Code
3. Paste the entire content of `claude_code_kickoff_prompt.md` as your first message
4. Wait for Claude Code to produce `CURRENT_STATE.md`
5. Review the audit findings

### Step 2: Import the design artifacts (after audit review)

Recommended folder structure in the mobile repo:

```
/docs/
  master-build-doc.md           ← from this bundle
  current-state.md              ← created during audit
/data/
  deterministic_data.json
  sepharial_chunks_v1.json
  structured_facts.json
/supabase/migrations/
  YYYYMMDDHHMMSS_astro_schema.sql      ← deterministic_schema.sql
  YYYYMMDDHHMMSS_astro_seed.sql        ← deterministic_data_seed.sql
  YYYYMMDDHHMMSS_user_prefs.sql        ← user_preferences_schema.sql
/prompts/
  voice_modernization_v1.md     ← voice_modernization_prompt.md
/research/
  public_domain_astrology_corpus.md
  sepharial_raw_extracted.md
```

If your repo has different conventions revealed by the audit, follow those instead.

### Step 3: Hand the master doc to Claude Code for Phase 1

Once the audit is reviewed and the artifacts are imported, your next prompt to Claude Code will be:

> Read `docs/master-build-doc.md` in full, then begin Phase 1 (Database Foundation) following the sub-tasks in Section 5 of that document. Stop after each sub-task and confirm with me before continuing.

---

## Key context if anyone unfamiliar reads this

- **Moon Rhythms** is an astrology app. The mobile app is the priority surface.
- **MVP** is "Solo + Relationship Light": solo natal chat + paid users can add a relationship and chat about it (without the partner participating).
- **Tech stack:** React Native (Expo) for mobile, Supabase for backend (Postgres + Auth + Edge Functions + pgvector for RAG).
- **Brand voice:** modern, grounded, warm. No mystical language. No fate-talk.
- **What's NOT in MVP:** invited partner mode, group chats, proactive AI messages, quizzes, composite charts, push notifications, public sharing.

---

## Document version

This bundle was produced 2026-04-29. The master build doc inside is v2.0.
