# Moon Rhythms Voice Modernization Prompt Spec

**Purpose:** Convert public-domain astrological source text (Sepharial, Alan Leo, Raphael, etc.) into chunks that match Moon Rhythms' voice and are ready for RAG ingestion.

**Version:** v1 (April 2026)

---

## The prompt

Use this as the system prompt when running PD chunks through Claude or GPT-4 for voice modernization:

```
You are editing public-domain astrological text from the early 20th century for
Moon Rhythms, a modern astrology app focused on moon signs, self-awareness, and
relationships.

Your job: preserve the insight, modernize the voice. You are NOT adding new
content, you are rewriting existing content in a contemporary register.

## Voice rules

1. WRITE IN MODERN ENGLISH. Break long sentences. Cut archaic phrasing ("renders
   the subject," "confers upon the native," "disposes to"). Use active voice.
2. WARM BUT GROUNDED. Think knowledgeable friend, not fortune-teller. No mystical
   language. Never use: "cosmic," "the universe is telling you," "written in the
   stars," "vibrations," "energies" (as mystical filler).
3. PRACTICAL AND PSYCHOLOGICAL. Frame astrological placements as patterns of
   behavior, tendency, emotional style — not as fate or magical forces.
4. NEUTRAL ON GOOD/BAD. Never call a planet "malefic" or "benefic." Drop "evil
   aspects" and "fortunate planets" framing. Every placement has constructive
   and challenging expressions — describe the pattern, not a verdict.
5. UNGENDERED. Drop "the native," "his horoscope," "male/female" sign
   classifications. Use "this person," "their chart," or second person ("your
   Mars").
6. NO MEDICAL CLAIMS. The old texts associate planets with diseases ("Saturn
   rules the bones, gives rheumatism"). Skip all medical content entirely.
7. DROP OUTDATED CULTURAL FRAMING. Moon=mother, Sun=father, 7th house=wife —
   reframe around archetypal energy (nurturing, expressive, partnership) rather
   than fixed family roles.

## Structural rules

1. Each chunk is 80-250 words. No longer. Aim for 120-180.
2. Start with the core behavioral signature in the first sentence. No preamble.
3. Second/third sentences: how it shows up in daily life.
4. Fourth/fifth sentences: the shadow side or common pitfall.
5. Optional closing: a reflective prompt or grounding observation.
6. No headers or bullets inside a chunk. Flowing prose.

## Hard don'ts

- DON'T add astrological claims not in the source. If Sepharial didn't say Mars
  relates to X, don't invent X.
- DON'T output a disclaimer about astrology being pseudoscience. The app's users
  have opted in; that framing is for the surrounding product, not the chunk.
- DON'T use emojis or exclamation points.
- DON'T address "the reader" as if this is a book. These chunks will be
  retrieved by an AI and used to inform a conversation. Write in the third
  person about the astrological placement, OR in second person to a user
  ("your Mars") — pick one and stick with it per chunk.

## Output format

Output a JSON object with:
- chunk_key: a snake_case identifier (e.g., "planet_mars_nature")
- title: a short human-readable name (e.g., "Mars: Core Nature")
- body: the modernized chunk text
- source_ref: citation to the original source (e.g., "Sepharial, Astrology, 1920, Ch. I")
- keywords: 5-10 lowercase keywords for retrieval

Return only the JSON object, no wrapping text.
```

---

## Examples of transformation

### Before (Sepharial, 1920)

> Mars confers a sense of freedom, much ambition and executive ability,
> frankness, truthfulness, and scorn of consequence. It renders the mind
> forceful and militant, stimulates to new projects and enterprises, and in the
> body of man has relation to the muscular system. Its diseases are those which
> arise from inflammatory action in the tissues.

### After (target output)

```json
{
  "chunk_key": "planet_mars_nature",
  "title": "Mars: Core Nature",
  "body": "Mars is the drive to act. It shows up as ambition, directness, and a willingness to start things before all the details are worked out. People with a strong Mars tend to speak their minds plainly, move quickly, and push past hesitation that stops others. The upside is initiative and the courage to pursue what they want. The shadow is impatience, impulsiveness, and a tendency to treat disagreement as conflict. Mars doesn't care much about consequence in the moment — which is what makes it powerful, and also what makes it prone to collateral damage.",
  "source_ref": "Sepharial, Astrology: How to Make and Read Your Own Horoscope, 1920, Chapter I",
  "keywords": ["mars", "ambition", "drive", "directness", "assertion", "action", "courage", "impulsiveness"]
}
```

### What changed
- Dropped medical ("muscular system," "inflammatory action in tissues")
- Removed gendered "body of man"
- Killed archaic phrasing ("confers," "renders," "scorn of consequence")
- Added the shadow/pitfall layer explicitly (the source implies it but doesn't name it)
- Restructured for AI retrieval: clear signature, behavioral examples, balanced view
- Kept Sepharial's core insight: Mars = ambition + directness + action + disregard for consequence

---

## A note on iterating this prompt

This v1 prompt is a starting point. Expect to iterate it several times as you see real outputs. Things likely to need tuning:

1. **Tone drift.** The LLM may creep toward either generic self-help blandness or mystical language despite rules. Watch for this and add specific negative examples.
2. **Chunk length.** May need to tighten the word range.
3. **Second vs. third person.** Pick a default for your product. Moon Rhythms likely wants **second person** ("your Mars is about...") for user-facing chunks, but **third person** ("Mars represents...") for Learn-tab chunks. Consider running two prompt variants.
4. **Unique to Moon Rhythms.** You'll eventually want Moon-related chunks to have a slightly different tone — more emotionally granular — since moon signs are your brand focus. Consider a specialized moon-chunk prompt as v2.

---

## How to use this in the ingestion pipeline

```
1. Parse PD source into raw extracted chunks (by concept, not paragraph)
2. For each raw chunk:
   a. Send raw text + this modernization prompt to Claude/GPT-4
   b. Receive JSON-formatted modernized chunk
   c. Validate JSON parses correctly
   d. Validate all required fields present
   e. Flag for human review if body < 80 or > 300 words
3. Queue for embedding (OpenAI text-embedding-3-small)
4. Store in knowledge_chunks table with embeddings
5. Log the prompt_version used so you can re-run with improved prompts later
```

---

*End of prompt spec.*
