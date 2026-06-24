# Moon Rhythms Numerology Spine — Research & Coverage Report

**Artifact:** `systems/numerology_data.json`
**Generated:** 2026-06-23
**System:** Pythagorean (default) + Chaldean (reference alternate)
**Validation:** `python3 -c "import json; json.load(open('numerology_data.json'))"` passes. Pythagorean letter map verified byte-equal to the app's `lib/numerology.js` `LETTER_VALUES`. Birthday table verified to contain all days 1-31.

---

## 1. What this file is

A deterministic structured-lookup spine for the numerology system, mirroring the *approach* of the existing astrology spine (`deterministic_data.json`): one JSON source of truth, `_schema` strings per section, a `metadata.design_decisions` block, and short grounded descriptors only. Interpretive long-form prose stays out of this file (it belongs in the RAG corpus).

Two jobs were done:

1. **Extract** — encode the app's existing engine (`lib/numerology.js`) so its current output is reproducible from this data: Pythagorean letter values, vowel set, both reduction modes, and every core formula and meaning table the app ships.
2. **Expand** — add the rest of a comprehensive numerology spine via fresh web research, cross-checked against at least two reputable sources per topic.

---

## 2. Sources (all accessed 2026-06-23)

Numerology is a slow-moving, doctrinal domain. None of these reference pages carry meaningful publish dates; they are evergreen. The real risk is *which variant a source uses*, not recency, so every variant split was checked explicitly and documented. Today's date: **2026-06-23**. Freshest dated signal found: tokenrock Life Path page labeled "(2026 Update)" and numerology.com cross-linking a "2026 reading", confirming both sites are live/maintained in 2026.

**Primary / authoritative**
- World Numerology — Hans Decoz (`worldnumerology.com`): single-digit numbers, master numbers, birthday numbers, pinnacles, challenges, period cycles, karmic debt/lessons, hidden passion, bridges, essence cycles, Y/W vowel rule. *Note: this site returns HTTP 403 to automated fetch (anti-bot). Its definitions were captured via its own search-result snippets and corroborated by independent sources; a few pages (pinnacles, challenges, period cycles) were fetched live successfully. Decoz is the canonical Western/Pythagorean reference and the basis for most timing conventions encoded here.*
- numerology.com: single-digit meanings, birthday 1-31, core-number framings, Life Path meanings, Life Path compatibility matrix.
- tokenrock.com: reduction rule, Life Path, pinnacle timing prose.
- affinitynumerology.com: hidden passion (+ tie-break algorithm), personal year/month/day chain, pinnacles, essence/transit.
- numerology.center: bridge numbers (full 0-8 scale), transit/essence mechanic, pinnacle cycles.
- feliciabender.com (Decoz school): pinnacle number meanings, pinnacle age timing, challenge themes.

**Corroborating / variant-documenting**
- chaldeannumerologycalculator.com, thelawofattraction.com, professionalnumerology.com — Chaldean and Pythagorean letter tables.
- astronumero.org — documents the non-standard "improved" Chaldean variant (assigns 9).
- dcode.fr — Pythagorean sequence.
- seventhlifepath.com, numerologist.com — Y/W vowel rule, karmic lessons, compatibility.
- sunsigns.org, centreofexcellence.com, prokerala.com — karmic debt themes, karmic lessons.
- almanac.com — Personal Year.
- sarahyip.com, flameofthenorth.com, mindbodygreen — the 44-as-master minority view.

---

## 3. Coverage map: deterministic vs interpretive

| Section | Nature | Computable deterministically? |
|---|---|---|
| Pythagorean / Chaldean letter tables | Deterministic | Yes, exact |
| Vowel/consonant split (app convention) | Deterministic | Yes (app: a,e,i,o,u; Y,W consonant) |
| Vowel/consonant split (phonetic Y rule) | Partly deterministic | No, needs syllable analysis; approximation documented |
| Reduction rules (both modes) | Deterministic | Yes, exact |
| Life Path, Expression, Soul Urge, Personality, Birthday, Maturity | Deterministic | Yes, exact (matches app) |
| Personal Year / Month / Day | Deterministic | Yes (Year matches app; Month/Day are standard extensions) |
| 4 Pinnacles + 36-LP timing | Deterministic | Yes, exact (matches app) |
| 4 Challenges | Deterministic | Yes, exact (matches app) |
| 3 Life Cycles | Deterministic formula; timing has TWO conventions | Yes formula; timing documented twice (see §5) |
| Karmic Debt (13/14/16/19) | Deterministic detection | Yes (pre-reduction total check) |
| Karmic Lessons (missing name numbers) | Deterministic | Yes |
| Hidden Passion / Intensity | Deterministic (+ documented tie-break) | Yes |
| Bridge numbers | Deterministic | Yes |
| Essence / Transit | Deterministic mechanic, moderately sourced | Mostly; edge cases flagged |
| Meaning tables (all contexts) | Lookup data (descriptors) | N/A (static lookup) |
| Life Path compatibility matrix | **Interpretive** | Flagged `is_deterministic: false`; asymmetric |

---

## 4. Extracted from the app vs added from research

**Extracted (exact, reproducible from `lib/numerology.js`):**
Pythagorean `LETTER_VALUES` (verified byte-equal), `VOWELS` set, `reduceToSingle` / `reduceStrict`, master numbers `[11,22,33]`, and the formulas for Life Path, Expression, Soul Urge, Personality, Birthday, Maturity, Personal Year, the 4 Pinnacles (+ `36 - lifePath` timing), 4 Challenges, and 3 Life Cycles. The app's shipped meaning tables (Life Path 1-33 with title+description, Expression, Soul Urge, Personality, Personal Year) are preserved verbatim or lightly de-em-dashed.

**Added from research (cross-checked >=2 sources):**
Chaldean letter table, full vowel/consonant + Y/W rule documentation, Karmic Debt, Karmic Lessons, Hidden Passion/Intensity, Bridge numbers, Personal Month/Day, Essence/Transit method, the full Birthday 1-31 meaning table, Pinnacle and Challenge meaning tables, Maturity meanings, the core single-digit + master meaning table, and the (flagged interpretive) Life Path compatibility matrix.

---

## 5. Key convention decisions (and the alternatives)

1. **System default = Pythagorean.** Chaldean included as a `reference_only` alternate (values 1-8, 9 never assigned to a letter). Standard/Cheiro values used; the disputed letters X and Z fixed at X=5, Z=7. Non-classical "improved" Chaldean variants (which assign 9) explicitly excluded.

2. **Y rule.** The app treats Y (and W) as always a consonant (`VOWELS` = `{a,e,i,o,u}` only). That is the reproducible convention encoded in `vowel_consonant_rules.app_engine_convention`. The phonetically correct rule (Y is a vowel when it carries the only vowel sound of a syllable) and a deterministic adjacency approximation are documented in `standard_phonetic_rule` for any future upgrade, but the app does **not** implement them today. **Open consequence:** Soul Urge / Personality values will differ from "phonetically correct" calculators for names where Y acts as a vowel (Lynn, Yvonne, Mary). This is a real, intentional divergence, flagged.

3. **Master numbers = [11,22,33]**, preserved on intermediate or final sums for core numbers (matches `reduceToSingle`). **44 is NOT a master number** in the canonical school (it is a "Power number"); exposed as `include_44: false`, an optional flag, with sources for the minority view.

4. **Challenges reduce masters away** (single digit 0-8, 0 valid) — the one place master status is dropped; matches the app's use of `reduceStrict`.

5. **Karmic Debt detection = pre-reduction total** equals 13/14/16/19 (reductions 13→4, 14→5, 16→7, 19→1). Classical past-life language reframed as present-tense growth themes in descriptors.

6. **Pinnacle timing = `36 - reduced Life Path`** for the first pinnacle end, then 9-year windows, fourth to end of life. This is canonical Decoz and matches the app exactly. Softer prose ranges ("27-35", "30-35") from other sources are documented as roundings of the same math, not different formulas.

7. **Life Cycle (Period Cycle) timing — DEVIATION FLAGGED.** The app reuses the pinnacle boundary `36 - lifePath` for Period Cycle 1, then a 27-year second cycle, then harvest. The **canonical Decoz rule is different**: Cycle 1 ends at the first Personal Year 1 on or after age 27, Cycle 2 lasts exactly 27 years, Cycle 3 to death. Pinnacles and Period Cycles do **not** share a transition age in the canonical system; the app conflates them. Both are encoded: `life_cycles.app_engine_timing` (reproducible, what the app does) and `life_cycles.canonical_decoz_timing` (documented). **The app code was not changed** (out of scope per instructions).

8. **Personal Year output = single digit 1-9** (matches app), with a note that some schools keep 11/22 as a master Personal Year. Personal Month and Personal Day reuse the Personal Year meaning table.

9. **Compatibility is interpretive.** Encoded with `is_deterministic: false`, master Life Paths reduced for lookup (11→2, 22→4, 33→6), and a note that the published numerology.com matrix is asymmetric (rows do not mirror). Use as a soft heuristic only.

---

## 6. Open questions / ambiguities

- **Decoz exact wording.** `worldnumerology.com` blocks automated fetch; several Decoz definitions were corroborated via snippets + independent sources rather than read firsthand. Claims stand and were cross-checked, but a few descriptor phrasings are reasonable rewrites in Moon Rhythms voice, not verbatim quotes (which is correct for app lookup copy anyway).
- **Essence / Transit edge cases.** The per-letter-duration-equals-its-value mechanic and three-track summation are well sourced. Edge cases — names of unequal length realigning across tracks, and master-number retention inside an Essence — are moderately confident, not firsthand-verified end to end. Flagged in `essence_transit.confidence_note`.
- **Maturity per-number descriptors.** The Maturity *framing* (later-life theme, ~35+) is sourced (Decoz). The per-number one-liners are the confirmed core trait viewed through that lens, not verbatim source text.
- **Personal Year master handling** is a genuine school split (reduce-all vs keep 11/22). The app reduces; documented.
- **Y-as-vowel** remains the single biggest practical divergence from "full-featured" calculators (see §5.2).

---

## 7. Self-assessment of completeness

**Estimated coverage: ~95% of a comprehensive deterministic numerology spine.**

Present and solid: both letter systems, vowel/consonant rules, reduction modes, all six core numbers, the three personal cycles, pinnacles, challenges, life cycles, karmic debt, karmic lessons, hidden passion, bridge numbers, essence/transit, full meaning tables for every core context including the complete 1-31 birthday table and 11/22/33 across all contexts, and a flagged compatibility matrix. Every app formula is reproducible from this data, and the Pythagorean map is verified byte-equal.

**What is deliberately NOT included (the remaining ~5%):**
- A literal Chaldean computation path (table is reference-only; the app does not compute Chaldean).
- Verbatim Decoz body prose for every number/cycle (interpretive, belongs in RAG; this file carries concise lookup descriptors instead).
- Niche/rarely-standardized constructs: Rational Thought number, Balance number, Subconscious Self number, Cornerstone/Capstone/First-Vowel letters, planes of expression. These are real but inconsistent across schools and were left out to keep the spine authoritative rather than speculative. They can be added later with the same cross-check rigor.
- Pinnacle/challenge timing as concrete date ranges per user (the data encodes the rules; the app computes the ages).

**No descriptor string contains emojis or em dashes.** Classical loaded/fatalistic language was neutralized throughout.
