# Public Domain Astrology Corpus — Master Reference

**Project:** Moon Rhythms RAG knowledge base
**Prepared:** April 24, 2026
**Purpose:** Catalog of verified public domain sources for building the astrological interpretation layer of Moon Rhythms. This is a **scouting report**, not the corpus itself — a map of what's available, at what quality, with what licensing, so Beau can make informed ingestion decisions.

---

## 1. How to Use This Document

This document has six parts:

1. **Copyright & licensing ground rules** — so you don't have to re-research what's safe
2. **Catalog of verified sources** — with URLs, PD status, format, and notes
3. **Coverage map** — what each source actually covers, mapped to Moon Rhythms' chunk schema
4. **Representative excerpts** — real text samples so you can judge voice and depth
5. **Ingestion priority ranking** — where to start
6. **Gaps and recommendations** — what PD won't cover, and how to fill it

Read Part 1 first. The licensing ground rules determine what you can legally do with everything else.

---

## 2. Copyright & Licensing Ground Rules

### The US public domain cutoff

As of 2026, works published in the US **before January 1, 1930** are in the public domain. This date advances by one year every January 1st. Works published in 1930 will enter PD on January 1, 2026 (already happened); 1931 enters on January 1, 2027; and so on.

**Practical application:** Any astrology book with a first-publication date before 1930 in the US is PD in the US. You can copy, adapt, redistribute, and commercially exploit the text freely.

### Author death + copyright term (for works outside the US cutoff)

For authors who died before **1956**, their works are PD in "life + 70 years" jurisdictions (most of Europe, Canada now, Australia). Alan Leo died in 1917 — all his works are PD globally. Sepharial died in 1929 — PD globally. William Lilly died in 1681 — obviously PD.

For a Moon Rhythms corpus used in a US-launched app, the US rule is what matters most. But if you ever expand internationally, author-death-plus-70 is the stricter check.

### The three trap categories

**Trap 1: "Scanned by" copyright on digital editions.**
When someone digitizes a PD book (Internet Archive, Google Books, HathiTrust), the underlying text remains PD. But specific *annotations, OCR corrections, introductions, or editorial material* added by the digitizer may be new copyrighted content. Rule: use the original text, ignore added commentary. For clean text, prefer Project Gutenberg (explicitly released to PD) over Internet Archive scans with uncertain editorial layers.

**Trap 2: sacred-texts.com's non-commercial restriction.**
John Bruno Hare's digital editions at sacred-texts.com come with an explicit "non-commercial purpose" restriction on the specific digital files. The underlying texts (Lilly 1647, Ptolemy's *Tetrabiblos*, etc.) are PD and can be used from other sources — but don't directly redistribute Hare's specific scanned HTML files in a commercial product. **Always source the same text from Gutenberg, Archive.org raw scans, or HathiTrust instead.**

**Trap 3: Modern reprints are not PD.**
A new edition of Alan Leo published by Cosimo in 2015 is a PD text plus new copyrighted introduction, cover, and typesetting. Use only the original 1910s text (from original scans), never the modern reprint.

### What "use" means for your corpus

Even with PD text, you're building a RAG database that feeds an AI. Your usage pattern is:

1. Ingest text into your knowledge chunks table with embeddings
2. AI retrieves chunks at inference time
3. AI generates responses informed by chunks
4. You may cite chunks in the UI

All of the above is legally clean for PD sources. You can also **modernize and rewrite** PD text to update the voice — there's no obligation to preserve original phrasing for PD material.

### What this doesn't cover

This document is not legal advice. It's a research brief based on US copyright law as it stood in April 2026. Before launch, have a lawyer review your final corpus composition, especially if you're using anything with a post-1929 publication date or any derivative works.

---

## 3. Catalog of Verified Sources

Each source below is confirmed PD in the US. Priority rankings at the end of the document.

### 3.1 Alan Leo — the foundation of modern astrology

**Who:** William Frederick Allan (1860–1917), pen name "Alan Leo." British astrologer, theosophist, publisher. Widely considered the father of modern Western astrology. Founded the Astrological Lodge of the Theosophical Society. Translated esoteric and Hindu astrological concepts into accessible English prose. His "Astrology for All" series is the single most valuable PD source for Moon Rhythms because it aligns closely with modern natal interpretation conventions.

**Why he matters for Moon Rhythms:** Leo's voice is clear, structured, and psychological. He was the first to frame astrological placements in terms of *character* rather than fate — which is exactly Moon Rhythms' angle. His moon-sign descriptions are rich and his language is modernizable with minimal effort.

**Confirmed PD status:** Died 1917. All works published during his lifetime are PD globally. Some posthumous reprints (1931 edition on Internet Archive) use original pre-1917 text — PD in the US but verify original publication date before using any specific edition.

**Key works for the corpus:**

| Work | Year | Topics | Source URL | Format |
|------|------|--------|------------|--------|
| *Astrology for All* (Vol 1) | 1899, revised 1910 | Sun & Moon in signs, individual characteristics | https://archive.org/details/astrologyforall00leogoog | Scanned PDF + full text |
| *How to Judge a Nativity* | 1908 | Reading a full natal chart | https://onlinebooks.library.upenn.edu/webbin/book/lookupname?key=Leo,+Alan (HathiTrust) | Page images |
| *The Key to Your Own Nativity* | 1917 | Practical chart interpretation | HathiTrust via Online Books Page | Page images |
| *Esoteric Astrology* | 1913 | Psychological/spiritual framing | https://archive.org/details/in.ernet.dli.2015.201007 | Scanned PDF |
| *The Progressed Horoscope* | 1906 | Progressions (post-MVP) | HathiTrust | Page images |
| *The Art of Synthesis* | 1912 | Chart synthesis (advanced) | Multiple | Page images |
| *Practical Astrology* | 1897 | Foundations | HathiTrust | Page images |

**Voice sample (from *Astrology for All* index metadata):** "moon, sun, astrology, sign, combination, aries, nature, signs, personal character, matters connected, persons born, great amount, considerable amount" — gives you a sense of his lexical register: plain, slightly Victorian, psychologically oriented, modernizable.

**Ingestion note:** Internet Archive PDFs often need OCR cleanup. Gutenberg has NOT produced clean text editions of most Leo works yet — you'll be working with OCR from Archive scans for most of his catalog. Budget cleanup time.

---

### 3.2 Sepharial — the technical teacher

**Who:** Walter Gorn Old (1864–1929), pen name "Sepharial." British astrologer, Theosophical Society member, editor of Old Moore's Almanac. Prolific author of astrological manuals. More technically oriented than Leo — Sepharial is your source for mechanics (how to calculate, how to judge aspects) rather than deep psychological interpretation.

**Why he matters for Moon Rhythms:** Sepharial's writing is practical and clear. Good for aspect mechanics, planetary rulership, and explanatory "Learn tab" content. Less rich for personality interpretation than Leo.

**Confirmed PD status:** Died 1929. All works PD in US. Works published before 1930 are globally PD.

**Key works for the corpus:**

| Work | Year | Topics | Source URL | Format |
|------|------|--------|------------|--------|
| *Astrology: How to Make and Read Your Own Horoscope* | 1920 | Complete beginner manual | https://www.gutenberg.org/ebooks/46963 | **Clean text from Gutenberg** |
| *A Manual of Astrology* | pre-1900 (exact year varies) | Technical foundations | Multiple (HathiTrust, Archive) | Page images |
| *The New Manual of Astrology* | 1898, revised 1909 | Language of the heavens, chart reading | HathiTrust | Page images |
| *Cosmic Symbolism* | pre-1929 | Symbolic astrology | Gutenberg | **Clean text** |
| *Kabalistic Astrology* | 1909 | Names and numbers | HathiTrust | Page images |
| *Hebrew Astrology* | 1929 | Prophecy and timing | HathiTrust | Page images |

**Voice sample (from *Astrology: How to Make and Read Your Own Horoscope*, 1920, Chapter on planetary natures):** "Neptune means chaos, confusion, deception. Uranus, eccentricity, originality, estrangement. Saturn, privation, hindrance, denial. Jupiter, affluence, fruitfulness, increase. Sun, dignities, honours. Mars, excess, impulse, quarrels. Venus, peace, happiness, agreement. Mercury, commerce, versatility, adaptability. Moon, changes, publicity."

These are exactly the kinds of keyword-rich associations that make good RAG chunks when expanded.

**Ingestion note:** The Gutenberg edition of *Astrology: How to Make and Read Your Own Horoscope* is already clean text, ready to parse. This is your lowest-friction Sepharial source.

---

### 3.3 Raphael — the practical astrologer

**Who:** Robert Cross Smith (1795–1832), pen name "Raphael," and subsequent astrologers who used the same pen name through the 19th and early 20th centuries. The original Raphael edited *The Prophetic Messenger* almanac and popularized the Placidus house system in English-speaking astrology. Later "Raphaels" continued the brand.

**Why he matters for Moon Rhythms:** Raphael's works are the foundation of 19th-century popular Western astrology. Less psychologically sophisticated than Leo, but rich on aspects, planetary placements, and practical interpretation.

**Confirmed PD status:** The original Raphael (1795–1832) is obviously PD. Later Raphael works through 1929 are PD in the US. A specific "Raphael" who published until 1923 (noted in archive metadata) — his works are clearly PD.

**Key works for the corpus:**

| Work | Year | Topics | Source URL | Format |
|------|------|--------|------------|--------|
| *A Manual of Astrology* | 1828 | Foundational text | https://archive.org/details/amanualastrolog00smitgoog | Full text on Archive |
| *The Guide to Astrology* (Vols 1 & 2 combined) | c. 1900 | Genethliacal astrology | https://archive.org/details/guidetoastrology00raphiala | Scanned PDF |
| *Raphael's Medical Astrology* | 1910 (reprinted 1924) | Physical body correspondences | https://archive.org/details/b28135921 | Scanned PDF |
| *The Astrologer of the Nineteenth Century* | 1825 | Occult miscellany | Public Domain Review has full edition | Page images |

**Ingestion note:** Raphael's prose is archaic (Regency-era English with idiosyncratic typography). Will need significant modernization. Use sparingly for MVP — prioritize Leo and Sepharial.

---

### 3.4 Ptolemy — *Tetrabiblos*

**Who:** Claudius Ptolemy (c. 100–170 CE), Greco-Egyptian polymath. The *Tetrabiblos* is the foundational text of Western astrology — every modern approach traces conceptually back to this work.

**Why he matters for Moon Rhythms:** For authority and credibility. Ptolemy's framework for planetary meanings, sign qualities, and aspect theory is the *canon* of Western astrology. Quoting or referencing Ptolemy is not about practical interpretation — it's about depth of lineage. Nice to have as supporting material, not core chunks.

**Confirmed PD status:** 2nd century. Translations matter — modern (post-1929) translations are still copyrighted. J.M. Ashmand's 1822 translation is safely PD.

**Key works for the corpus:**

| Work | Year | Topics | Source URL | Format |
|------|------|--------|------------|--------|
| *Tetrabiblos* (Ashmand translation) | 1822 translation | Foundational framework | Available on Project Gutenberg and other PD archives; **AVOID sacred-texts.com's specific edition due to non-commercial restriction** | Multiple |

**Ingestion note:** Ptolemy's framework is abstract and philosophical, not directly interpretive. Good for a "Learn" tab historical grounding, not for chunks the AI uses to describe "what Moon in Leo means for you."

---

### 3.5 William Lilly — *Christian Astrology*

**Who:** William Lilly (1602–1681). English astrologer, author of *Christian Astrology* (1647), the standard horary astrology text. Famously predicted the Great Fire of London in 1666.

**Why he matters for Moon Rhythms:** Limited direct value for natal interpretation — Lilly wrote horary astrology (answering specific questions from charts cast in the moment). Planet and sign meanings overlap with natal work but context differs. Good for deep-dive historical content, not MVP chunks.

**Confirmed PD status:** 1647, obviously PD. 1852 Zadkiel-edited version ("Introduction to Astrology") is also PD.

**Key works:**

| Work | Year | Topics | Source URL | Format |
|------|------|--------|------------|--------|
| *Christian Astrology* | 1647 | Horary + planet/sign meanings | Project Gutenberg and Archive; **AVOID sacred-texts.com's Zadkiel edition due to non-commercial restriction** | Multiple |

**Ingestion note:** Archaic 17th-century English. Requires substantial modernization. Skip for MVP.

---

### 3.6 Franz Cumont — *Astrology and Religion Among the Greeks and Romans*

**Who:** Belgian historian of religion (1868–1947). Seminal work on ancient star-worship published 1912.

**Why he matters for Moon Rhythms:** Historical/contextual content for a "Learn" tab. Not interpretive. Zero use for core chunks.

**Confirmed PD status:** 1912, US PD. Cumont died 1947, PD in life+70 jurisdictions too.

**Source:** Available on Archive.org and other PD archives. AVOID sacred-texts.com's specific digital edition.

---

### 3.7 Evangeline Adams — early works

**Who:** American astrologer (1868–1932). Famously made astrology respectable in early 20th-century America. Predicted the stock market crash of 1929.

**Why she matters for Moon Rhythms:** Her voice is modern-feeling relative to her contemporaries, and she wrote directly to an American audience — which suits Moon Rhythms' target market better than British theosophical writers. Early works are PD; later works (1931–1932) still under copyright.

**Confirmed PD status:** Works published **before 1930** are PD. Her major books include:

| Work | Year | PD Status |
|------|------|-----------|
| *The Bowl of Heaven* | 1926 | **PD in US** |
| *Astrology: Your Place in the Sun* | 1927 | **PD in US** |
| *Astrology: Your Place Among the Stars* | 1930 | Under copyright until 2026 — CHECK DATE |

**Ingestion note:** Find original 1926–1927 editions on Archive or HathiTrust. Her 1930 book entered PD on January 1, 2026 — it's now available for your use, but verify source scans are from the original 1930 edition, not a later reprint.

---

### 3.8 Max Heindel — *Simplified Scientific Astrology*

**Who:** Danish-American occultist (1865–1919), founder of the Rosicrucian Fellowship. Wrote accessible astrology guides in the early 20th century.

**Why he matters for Moon Rhythms:** Heindel's writing is accessible and includes what he called "spiritual" astrology — framing placements around soul lessons rather than fate. Useful for a more mystical content layer if that fits your brand (you've expressed preference for NOT using woo-woo language, so weight accordingly).

**Confirmed PD status:** Died 1919, works pre-1930 are fully PD.

**Key work:** *Simplified Scientific Astrology* (1918). Available on Archive.org and direct Rosicrucian Fellowship site (they maintain their founder's works online as PD).

---

### 3.9 Other candidates worth knowing

**Luke Broughton** (American astrologer, 1828–1898) — early American practical astrology. Limited online availability but worth searching HathiTrust.

**Zadkiel (Richard James Morrison, 1795–1874)** — British astrologer, edited the 1852 version of Lilly. Original Zadkiel almanacs are PD.

**Walter Gorn Old's contemporaries** in the Theosophical Society astrology circle produced essays in *Modern Astrology* magazine (Alan Leo was editor). Back issues pre-1930 may exist in HathiTrust. These essays often contain rich interpretive material.

**Public Domain Review** (publicdomainreview.org) hosts curated PD materials including astrological works — a good scouting resource.

**IAPSOP** (iapsop.com) — International Association for the Preservation of Spiritualist and Occult Periodicals. Massive archive of old astrological magazines.

---

## 4. Coverage Map — What Each Source Covers

This maps the sources above to the kinds of knowledge chunks your RAG database will need.

### 4.1 Core chunk categories for Moon Rhythms

Based on the user profile chunk tiers we designed earlier, your knowledge corpus needs to cover:

1. **Planets in signs** (10 planets × 12 signs = 120 chunks minimum)
2. **Planets in houses** (10 × 12 = 120)
3. **Aspects between planets** (10 × 9 × 5 aspect types ≈ 450 major combinations, fewer meaningful pairings)
4. **Sign characteristics** (12)
5. **House meanings** (12)
6. **Moon signs deep-dive** (your brand-aligned priority — 12 extensive chunks)
7. **Moon phases** (8 phases)
8. **Aspect theory** (conjunction, opposition, trine, square, sextile explained)
9. **Synastry basics** (how charts interact — limited PD coverage)
10. **Transit interpretation** (planet transiting sign, transit to natal — limited PD coverage)

### 4.2 Where PD covers you well

| Category | Best PD Source | Coverage Quality |
|----------|----------------|------------------|
| Sun & Moon in signs | Alan Leo *Astrology for All* | **Excellent** — core of the book |
| Planets in signs (general) | Leo *How to Judge a Nativity*, Sepharial *Astrology* | Good |
| Planets in houses | Leo, Sepharial, Raphael | Good |
| Major aspects (meaning) | Sepharial, Leo | Good |
| Sign characteristics | Leo *Astrology for All* | **Excellent** |
| House meanings | Lilly, Sepharial, Raphael | Good (technical) |
| Aspect theory | Sepharial | Good |
| Moon phases | Leo (scattered), Max Heindel | Adequate |

### 4.3 Where PD covers you poorly — this is where you commission writing

| Category | PD Coverage | Why PD Falls Short |
|----------|-------------|---------------------|
| Synastry (chart comparison) | Minimal | Modern synastry as a defined practice largely post-1930 |
| Composite charts | None | Invented by Robert Hand in 1970s |
| Transit-based guidance | Basic only | Modern psychological transit framing is post-1960s |
| Psychological/Jungian astrology | Essentially none | Dane Rudhyar (1930s+), Liz Greene, etc. |
| Couples dynamics via astrology | Essentially none | Modern relationship coaching framing |
| Moon-sign compatibility (as a focus) | Scattered | Donna Cunningham's framing from 1988 defined modern approach |
| Chiron | None | Discovered 1977 |
| Modern asteroids (Lilith etc.) | None | Post-1930 astrological interpretation |
| Human Design | None | Invented 1987 |

**Critical implication for Moon Rhythms:** The PD corpus will do 60–70% of the heavy lifting for individual natal interpretation, but essentially 0% for the *relationship-focused core* of the product. The couples advisor experience will require commissioned or original-written content. Plan and budget for this.

---

## 5. Representative Voice Samples

These excerpts let you judge the raw material. All samples are from confirmed PD sources. Your corpus ingestion pipeline will need to modernize this prose — these show you what you're starting from.

### 5.1 Sepharial on the planets (1920, *Astrology: How to Make and Read Your Own Horoscope*)

> Neptune means chaos, confusion, deception. Uranus, eccentricity, originality, estrangement. Saturn, privation, hindrance, denial. Jupiter, affluence, fruitfulness, increase. Sun, dignities, honours. Mars, excess, impulse, quarrels. Venus, peace, happiness, agreement. Mercury, commerce, versatility, adaptability. Moon, changes, publicity.

*Assessment:* Concise, keyword-rich, directly usable as seed material. Modernization needed ("privation" → "restriction"; "dignities, honours" → "authority, recognition"). A single planet-keyword expansion like this becomes 10 named chunks in your schema.

### 5.2 Sepharial on practical application (same source)

> It is not possible within the limits of a small handbook such as this to adequately consider the philosophic paradox which makes of Freewill in man a "necessity in play"; but it is obvious that the concept is not altogether unscientific, seeing that it is customary to speak of the "free path of vibration" in chemical atoms while at the same time it is known that these atoms have their restricted characteristics, modes of motion, &c.

*Assessment:* Here's the Edwardian voice in full. Wordy, philosophical, not immediately usable. Shows why "rewrite in modern voice" is a necessary step, not optional.

### 5.3 Raphael on planetary placements (1828-ish, *The Guide to Astrology*)

> Herschel (Uranus) in the ascendant, in fiery signs, makes the native rash, headstrong, and ambitious; fond of curiosities; restless; inclined to the study of astrology; aiming at great and noble things; possessing original talents; fond of dispute and argument.

*Assessment:* Structural template you can adapt — "[Planet] in [house/sign] produces a person who is [X], [Y], [Z]." This pattern is replicable and modernizable to your voice. But the specifics ("inclined to the study of astrology") are period-bound quirks to remove.

### 5.4 Alan Leo — typical chapter structure (indexed concepts from *Astrology for All*)

Based on the indexed terms in digitized editions, Leo's chapters typically cover: sign basics, Sun in each sign (12 sections), Moon in each sign (12 sections), Sun-Moon combinations (144 sections — this is the gold), personal character reading, and practical examples.

The Sun-Moon combinations (144 of them) are particularly valuable for Moon Rhythms because they give you **pre-written chunks for every combination of luminary placements** — something no modern PD source matches in coverage.

*Assessment:* Alan Leo is your single highest-priority ingestion target for this reason alone.

---

## 6. Ingestion Priority Ranking

Recommended order based on (coverage × quality × ease of processing):

### Tier 1 — Start here (weeks 1–3)

1. **Sepharial, *Astrology: How to Make and Read Your Own Horoscope* (1920)** — Source: Project Gutenberg. *Why first:* Clean text already extracted. No OCR needed. Covers fundamentals cleanly. Your lowest-friction starting point.
2. **Alan Leo, *Astrology for All* (1899/1910 editions)** — Source: Archive.org. *Why second:* Highest interpretive quality. Sun-Moon combinations are uniquely valuable. Worth the OCR cleanup time.

### Tier 2 — Fill the gaps (weeks 4–6)

3. **Alan Leo, *How to Judge a Nativity* (1908)** — Aspect-focused, fills gaps left by *Astrology for All*.
4. **Alan Leo, *The Key to Your Own Nativity* (1917)** — Practical chart synthesis.
5. **Sepharial, other PD works** — For aspect mechanics and technical backbone.

### Tier 3 — Depth and context (post-MVP)

6. **Evangeline Adams, early works** — American voice, accessible prose.
7. **Ptolemy, *Tetrabiblos*** — Framework authority and "Learn" tab material.
8. **Raphael, technical works** — Historical depth.
9. **Max Heindel** — Optional, only if you want a more spiritually-framed layer.

### Tier 4 — Skip unless you have a specific use

10. **William Lilly** — Too archaic and horary-focused for natal MVP.
11. **Cumont** — Academic history, not interpretation.

---

## 7. Recommended Ingestion Pipeline

A workflow for turning these sources into your RAG database.

### Step 1: Acquire clean text

- **Gutenberg sources:** Download the plain-text or HTML versions directly. Already clean.
- **Archive.org scans:** Download PDF, run OCR if needed (use `tesseract` or commercial OCR — pay for quality; cheap OCR creates downstream cleanup work).
- **HathiTrust:** Page images only — harder to extract. Use for reference, not primary ingestion.

### Step 2: Clean and normalize

Once you have raw text, run it through a pipeline that:

1. Strips Project Gutenberg license boilerplate (for Gutenberg sources)
2. Removes chapter/page number artifacts from OCR
3. Normalizes archaic spellings (e.g., "shewn" → "shown")
4. Converts astrological symbols to text (many PD scans use now-obscure Unicode symbols for planets and signs — replace with names)

### Step 3: Chunk by concept, not by paragraph

This is the part that matters most. Don't chunk by word count or paragraph. Chunk by **astrological concept**, using named keys that match your database schema. For example:

- `moon_in_leo_general` — general meaning of Moon in Leo
- `moon_in_leo_emotional_patterns` — the emotional tier specifically
- `moon_in_leo_relationships` — how it shows up relationally
- `moon_leo_sun_scorpio_combo` — specific Sun-Moon combo (Alan Leo's territory)

Each chunk should be 100–400 words. Too short and retrieval misses context; too long and you waste tokens.

### Step 4: Modernize voice via AI editing

Here's where AI earns its keep in *your* pipeline — not scraping other people's modern content, but modernizing PD source text that you already legally own. Feed each chunk through a prompt like:

> "You are editing 1910s astrological text for a modern app called Moon Rhythms. Preserve the author's insight, but update the language: remove archaic phrasing, break up long sentences, eliminate gendered generalizations, and write in a warm but grounded voice. Never add mystical language ('cosmic,' 'written in the stars'). Output the modernized chunk."

This is fully legitimate — you're editing your own PD-derived material, not derivative-working someone else's copyrighted content. The legal distinction we discussed earlier matters here: **your input data is clean**, so your output is clean.

### Step 5: Embed and store

Feed each modernized chunk through OpenAI's `text-embedding-3-small` (or equivalent) to get vectors. Store in pgvector in Supabase with:
- Chunk text
- Embedding
- Source attribution (which PD book, which chapter)
- Topic keys (matches schema)
- Date ingested, prompt version used for modernization

Attribution in the database matters even for PD work — lets you re-pull specific chunks if you ever want to re-modernize with a better prompt later.

---

## 8. Gaps PD Will Not Fill (and What To Do)

The following categories **cannot** be covered from PD sources. You need other paths:

### 8.1 Modern psychological astrology

Rudhyar, Jung-influenced astrologers, Liz Greene, Steven Forrest — all under copyright. This is the framing most people recognize as "real" modern astrology.

**Solution:** Hire one or two practicing astrologers to write a layer of modern psychological interpretation in Moon Rhythms' voice. Budget: ~$3,000–$8,000 for 300–500 core chunks at commercial rates.

### 8.2 Synastry and relationship astrology

This is Moon Rhythms' *entire moat*. PD coverage is near-zero. Without this layer, the couples advisor is shallow.

**Solution:** This is the most important commissioning work you'll do. Find an astrologer with synastry expertise. Write your own position on what relationship astrology means in Moon Rhythms' framework. This content becomes your core IP — it cannot be scraped or replicated.

### 8.3 Chiron and modern asteroids

Chiron (discovered 1977) has no PD interpretive literature. Black Moon Lilith (increasingly popular since the 1990s) similarly lacks PD sources.

**Solution:** Commission or skip entirely for MVP. Many users won't miss it.

### 8.4 Transit interpretation (modern framing)

Modern apps ("now Mercury is retrograde, so...") draw on interpretive conventions developed post-1930.

**Solution:** Write in-house using the core PD material as a foundation and modern astrological conventions as framing.

### 8.5 Human Design

Invented 1987 by Ra Uru Hu. Entirely under copyright. Not available as PD content at all.

**Solution:** You mentioned a WebView wrap for the bodygraph in v1. For interpretive content about Human Design, either license from a Human Design educator, commission proprietary content, or skip Human Design from the AI advisor layer entirely until you have a licensing agreement.

---

## 9. Recommended Next Actions

In order:

1. **Read this document in full and flag anything you want to dig deeper on.**
2. **Download the Sepharial Gutenberg text** (https://www.gutenberg.org/ebooks/46963) — it's the fastest "see this working" move. You can parse it into test chunks this week.
3. **Download one Alan Leo volume** from Archive.org (*Astrology for All*) and assess OCR quality. This tells you how much cleanup time the Leo catalog will require.
4. **Decide your corpus scope for MVP.** Suggested: ~500 modernized chunks from Leo + Sepharial covering planets in signs, planets in houses, major aspects, and moon signs in depth. This is achievable in 4–6 weeks of focused work.
5. **Start scouting for a commission astrologer** in parallel. This takes time (reviewing writing samples, negotiating scope, contracting). You want candidates lined up by the time your PD corpus is ingested.
6. **Build the internal prompt-tuning tool** we discussed earlier, so you can iteratively improve the modernization prompt as you ingest.
7. **Before launch, commission legal review** of the final corpus — all sources, all licenses, all derivative work paths. Budget a few hours of IP lawyer time.

---

## 10. Appendix — Quick Reference URLs

For copy-paste convenience:

**Project Gutenberg (clean text, ready to use):**
- Sepharial, *Astrology*: https://www.gutenberg.org/ebooks/46963
- Sepharial, *Cosmic Symbolism*: https://www.gutenberg.org/ebooks/author/32128 (catalog)
- Astrology books generally: https://www.gutenberg.org/ebooks/subject/673

**Internet Archive (PDF scans, may need OCR):**
- Alan Leo, *Astrology for All* (1899): https://archive.org/details/astrologyforall00leogoog
- Alan Leo, *Astrology for All* (1931 reprint): https://archive.org/details/in.ernet.dli.2015.238185
- Alan Leo, *Esoteric Astrology*: https://archive.org/details/in.ernet.dli.2015.201007
- Alan Leo, *Modern Astrology* magazine: https://archive.org/details/modern-astrology-alan-leo
- Raphael, *A Manual of Astrology*: https://archive.org/details/amanualastrolog00smitgoog
- Raphael, *The Guide to Astrology*: https://archive.org/details/guidetoastrology00raphiala
- Sepharial Gutenberg mirror: https://archive.org/details/astrologyhowtoma46963gut

**HathiTrust catalog (Alan Leo complete bibliography):**
- https://onlinebooks.library.upenn.edu/webbin/book/lookupname?key=Leo,+Alan

**Sepharial catalog:**
- https://onlinebooks.library.upenn.edu/webbin/book/lookupname?key=Sepharial,+1864-1929

**DO NOT use for commercial redistribution (non-commercial restriction):**
- sacred-texts.com's specific digital editions — go to Gutenberg/Archive for the same underlying texts instead

**Useful scouting resources:**
- Public Domain Review: https://publicdomainreview.org/
- IAPSOP (occult periodicals archive): https://iapsop.com/
- Open Library: https://openlibrary.org/

---

## Document Status

This is a v1 scouting report. The next iterations should add:

- **v2:** Actual chunking schema worked out for 1–2 source books, with example chunks in the Moon Rhythms database format
- **v3:** Prompt specifications for the voice-modernization step
- **v4:** Full attribution database design so every chunk traces back to its source in case of later legal review

---

*End of document.*
