# Human Design — Licensing & IP Legal Picture for Moon Rhythms

**Companion to:** `human_design_data.json`, `human_design_RESEARCH.md` (the mechanical spine), `human_design_schema.sql`, `human_design_seed.sql`
**Prepared:** 2026-06-23
**Question answered:** "Can we legally use Human Design in our commercial app? Is it copyrighted/trademarked? Do we need to buy a license, and if so from whom and how much?"

---

## ⚠️ NOT LEGAL ADVICE

**This document is research and analysis, not legal advice.** It cites primary legal authority (US statute, Supreme Court cases, Copyright Office circulars) and primary commercial sources (vendor terms, USPTO records), but it is written by an engineering agent, not a licensed attorney. **A licensed US IP attorney must review and sign off before commercial launch.** The "Open questions for counsel" section (§9) lists the specific items a lawyer should confirm.

**Freshness disclosure (per Moon Rhythms fast-moving-facts rule):**
- **Today's date:** 2026-06-23. Every web source below was accessed 2026-06-23.
- **Freshest primary source pulled:** USPTO TSDR live status pages (real-time from the official trademark register, pulled 2026-06-23/24). The most recent docketed trademark event is the cancellation of the "HUMAN DESIGN" registration on 2025-02-21. Jovian Archive's own site footer now reads "© 2026."
- The controlling legal authorities (17 USC §102(b) from 1976; *Baker v. Selden* 1879; *Feist* 1991; *TrafFix* 2001) are old but are the current, still-controlling law — they do not get "newer."
- **Confidence is flagged inline.** Where research could only establish "we did not find X" (not "X does not exist"), that is stated explicitly.

---

## 0. Bottom line (TL;DR)

| Question | Answer | Confidence |
| --- | --- | --- |
| **Do we need to buy a license to compute & display the mechanical chart?** | **No.** A method of calculation and factual mappings are not copyrightable (17 USC §102(b); *Baker*; *Feist*). | High (on the law); see §9 caveats |
| **Is there an official license/API we *could* buy?** | There is **no official redistributable HD developer license or content license.** Jovian Archive sells finished consumer reports, not a license. Third parties sell *mechanical-only* calc APIs (BodyGraph ~$59/mo, humandesignapi.nl €18–40/mo). We don't need any of them — our own engine already computes the chart. | High |
| **Is "Human Design" a registered US trademark we must avoid?** | **No live US trademark** exists for "Human Design," "Human Design System," "BodyGraph," "Rave Mandala," or "Maia Mechanics." Jovian's US mark is **abandoned/dead**. We can use "Human Design" descriptively/nominatively. | High on the dead/abandoned marks; Medium-high on the "no registration found" marks (see §3) |
| **Can we draw our own bodygraph?** | **Yes.** The layout is functional/system-dictated (thin-to-no copyright). Just don't copy Jovian's actual artwork file, and avoid naming it "Rave BodyGraph"/"Rave Mandala." | High |
| **Interpretive text (what a gate "means")?** | **Original prose IS copyrightable.** Write our own / commission original copy. Never paste Jovian's or any book's wording verbatim. | High |
| **Does the Swiss Ephemeris CHF 750 license apply to us?** | **No** — our HD engine uses `astronomy-engine` (MIT), not Swiss Ephemeris. See §8. | High (verified in the repo) |

**One-line verdict:** We do **not** need to buy any license to ship the Human Design feature as currently built (mechanical chart from our MIT-licensed engine + our own bodygraph drawing + our own/commissioned interpretive copy). The residual risks are about *naming* and *not copying anyone's prose/artwork*, both of which we control. Get a lawyer to confirm the trademark-clearance and "draw-your-own-art" items before launch.

---

## 1. Can we compute & display the mechanical chart without a license?

**Verdict: Yes, with high confidence on the legal principle.**

The mechanical chart = type, authority, profile, gates, channels, centers, definition, incarnation cross, and the degree wheel. Every one of these is either **the output of a system/method** or a **factual mapping**, and US copyright law does not protect those.

**Controlling authority:**

- **17 U.S.C. § 102(b)** — "In no case does copyright protection for an original work of authorship extend to any idea, procedure, process, system, method of operation, concept, principle, or discovery, regardless of the form in which it is described, explained, illustrated, or embodied in such work."
  - https://www.law.cornell.edu/uscode/text/17/102 (accessed 2026-06-23)
  - https://www.govinfo.gov/content/pkg/USCODE-2022-title17/html/USCODE-2022-title17-chap1-sec102.htm (accessed 2026-06-23)

- **Baker v. Selden, 101 U.S. 99 (1879)** — Copyright in a *book* describing a system (there, bookkeeping) does **not** grant exclusive rights in the **system itself** or in the **forms/diagrams necessary to use it**. A method is protectable, if at all, only by patent. The HD chart is the output of the HD method.
  - https://www.law.cornell.edu/supremecourt/text/101/99 (accessed 2026-06-23)
  - https://www.courtlistener.com/opinion/90097/baker-v-selden/ (accessed 2026-06-23)

- **Feist Publications v. Rural Telephone, 499 U.S. 340 (1991)** — **"No one may claim originality as to facts."** Copyright requires "independent creation plus a modicum of creativity"; the Court **rejected the "sweat of the brow" doctrine.** A factual compilation gets only a *thin* copyright in original *selection/arrangement*, never in the underlying facts.
  - https://www.law.cornell.edu/supremecourt/text/499/340 (accessed 2026-06-23)

- **Merger doctrine** (*Morrissey v. P&G*, 379 F.2d 675 (1st Cir. 1967)) — Where an idea/fact can be expressed in only one or a few ways, the expression "merges" with the idea and is unprotectable. "HD Gate N = I Ching Hexagram N" is a 1:1 fact with no expressive room.
  - U.S. Copyright Office Circular 33, "Works Not Protected by Copyright" (rev. 2021-03-26): https://www.copyright.gov/circs/circ33.pdf (accessed 2026-06-23)

**Applied to our specific data:**

| Our data element | Legal characterization | Copyrightable? |
| --- | --- | --- |
| Gate N → Hexagram N | Fact / 1:1 mapping (merger) | **No** |
| Gate → zodiac degree range (the wheel) | Deterministic output of the system | **No** |
| Channel = gate-pair → center wiring | System / method of operation | **No** |
| Type / authority / profile / definition derivation | Method of calculation (algorithm) | **No** |
| 192 named incarnation crosses | Factual labels produced by the system | **No** (names are short; see naming caveat §6) |
| Long interpretive description of a gate's "meaning" | Original literary expression | **YES** — must be our own |

**Critical safe-harbor we already satisfy:** we **independently compute** the chart from an open-source engine (the astronomical math + the HD system rules); we do **not** scrape a particular publisher's table or copy their prose. *Feist*'s rejection of "sweat of the brow" means Jovian's effort in compiling HD data creates **no rights** in the facts we independently regenerate. Our `human_design_RESEARCH.md` already documents this discipline (mechanical/factual data IN, interpretive prose OUT).

**Risk profile:** Low for the mechanical chart. The one real-world hedge is that Jovian Archive *asserts* sweeping IP ownership and is litigious in tone (§4), so "low legal risk" ≠ "zero chance of a nastygram." But the law, and an actual court ruling (§4), are on our side.

---

## 2. Is "Human Design" trademarked — do we need permission to use the name?

**Verdict: No live US trademark blocks us. We can use "Human Design" descriptively/nominatively. High confidence.**

### What we VERIFIED directly from the USPTO register (TSDR, primary source, accessed 2026-06-23)

| Mark | Serial / Reg # | Owner | Status |
| --- | --- | --- | --- |
| **HUMAN DESIGN** | SN 86134850 / Reg 4579387 | Human Design, LLC (Boulder, CO) — *not Jovian* | **DEAD — cancelled 2025-02-21** (no §8 declaration). "DESIGN" was disclaimed. |
| **THE HUMAN DESIGN SYSTEM** | SN 98217560 | Jovian Archive Media Pte. Ltd. (Singapore) | **DEAD — abandoned 2024-09-09** (failed to answer an Office action) |
| **THE HUMAN DESIGN SYSTEM** | SN 78500640 | Jovian Archive Corporation | **DEAD — abandoned 2006-08-15** |
| **RAVE** (stylized) | SN 79269522 / Reg 6150015 | A **French skateboard-clothing** company | LIVE but **irrelevant** (Class 025 clothing, no HD connection) |

Sources:
- https://tsdr.uspto.gov/statusview/sn86134850
- https://tsdr.uspto.gov/statusview/sn98217560
- https://tsdr.uspto.gov/statusview/sn78500640
- https://tsdr.uspto.gov/statusview/sn79269522
- https://trademarks.justia.com/861/34/human-86134850.html
- (all accessed 2026-06-23)

**Key takeaways:**
1. **No one currently holds a live US trademark on "Human Design" in the software/astrology/personality lane** (or any lane). Jovian's only US filing is abandoned.
2. The USPTO repeatedly **disclaimed "HUMAN," "DESIGN," and "SYSTEM"** as descriptive/generic across these files — i.e., the office treats the component words as too generic to own standing alone. This *supports* descriptive/nominative use.
3. **Trademark ≠ copyright.** Even with dead trademarks, Jovian can still assert (a) **copyright** in its books/specific artwork/course text and (b) **common-law ™ rights** in marks it actively uses (e.g., "Rave BodyGraph," "Rave Mandala") through use, even without registration. So: name-collision risk is low; copying-their-content risk is a separate matter (§1, §5).

### Marks we could NOT find any US registration for (absence of evidence — Medium-high confidence)
Searched USPTO TSDR + the Justia/Trademarkia mirrors (which index the full federal register) + uspto.report:
- **BODYGRAPH** / Rave BodyGraph — no US record found under any owner
- **RAVE MANDALA** — no US record found
- **MAIA MECHANICS** — no US record found
- **JOVIAN ARCHIVE** (word mark) — no US record found (only the abandoned SN 98217560)
- **BG5** — no US record found

Caveat: USPTO's own live search UI and WIPO's database are bot-gated, so these five were checked via TSDR-by-serial + comprehensive third-party mirrors rather than a per-mark live USPTO session. The mirrors returning zero Jovian hits, combined with Jovian's own pages marking "Rave BodyGraph**™**" and "Rave Mandala**™**" (the ™ symbol = *claimed/common-law*, not the ® *registered* symbol), is consistent and strong but is index-coverage evidence, not a per-serial live confirmation. **This is the #1 item for counsel to close** (§9).

### Safer naming guidance
- Using **"Human Design"** descriptively ("Discover your Human Design type," "Your Human Design chart") is **nominative/descriptive use** and low-risk — there's no live mark, and the words are disclaimed-as-descriptive.
- **Avoid** branding a feature or product **"BodyGraph," "Rave BodyGraph," or "Rave Mandala"** — those are Jovian's actively-used (™-claimed) marks. Use generic labels: **"body chart," "energy chart," "design chart," "Human Design chart."**
- **Do not imply affiliation or endorsement** by Jovian Archive / IHDS / Ra Uru Hu. Nominative reference is fine; "official" / "certified" / "powered by Jovian" is not (we aren't).

---

## 3. Interpretive content — the legal path

**Verdict: Write our own original descriptions, or commission them. Never copy a vendor's or book's wording verbatim. High confidence.**

- **What's protected:** The long, original **prose** describing what a gate/channel/center/type/profile/cross "means" is copyrightable literary expression — even though the underlying *idea* (the gate's meaning) is not. This includes Ra Uru Hu's transcripts/books, Jovian's myBodyGraph report text, and any HD author's descriptions.
- **What's NOT protected:** The *idea/meaning itself*, the system, the mechanical facts. We can convey the same concepts in our own words.
- **The thin-compilation trap:** Even free facts, if we copied a specific author's **exact selection + ordering + wording** of descriptors, could implicate their thin compilation copyright and/or literary copyright. Our defense is independent authorship.
- **Market reality (verified):** **No vendor licenses raw interpretive HD text for redistribution.** Jovian (myBodyGraph) sells finished reports ($49–$1,199), not a text license. BodyGraph Business plan lets you *generate/sell reports inside their platform* but doesn't hand you the raw text. So "license official interpretive text" is **not an available option** even if we wanted it — the only path is **original/commissioned copy** (which is also the cheapest and lowest-risk).
  - https://www.mybodygraph.com/pricing (accessed 2026-06-23)
  - https://bodygraph.com/pricing/ (accessed 2026-06-23)

**Our current posture already does this right:** `human_design_RESEARCH.md` §2 documents that we deliberately exclude the 384 gate-line interpretive texts and all long proprietary descriptions, treating interpretation as RAG/commissioned content. Keep that line bright. **Action item:** ensure any short `theme`/`keyword`/`descriptor` strings in the seed data are our own neutral wording, not lifted phrases (the RESEARCH doc says they are; worth a spot-audit).

---

## 4. Does Jovian Archive enforce its IP? (context for risk appetite)

**What Jovian claims (verified, primary — their own Terms):**
> "Jovian Archive Media Pte. Ltd. has the exclusive worldwide rights to the Human Design System… and all intellectual property, including… copyrights, moral rights, trademarks, trade secrets…" and forbids any commercial use, derivative works, or reproduction "without the explicit prior written permission."
> "The Rave BodyGraph™ and Rave Mandala™ are registered trademarks of Jovian Archive Media Pte. Ltd." (note: printed with **™**, not **®**, despite saying "registered" — internally inconsistent).
- https://www.jovianarchive.com/Terms_and_Conditions (accessed 2026-06-23)
- https://www.mybodygraph.com/terms-conditions (accessed 2026-06-23)

**The court ruling that helps us (verified, multi-source secondary):**
- **Court of Florence, Italy, order dated 2020-06-03.** A Jovian licensee (Human Design Italia) sued a publisher over an HD book. **The court ruled there is no copyright over the Human Design system itself**, reasoning copyright cannot protect an "idea, procedure, process, system, method of operation, concept, principle or discovery." Quoted: *"Neither [Jovian Archive] nor its successors can prevent others from publishing additional [works] on the 'Human Design System.'"*
  - https://en.wikipedia.org/wiki/Human_Design (accessed 2026-06-23)
  - https://www.oshonews.com/2020/07/19/human-design-italian-court-case/ (pub. 2020-07-19; accessed 2026-06-23)
  - *Caveat: Italian first-instance order, not US-binding, and it addressed copyright over the system — not specific copyrighted text/artwork or trademarks. But it applies the same idea/expression principle US law uses.*

**Enforcement against apps:** We found **no documented, verifiable record** of Jovian sending cease-and-desist letters to specific third-party software apps. (Reddit/community forums were not crawlable, so community hearsay is unconfirmed.) Many competitors operate openly with their own engines and bodygraphs (bodygraph.com, geneticmatrix.com, humandesignchart.org, an MIT-licensed `hdkit`, etc.), which is strong de-facto evidence the market doesn't treat Jovian's claims as a hard bar. **This is "we did not find enforcement," not "enforcement never happens."**

---

## 5. The BodyGraph image / Rave Mandala — can we draw our own?

**Verdict: Yes. Draw our own SVG with our own styling. Low copyright risk. High confidence.**

- The bodygraph's **layout is functional/system-dictated**: which center connects to which, the 64 numbered gates, the channel wiring — these are the *system*, not artistic choices. Functional/blank-form diagrams have thin-to-no copyright (*Baker v. Selden*; Copyright Office Circular 33; Compendium 3rd ed. Ch. 300 on functional layouts + merger).
  - https://www.copyright.gov/circs/circ33.pdf
  - https://www.copyright.gov/comp3/chap300/ch300-copyrightable-authorship.pdf
- **What IS protectable** is only Jovian's *specific artistic ornamentation* in *their* file: their exact palette, gradients, iconography, proportions, typography. **So: generate geometry from the system rules ourselves; never trace, recolor, or vectorize Jovian's actual artwork file.**
- **Trade dress is a weak claim** (*TrafFix Devices v. Marketing Displays*, 532 U.S. 23 (2001)): functional features get no trade-dress protection, and since dozens of vendors render their own bodygraphs, consumers don't associate "a bodygraph" with one source.
  - https://supreme.justia.com/cases/federal/us/532/23/
- The **Rave Mandala** (zodiac wheel + I Ching outer ring) is structurally a **standard 360° astrological wheel** with gate positions fixed by ecliptic degree — same low-risk analysis. The I Ching and the zodiac are public domain.
- **Precedent in the wild (verified):** `jdempcy/hdkit` is an **MIT-licensed** open-source bodygraph SVG generator (172 stars, public since 2016) — explicit permission to render bodygraphs commercially. Plus many independent free generators with visibly different styling.
  - https://github.com/jdempcy/hdkit (accessed 2026-06-23)

**Naming caveat (repeat of §2):** Draw it freely; just don't *call* it a "BodyGraph" / "Rave BodyGraph" / "Rave Mandala" in product/marketing. Use "body chart" / "energy chart" / "Human Design chart."

> **Note re: current mobile plan.** The mobile `CLAUDE.md` says "Human Design via WebView for v1." Confirm the WebView loads **our own** chart renderer (served from moonrhythms.io), **not** an embedded third-party generator (e.g., an iframe of bodygraph.com or Jovian's widget). Embedding a third party's chart pulls in *their* terms and could re-introduce risk we otherwise avoid. Self-host the render.

---

## 6. Is there an official license/API to buy, and what does it cost?

**Verdict: There is no official redistributable HD license. We don't need any API — our engine already computes the chart. For reference, here's the market:**

### Jovian Archive (the rights-holder) — NO developer license/API
- **No public API, SDK, or redistributable calculation-engine license.** Their consumer products forbid reuse/redistribution.
- Their only embed path is a **"Pro Web Widget"** — a rented iframe powered by their remote Maia Mechanics server, requiring an **active paid subscription + API key** and **gated to IHDS-certified professionals** (must have completed "Living Your Design Guide Training"). It does **not** give you the engine; it's a branded calculator you rent monthly. Not usable for our app and not needed.
  - https://www.maiamechanics.com/ ; https://wordpress.org/plugins/maia-mechanics-pro-web-widget/ (accessed 2026-06-23)
- **Maia Mechanics Imaging (MMI)** desktop software: one-time purchase, Basic $89 → Business/BG5 $1,199. This is end-user software, not a license to build on.
  - https://jovianarchive.com/Software/Maia_Mechanics_Imaging (accessed 2026-06-23)
- **myBodyGraph** consumer reports/subscriptions: $49 one-time → $1,199/yr. Finished products, no license, no API.
  - https://www.mybodygraph.com/pricing (accessed 2026-06-23)

### Third-party calculation APIs (mechanical data only — we don't need these)
| Provider | Price | Returns | Note |
| --- | --- | --- | --- |
| **BodyGraph Chart** (bodygraph.com) | API gated to **Business plan ~$59/mo annual / $69/mo** | Mechanical chart data only (no visual, no interpretation) | Lower plans have no API |
| **humandesignapi.nl** | €18.75–39.58/mo, or **€1,200 lifetime** | "Only the data is returned" (mechanical only) | Clearest pricing |
| **humandesignhub.app** | Free tier 100 credits/mo; paid undisclosed $ | Mechanical only | Pricing not public |

- https://bodygraph.com/feature/api-access/ ; https://bodygraph.com/pricing/ (accessed 2026-06-23)
- https://humandesignapi.nl/ (accessed 2026-06-23)
- https://humandesignhub.app/docs (accessed 2026-06-23)

**Why we don't need any of them:** all these APIs return *only* the mechanical chart — exactly what our own MIT-licensed `natalengine` already computes for free. None sells interpretive text. There is no upgrade in legal safety from buying one (their data is the same uncopyrightable mechanical facts); we'd just be paying for compute we already have.

---

## 7. Recommended path for Moon Rhythms (lowest legal risk, shippable)

1. **Keep computing the mechanical chart with our own MIT-licensed engine.** No license needed. (Our `natalengine` → `astronomy-engine` path is MIT — verified, §8.)
2. **Draw our own bodygraph/mandala SVG**, self-hosted on moonrhythms.io. Own palette, proportions, typography. Never trace/recolor/vectorize Jovian's artwork. Confirm the v1 WebView renders *our* chart, not a third-party embed (§5 note).
3. **Write or commission 100% original interpretive copy.** Never paste vendor/book wording. Keep the bright line our RESEARCH doc already draws. Spot-audit short descriptor strings for any lifted phrasing.
4. **Name carefully.** Use "Human Design" descriptively (low risk — no live mark). Use generic chart labels ("body chart"/"energy chart"), **not** "BodyGraph"/"Rave BodyGraph"/"Rave Mandala." No "official/certified/powered-by-Jovian" implications.
5. **Add a short disclaimer** in-app/marketing: that Moon Rhythms is independent and not affiliated with or endorsed by Jovian Archive, the IHDS, or Ra Uru Hu. (Reduces any false-association/trademark angle.)
6. **Before launch, run the lawyer checklist in §9.**

This path requires **buying nothing** and ships with the feature as currently scoped.

---

## 8. Sidebar — the ephemeris license question (resolved: not an issue for HD)

Research surfaced a real trap for astrology apps: the **Swiss Ephemeris** is dual-licensed **AGPL-3.0 OR a paid Astrodienst commercial license (~CHF 750+)**. If our HD engine used Swiss Ephemeris and we shipped closed-source, we'd likely owe that fee or trip the AGPL copyleft.
- https://www.astro.com/swisseph/swephprice_e.htm (accessed 2026-06-23)

**It does NOT apply to our Human Design path. Verified in the repo (2026-06-23):**
- `natalengine` (the HD engine) is **MIT**, and its only runtime dependency is **`astronomy-engine`** (Don Cross), which is **MIT**. No Swiss Ephemeris is involved in the HD calculation.
- No `swisseph`/`sweph` package is installed anywhere in the web repo's `node_modules`.

**Separate, non-HD flag for the backend (note for the web team, not a HD issue):** the web repo also depends on `ephemeris` (npm), which is **GPL-3.0**, and `circular-natal-horoscope-js` (Unlicense/public-domain). The GPL-3.0 `ephemeris` package (used for general natal astrology, not HD) is its own copyleft consideration for the server bundle and is worth a separate look by whoever owns the web backend licensing — but it is **outside the scope of this HD memo** and does not affect the "do we need a HD license" answer.

---

## 9. Open questions for counsel (close before launch)

1. **Trademark clearance (the #1 gap).** Run a full live USPTO/TSDR + WIPO + Singapore IPOS / EUIPO search for "BodyGraph," "Rave BodyGraph," "Rave Mandala," "Maia Mechanics," "Jovian Archive," "BG5." We established the US "Human Design" family marks are dead and found no US registration for the others, but the others were checked via mirrors, not per-mark live USPTO sessions. Confirm registered-vs-merely-™ status, owner, live/dead, and goods/services class for each, and confirm our chosen UI labels don't collide.
2. **Which Jovian entity holds rights** — their properties inconsistently name "Jovian Archive Media Pte. Ltd." vs "Jovian Archive Media Inc." vs "Jovian Archive Corporation." Relevant if a dispute ever arises.
3. **US-registered copyrights** — confirm whether Jovian holds any US copyright *registrations* for specific chart artwork or interpretive text (distinct from the uncopyrightable system). Affects damages exposure if we ever inadvertently copied protected expression.
4. **Our-own-artwork sign-off** — have counsel eyeball our final bodygraph/mandala SVG side-by-side against Jovian's to confirm no substantial similarity in protected ornamentation.
5. **Interpretive-copy provenance** — confirm our gate/channel descriptions and any short descriptor strings are independently authored, with an audit trail.
6. **Third-party embed check** — confirm the v1 WebView serves our own renderer, so no third party's Terms of Service attach to our product.
7. **Backend ephemeris licensing** (separate workstream) — the web repo's GPL-3.0 `ephemeris` dependency for general astrology. Not a HD-license question, but flag it for whoever owns the web licensing review.

---

## 10. Source index (all accessed 2026-06-23)

**Copyright law (primary):**
- 17 USC §102(b): https://www.law.cornell.edu/uscode/text/17/102 ; https://www.govinfo.gov/content/pkg/USCODE-2022-title17/html/USCODE-2022-title17-chap1-sec102.htm
- Baker v. Selden, 101 U.S. 99 (1879): https://www.law.cornell.edu/supremecourt/text/101/99 ; https://www.courtlistener.com/opinion/90097/baker-v-selden/
- Feist v. Rural Telephone, 499 U.S. 340 (1991): https://www.law.cornell.edu/supremecourt/text/499/340
- TrafFix Devices v. Marketing Displays, 532 U.S. 23 (2001): https://supreme.justia.com/cases/federal/us/532/23/
- US Copyright Office Circular 33 (rev. 2021-03-26): https://www.copyright.gov/circs/circ33.pdf
- US Copyright Office Compendium 3rd ed., Ch. 300: https://www.copyright.gov/comp3/chap300/ch300-copyrightable-authorship.pdf

**Trademark (primary — USPTO TSDR):**
- https://tsdr.uspto.gov/statusview/sn86134850 (HUMAN DESIGN — cancelled 2025-02-21)
- https://tsdr.uspto.gov/statusview/sn98217560 (THE HUMAN DESIGN SYSTEM, Jovian — abandoned 2024)
- https://tsdr.uspto.gov/statusview/sn78500640 (THE HUMAN DESIGN SYSTEM, Jovian Corp — abandoned 2006)
- https://tsdr.uspto.gov/statusview/sn79269522 (RAVE — French clothing, unrelated)
- Mirror cross-checks: https://trademarks.justia.com/861/34/human-86134850.html ; https://uspto.report/TM/98217560

**Jovian Archive / vendor terms (primary):**
- https://www.jovianarchive.com/Terms_and_Conditions
- https://www.mybodygraph.com/terms-conditions
- https://www.jovianarchive.com/Human_Design/The_Chart_and_BodyGraph
- https://jovianarchive.com/Software/Maia_Mechanics_Imaging
- https://www.maiamechanics.com/ ; https://wordpress.org/plugins/maia-mechanics-pro-web-widget/
- https://www.mybodygraph.com/pricing

**Commercial APIs / pricing (primary):**
- https://bodygraph.com/feature/api-access/ ; https://bodygraph.com/pricing/ ; https://bodygraph.com/feature/human-design-api/
- https://humandesignapi.nl/
- https://humandesignhub.app/docs
- https://www.geneticmatrix.com/software/ ; https://www.geneticmatrix.com/plans-features/

**Open-source engines / bodygraph renderers:**
- https://github.com/jdempcy/hdkit (MIT, bodygraph SVG)
- https://github.com/CReizner/SharpAstrology.HumanDesign (MIT)
- https://github.com/geodetheseeker/human-design-py
- https://humandesignchart.org/ ; https://bodygraph.io/ ; https://www.puregenerators.com/chart-calculator

**Enforcement context (secondary):**
- https://en.wikipedia.org/wiki/Human_Design
- https://www.oshonews.com/2020/07/19/human-design-italian-court-case/ (Court of Florence, 2020-06-03)

**Ephemeris licensing (primary):**
- https://www.astro.com/swisseph/swephprice_e.htm ; https://www.astro.com/swisseph/swisseph.htm

**Our own repo (verified 2026-06-23):** `natalengine` = MIT → `astronomy-engine` = MIT (HD path); no Swiss Ephemeris installed. Web repo also has `ephemeris` = GPL-3.0 (non-HD astrology) and `circular-natal-horoscope-js` = Unlicense.
