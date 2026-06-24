# Human Design Mechanical Spine — Research & Coverage Report

**Companion file:** `human_design_data.json` (the deterministic mechanical spine)
**Generated:** 2026-06-23
**Author note:** This report documents how the spine was built, what was extracted vs. verified, the copyright boundary, and a completeness self-assessment.

---

## 1. Purpose & scope

This spine encodes the **deterministic, structured-lookup MECHANICAL data** of the Human Design (HD) system for Moon Rhythms — the same role `deterministic_data.json` plays for the astrology engine. It is consumed by the app's chart engine and the AI prompt assembler. It is **not** RAG content and it deliberately contains **no long interpretive prose**.

The HD calculation in the live web app (`moonrhythms.io`) runs through the `natalengine` npm package, with the definition-type result overridden by a union-find in `pages/api/human-design.api.js`. This spine mirrors exactly what the engine computes, plus verified expansions (degree ranges, hexagram numbers, determination-rule documentation).

---

## 2. Copyright boundary (the rule we followed)

**Encoded (factual mechanical structure — fine to encode):**
gate→I Ching hexagram mapping, gate→center assignments, the 36 channels (gate pairs + centers + names), the 9 centers and their categories, the 5 types with strategy/signature/not-self/aura, the 7 authorities and their precedence, the 12 profiles and their line combinations, the 5 definition types, the 192 named incarnation crosses (64 gates × 3 angles), gate zodiac-degree ranges, the 13 planetary activations and the Design (88°) rule, the 6 line-name archetypes, the gate wheel order + offset.

**Excluded (proprietary / interpretive — OUT):**
- Long interpretive descriptions of gates, channels, centers, types, profiles, or crosses from Jovian Archive or commercial HD books.
- The **384 gate-line interpretive texts** (64 gates × 6 lines). The spine encodes the line *framework* (6 archetype names + degree math) and explicitly flags line-level interpretation as a **RAG / commissioned-content** concern, not a mechanical fact.
- Any verbatim copy of a vendor's prose.

**Descriptor policy:** where a short descriptor appears (a `theme`, `keyword`, `strategy`, `signature`, `not_self`, or one-line `descriptor`), it is brief, factual, and neutral — carried over from the app's own data (which already uses short neutral descriptors) or written in our own words. No emojis in any descriptor string.

---

## 3. Coverage map: mechanical/deterministic (IN) vs interpretive/proprietary (OUT)

| Data | In spine? | Source |
| --- | --- | --- |
| 9 centers (name, theme, biological, pressure, category, connected gates) | IN | natalengine `CENTERS` + derived |
| Center category (motor/pressure/awareness/throat/identity) + defined/undefined mechanics | IN | Standard HD mechanics (verified) |
| 64 gates (center, theme, HD name) | IN | natalengine `GATES` (verbatim) |
| Gate → hexagram NUMBER (1–64) | IN (added) | Verified 1:1, see §5 |
| Gate → hexagram NAME | IN | natalengine `GATES[].iching` (verbatim) |
| Gate zodiac degree ranges (start/end, zodiac notation, wheel index) | IN (computed) | Computed from order+offset, verified §5 |
| 36 channels (gate pair, name, centers, theme) | IN | natalengine `CHANNELS` (verbatim) |
| 5 types (strategy, signature, not-self, aura, %, determination rule) | IN | natalengine `TYPES` + determination logic |
| Type determination algorithm (motor-to-throat BFS + sacral) | IN (documented) | natalengine `calculateHumanDesign`/`checkMotorToThroat` |
| 7 authorities + strict precedence order | IN | natalengine `AUTHORITIES` + `determineAuthority` |
| 12 profiles (line combos, name, theme, angle) | IN | natalengine `PROFILES` + incarnation-crosses angle map |
| 6 line-name archetypes + degree math | IN | natalengine `LINE_NAMES`, verified |
| 5 definition types (component-count) | IN | app override `calculateDefinition` (union-find) |
| 13 planetary activations + Design 88° rule | IN (documented) | natalengine `calculateHumanDesign` |
| 192 incarnation crosses (gate × angle) | IN | natalengine `INCARNATION_CROSSES` (verbatim) + angle map |
| Gate wheel order + offset + degrees-per-gate | IN | natalengine `GATE_ORDER`, `GATE_WHEEL_OFFSET`, verified |
| 384 gate-line interpretations | **OUT** | Proprietary/interpretive → RAG |
| Long gate/channel/center/type/cross descriptions | **OUT** | Proprietary → RAG |
| Gene Keys Shadow/Gift/Siddhi spectrum | OUT of this file | Lives in natalengine `GENE_KEY_SPECTRUM`; Gene Keys (Richard Rudd) is a separate system — encode separately if desired |

---

## 4. Extracted from natalengine (verbatim) vs added/verified

**Extracted verbatim from `natalengine/src/calculators/humandesign.js`:**
`CENTERS` (9), `GATES` (64: center + iching name + theme), `CHANNELS` (36), `TYPES` (5), `AUTHORITIES` (7), `PROFILES` (12), `LINE_NAMES` (6), `GATE_ORDER` (64), `GATE_WHEEL_OFFSET` (358.25), and the type/authority/profile derivation logic.

**Extracted verbatim from `natalengine/src/data/incarnation-crosses.js`:**
`INCARNATION_CROSSES` (64 gates × [Right, Juxtaposition, Left]) and the profile→angle mapping.

**Extracted from the app override `pages/api/human-design.api.js`:**
the corrected `calculateDefinition` union-find → Single / Split / Triple Split / Quadruple Split / No Definition. (The bundled natalengine library uses a cruder channel-*count* heuristic for definition; the spine encodes the **app's component-count mechanic**, which is correct, and documents the discrepancy.)

**Added / computed / documented (not literally present as a table in the source):**
- **Gate degree ranges** — computed deterministically from `GATE_ORDER` + `GATE_WHEEL_OFFSET` with 5.625°/gate, including zodiac notation and Aries-point wrap flag for Gate 25.
- **Hexagram numbers** — added the canonical 1–64 number to each gate (1:1 with gate number).
- **Center categories** and **connected-gate lists** — categories per standard HD; gate lists derived from `GATES[].center`.
- **Determination rules** spelled out as explicit ordered algorithms for type, authority, and definition.
- **Planetary-activation table** (13 bodies × 2 sides) and the Earth/South-Node opposition rules and the 88°-of-solar-arc Design rule.

---

## 5. Verification (fresh research, ≥2 sources, dated)

A dedicated web-research pass cross-checked the load-bearing mappings. **Today's date: 2026-06-23.** The HD reference pages are living/undated reference tables (the King Wen sequence and Rave Mandala wheel have been fixed since antiquity / the 1980s respectively), so no source carries a 2026 publish date and none is needed — these are static reference mappings, not fast-moving facts. **All sources accessed 2026-06-23.**

### 5.1 Gate ↔ I Ching hexagram number — CONFIRMED 1:1
HD Gate N = I Ching Hexagram N for all 64. No numbering discrepancies. The natalengine name list matches the canonical Wilhelm-Baynes primary titles with only **cosmetic** variants:
- Gate 43: natalengine "Break-through" vs W-B "Break-Through (Resoluteness)" — same word, W-B adds a subtitle.
- Gate 50: natalengine "The Cauldron" vs archaic W-B "The Caldron" — "Cauldron" is the universal HD spelling.
- Many hexagrams have W-B parenthetical subtitles (e.g. 24 "Return (The Turning Point)", 25 "Innocence (The Unexpected)") that natalengine drops; no conflict.

We kept the natalengine spellings (standard HD-community usage) in `hexagram_name` and added the integer `hexagram_number`.

Sources: jovianarchive.com (Gates and Hexagrams; official HD), castiching.com hexagram list (Wilhelm-Baynes titles), en.wikipedia.org List of hexagrams of the I Ching (number/sequence cross-check — note Wikipedia uses non-W-B shorthand names, not used as the naming reference), thalira.com (explicit 1:1 statement).

### 5.2 Gate zodiac degree wheel — CONFIRMED
- **Gate 25 begins at 28°15' Pisces = 358.25° absolute** — confirmed by two independent HD degree tables.
- **Wheel order** (the 64-gate sequence starting at Gate 25) — matched exactly by both tables; no gate out of position.
- **5.625° per gate** (5°37'30"); 64 × 5.625 = 360° — confirmed.
- **6 lines per gate; 0.9375°/line** — 6 lines confirmed by official Jovian Archive; the literal "0.9375°" string was not found printed in a source but is arithmetically forced (5.625 ÷ 6) and internally consistent, so treated as confirmed-by-math.
- **Line names** — 1 Investigator, 2 Hermit, 3 Martyr, 4 Opportunist, 5 Heretic, 6 Role Model — confirmed verbatim by the official Jovian Archive "6 Lines of the Hexagram" page.

**Technical caveat (carried into the data):** Gate 25's span wraps the 0°/360° (Aries) point (358.25° → 3.875°). Every other gate is contiguous; only Gate 25 straddles the Aries point. The spine flags this with `wraps_aries_point: true` on Gate 25, and the engine's bucketing (`(L - offset) mod 360`) already handles the wrap correctly.

Sources: barneyandflow.com/gate-zodiac-degrees (HD degree table), bonniesorsby.com/human-design-gates-by-degree (independent HD degree table), jovianarchive.com (lines, official HD).

### 5.3 Types, authority, definition — sourced from the engine
Type determination (motor-to-throat BFS + defined-Sacral), authority precedence (Emotional > Sacral > Splenic > Ego > Self > Lunar/None > Mental), and the definition component-count are taken directly from the live engine code (the canonical Ra Uru Hu / Jovian-lineage mechanics) and documented as explicit algorithms. The aura descriptors (Manifestor closed/repelling, Generator open/enveloping, Projector focused/absorbing, Reflector resistant/sampling) are standard HD and were added; they are short neutral descriptors.

---

## 6. Internal-consistency validation (automated, on the produced JSON)

Run against `human_design_data.json`. **Result: 0 errors — ALL CHECKS PASSED.**
- 64 gates present (1–64), each with a center that is one of the 9, and `hexagram_number == gate`.
- 36 channels; **every channel's two declared centers equal the centers of its two gates** (set-equality check).
- All channel gates exist in the gates table.
- **Degree ranges tile the full 360°** with no gaps or overlaps: every gate spans exactly 5.625°, consecutive starts differ by exactly 5.625°, total coverage = 360.0000°.
- The union of all centers' `gates` lists = exactly {1..64}, no dupes, no omissions.
- 64 incarnation-cross entries (one per Personality-Sun gate), each with right/juxtaposition/left names.

---

## 7. JSON section counts

| Section | Count |
| --- | --- |
| centers | 9 |
| gates | 64 |
| channels | 36 |
| types | 5 |
| authorities | 7 |
| profiles | 12 |
| lines | 6 |
| definition_types | 5 |
| planetary_activations (bodies/side) | 13 |
| incarnation_crosses (Personality-Sun gates × 3 angles) | 64 × 3 = 192 named crosses |
| gate_wheel order entries | 64 |

---

## 8. Open questions / known limitations

1. **Definition mechanic divergence.** The bundled natalengine uses a channel-*count* heuristic for definition; the app overrides it with a center-*component* union-find. The spine encodes the **component-count** mechanic (correct) and documents the divergence. If natalengine is ever upgraded, re-verify this still matches.
2. **0.9375°/line not printed verbatim** in any source — it is forced by 5.625 ÷ 6 and is not in doubt, but no source literally prints the string.
3. **Wilhelm-Baynes subtitles not stored.** We kept natalengine's primary-title spellings (HD-community standard). If you later want the W-B subtitles (e.g. "(Resoluteness)") for display, they would be an additive field.
4. **Sign-bucket groupings in `gate_wheel.order_by_sign` are approximate** — some gates straddle a sign boundary. The authoritative position is each gate's `degree_range`. This is flagged inline in the data.
5. **Gene Keys** (`GENE_KEY_SPECTRUM` in natalengine) is a separate system (Richard Rudd) and is intentionally **not** in this HD spine. Encode it as its own system file if the app surfaces Gene Keys.
6. **Profile angle nuance.** The incarnation-cross angle map keys profiles to Right/Left/Juxtaposition per natalengine's `getAngleFromProfile`. Some HD schools assign angles slightly differently at the edges; we implemented the Jovian-standard the app uses.

---

## 9. Completeness self-assessment

**~98% complete** against the brief's mechanical checklist.

Fully covered: 9 centers (+categories +connected gates), 64 gates (+hexagram number/name +center +theme +degree range +line count), 36 channels, 5 types (+aura +determination rules +algorithm), 7 authorities (+precedence order +rule), 12 profiles (+line derivation +angle), 6 lines (+degree math), 5 definition types (+algorithm), 13 planetary activations (+Design 88° rule +Earth/South-Node opposition), 192 incarnation crosses, gate wheel (order +offset +degrees-per-gate +per-line). Internal consistency machine-validated to 0 errors; full 360° tiling confirmed.

Remaining ~2% is deliberately out of scope (the 384 gate-line interpretive texts and long proprietary descriptions → RAG/commissioned), plus the additive-only items in §8 (W-B subtitles, Gene Keys as a separate system). No mechanical gap is known.
