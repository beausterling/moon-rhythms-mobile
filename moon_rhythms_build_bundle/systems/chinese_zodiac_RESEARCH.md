# Chinese Zodiac / BaZi Deterministic Spine — Research & Coverage Report

**Artifact:** `systems/chinese_zodiac_data.json`
**Generated:** 2026-06-23
**Companion to:** `moon_rhythms_build_bundle/deterministic_data.json` (Western astrology spine — structure and voice mirrored)
**Author note:** This is structured-lookup reference data only. Interpretive prose belongs in the RAG corpus, not here.

---

## 1. What this file is

A single deterministic source of truth for the Chinese zodiac / BaZi (Four Pillars) system. The app's actual date->pillar conversion is done at runtime by the `lunar-javascript` library (`pages/api/chinese-zodiac.api.js`); this JSON supplies every reference table the app and the AI assembler read from. It preserves every exact mapping the app already ships and expands them into a comprehensive, cross-verified spine.

---

## 2. Sources (all accessed 2026-06-23)

The underlying data is classical Chinese metaphysics (centuries-stable), so recency is not the risk — correctness is. Every load-bearing claim was cross-checked against >= 2 independent sources.

| # | Source | URL | Used for |
|---|--------|-----|----------|
| 1 | Wikipedia — Sexagenary cycle (EN) | https://en.wikipedia.org/wiki/Sexagenary_cycle | 60-cycle table, (year-3) mod 60 formula, Lunar-New-Year vs Li Chun boundary |
| 2 | Wikipedia — 干支 (ZH) | https://zh.wikipedia.org/wiki/干支 | Full 60-position ganzhi ordering |
| 3 | Wikipedia — 納音 (ZH) | https://zh.wikipedia.org/wiki/納音 | NaYin concept (NOTE: EN "Nayin" article 404s — no standalone EN page exists) |
| 4 | Wikipedia — Earthly Branches (EN) | https://en.wikipedia.org/wiki/Earthly_Branches | Branch animals, fixed elements, yin/yang, shichen time periods |
| 5 | 农历网 — 六十甲子纳音表 (traditional 30-line verse) | https://m.nongli.com/item5/bz/23913.html | Independent confirmation of NaYin order; source of glyph variants |
| 6 | The China Journey — Nayin Five Elements | https://www.thechinajourney.com/nayin-five-elements/ | 30 NaYin names + pairs + element (independent confirm) |
| 7 | The China Journey — Wuxing | https://www.thechinajourney.com/wuxing/ | Sheng/Ke/Cheng/Wu cycles |
| 8 | Learn Religions — Sheng & Ke cycles | https://www.learnreligions.com/five-element-generating-sheng-and-control-ke-cycles-3183168 | Wu Xing generating/controlling cycles |
| 9 | Me & Qi — Wu Xing (Five Elements) | https://www.meandqi.com/knowledge-base/concepts/wu-xing-five-elements | Wu Xing cycles cross-check |
| 10 | Imperial Harvest — Hidden Heavenly Stems (藏干) | https://imperialharvest.com/blog/hidden-heavenly-stems/ | Cangan / hidden stems table (verbatim) |
| 11 | Imperial Harvest — The 12 Earthly Branches | https://imperialharvest.com/blog/12-earthly-branches/ | Branch attributes |
| 12 | Imperial Harvest — Intro to the Chinese Calendar (Part 2) | https://imperialharvest.com/blog/introduction-to-the-chinese-calendar-part-2/ | Solar-term month boundaries (jie) |
| 13 | Bazi Fortune — Hidden Stems (Cang Gan) Guide | https://bazifortune.app/blog/bazi-hidden-stems-cang-gan-guide | Hidden stems cross-check |
| 14 | shaogn — Quick Reference Table of Hidden Stems | https://shaogn.com/en/comprehensive-quick-reference-table-of-hidden-stems-in-earthly-branches/ | Hidden stems cross-check |
| 15 | FateMaster — Dizhi (12 Earthly Branches) | https://www.fatemaster.ai/en/guides/dizhi | Branches, hidden stems |
| 16 | FateMaster — Xing-Chong-Hui-He rules | https://www.fatemaster.ai/en/guides/xing-chong-hui-he | San He, Liu He, Liu Chong, Xing, San Hui |
| 17 | YourChineseAstrology — Six Harming Groups | https://www.yourchineseastrology.com/zodiac/compatibility/6harming-groups/ | Liu Hai, Xing |
| 18 | Baidu Baike (EN) — Zodiac Punishment | https://baike.baidu.com/en/item/Zodiac%20Punishment/1412695 | Xing punishment groups |
| 19 | TreyBaZi — 3 Meetings & 3 Combinations | http://treybazi.blogspot.com/2013/02/earthly-branches-3-meetings-3.html | San Hui, San He |
| 20 | TravelChinaGuide — Four Pillars of Destiny | https://www.travelchinaguide.com/intro/astrology/four-pillar.htm | Four Pillars framing, solar-term months |
| 21 | Master Sean Chan — BaZi Jiazi #1 甲子 | https://www.masterseanchan.com/bazi-jiazi-yang-wood-rat/ | Confirms 甲子 = 海中金 = Metal (stem element != NaYin element) |

---

## 3. Coverage map: deterministic vs interpretive

**In this file (deterministic, structured lookup):**
- 5 elements + their display colors + 4 directed interaction cycles (sheng / ke / xie / wu)
- 10 Heavenly Stems (element + polarity + neutral imagery descriptor)
- 12 Earthly Branches (animal, fixed element, polarity, hidden stems, shichen, lunar month, month-start solar term)
- 12 animals (traits, lucky numbers/colors, loose compatible/incompatible, emoji, branch, fixed element)
- Full 60-cycle (Jiazi) — 60 entries, each with stem/branch/animal/stem-element/polarity/NaYin(chinese+english+element)
- 30 NaYin index table (positions + ganzhi pairs)
- Year-boundary rules + Gregorian->cycle formulas
- Compatibility: San He, Liu He, Liu Chong, Liu Hai, Xing, San Hui
- Four Pillars structure + inner/secret/true animal + day-master mapping
- 12 shichen two-hour periods

**NOT in this file (belongs in RAG / interpretive corpus):**
- Long-form personality writeups per animal/year-pillar/NaYin
- Year-by-year fortune / horoscope prose
- Relationship narrative interpretations
- BaZi chart-reading methodology essays (useful gods, luck pillars / da yun, ten gods / shi shen narratives)

---

## 4. Extracted-from-app vs added-from-research

**Extracted VERBATIM from `pages/api/chinese-zodiac.api.js` (preserved exactly):**
- `ANIMALS` — 12 char->English mappings and their order
- `STEMS` — 10 stems with pinyin/element/polarity
- `BRANCHES` — 12 branches with pinyin/animal
- `NAYIN` — the 30 English NaYin translations the app already chose (reused across the full 60-cycle; no new English names invented)
- `ELEMENT_COLORS` — 5 hex colors (carried into `five_elements`)
- `ANIMAL_TRAITS` — traits / lucky numbers / colors / compatible / incompatible per animal (the compatible/incompatible kept as `compatible_loose`/`incompatible_loose`)
- `ANIMAL_EMOJIS` — preserved in an `emoji` field per animal (no emoji in any prose)

**Added from fresh research:**
- Full 60-cycle (app only used lunar-javascript's runtime lookup; never shipped the table)
- The other 30 NaYin slots (app shipped 30 names; the 60-cycle reuses each across 2 positions — so all 60 are covered without new names)
- Hidden stems (cangan) for all 12 branches
- Branch fixed elements, polarities, shichen, lunar months, month-start solar terms
- Wu Xing directed interaction cycles (sheng/ke/xie/wu)
- Stem imagery descriptors
- All compatibility group structures (San He / Liu He / Liu Chong / Liu Hai / Xing / San Hui)
- Year-boundary rules and conversion formulas
- Four Pillars / inner-secret-true animal / day-master structure

---

## 5. Key decisions & source disagreements (also in `metadata.design_decisions`)

1. **Year-boundary rule (CRITICAL).** Two boundaries that disagree by up to ~5 weeks:
   - Popular zodiac ANIMAL year rolls over at **Chinese Lunar New Year** (variable, late Jan to mid Feb).
   - Formal BaZi YEAR PILLAR changes at **Li Chun (立春, ~Feb 4)** solar term, not at Lunar New Year.
   - **Which the app uses:** `getYearShengXiao()`/`getYearGan()`/`getYearNaYin()` use the LUNAR NEW YEAR boundary for the displayed animal/stem/NaYin, while `getEightChar()` (the four pillars) uses solar terms (Li Chun) for the year pillar. So the app's top-line animal can disagree with `fourPillars.year` for births in the Lunar-New-Year-to-Li-Chun window. Documented as intentional, not a bug. To go fully BaZi-correct, drive the top-line animal from `getEightChar()` instead.

2. **NaYin English names.** Taken verbatim from the app's existing `NAYIN` map. The full 60-cycle reuses these same 30 names (each NaYin spans 2 consecutive positions), so no new English names were invented — the app's choices propagate consistently.

3. **Fixed element vs year element vs NaYin element.** Three distinct element concepts kept as separate fields: animal/branch FIXED element (intrinsic, never changes), YEAR STEM element (what the app's `fullSign` like "Wood Tiger" uses), and NaYin element (independent third element, e.g. 甲子 stem=Wood but NaYin=Metal).

4. **Hidden stems — Wu (午).** Canonical table gives 午 two hidden stems (丁 primary + 己 middle); some simplified tables drop 己. The canonical 己 is included.

5. **Liu He 午未 transformation.** Standard reading = Earth (used); a minority of schools say Fire or no transformation (noted inline).

6. **Solar-term convention.** Branch month boundaries use the BaZi jie (节, odd-numbered node terms that BEGIN each month), not the zhongqi (中气) mid-month terms that Wikipedia's Sexagenary-cycle table lists. Solar-term dates drift +/-1 day per year and must be computed astronomically; the ~dates are approximate labels.

7. **NaYin glyph variants.** Five names have accepted variants (城头土~城墙土, 沙中金~砂中金, 金箔金~锡箔金, 桑柘木~桑拓木, 大溪水~大谿水). The app's canonical forms are used.

8. **Cycle formula index convention.** `(year-4) mod 60` for a 0-indexed array (1984 -> index 0 -> 甲子) or `(year-3) mod 60` with 0->60 for human 1-60 numbering. Both equivalent; both documented.

---

## 6. Validation

`python3 -c "import json; json.load(open('chinese_zodiac_data.json'))"` passes (valid UTF-8 JSON, 77 KB). Programmatic invariant checks all pass:
- 60-cycle: exactly 60 entries; position 1 = 甲子 "Gold in the Sea"; position 60 = 癸亥 "Water of the Great Sea"
- Anchor: `(1984-4) mod 60` = 甲子; `2024` = Dragon; `2026` = 丙午 Fire Horse
- Each of the 30 NaYin appears exactly twice across the 60
- Branch fixed elements correct (子=Water, 寅=Wood, 午=Fire, 申=Metal)
- 午 hidden stems = [丁, 己] in order
- Compatibility: San He 4 groups, Liu Chong 6 pairs, Xing 4 groups

---

## 7. Completeness self-assessment

**~95% complete** for a deterministic BaZi reference spine.

**Fully covered:** stems, branches, animals, 60-cycle, NaYin (full 60 via 30 names), hidden stems, Wu Xing cycles, fixed/year/NaYin element distinction, all six compatibility structures + San Hui, four pillars + inner/secret/true + day master, shichen, year-boundary rules, conversion formulas.

**Deliberately out of scope (interpretive — belongs in RAG, not here):**
- Ten Gods / Shi Shen (十神) — the relational labels between Day Master and other stems. This is structured BaZi data but derivation-dependent (relative to the Day Master) rather than a static lookup; could be added later as a derived-relationship table if the AI assembler needs it.
- Luck pillars / Da Yun (大运) — the 10-year luck cycles. Algorithm-driven (forward/backward by gender + solar-term distance), not a static table.
- Twelve Life Stages / Chang Sheng (长生) — the growth-cycle of each stem through the branches. Standard 12x10 table; omitted for MVP but a candidate addition.
- Per-animal/per-pillar interpretive prose, year-fortune content.

**Minor gaps / future additions (if needed):**
- Self-element (比劫) and other relational shortcuts for the AI assembler
- Exact solar-term astronomical dates per year (intentionally not hardcoded; compute from solar longitude)
- Lucky directions/flowers per animal — the app shipped numbers + colors only; directions/flowers vary widely by source and were not added to avoid low-confidence data. Can be added if a single authoritative source is chosen.

No known correctness errors. All disagreements are documented rather than silently resolved.
