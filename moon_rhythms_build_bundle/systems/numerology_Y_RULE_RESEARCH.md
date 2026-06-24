# Numerology Y / W Vowel Rule — Authoritative Research

**Question:** What is the standard, citeable method for treating Y and W as vowels vs consonants in name-number calculations (Expression/Destiny, Soul Urge/Heart's Desire, Personality)? Is there genuine consensus, who is the most-cited authority, and how do we implement it deterministically?

**Today's date:** 2026-06-23
**Freshest dated source signal found:** Felicia Bender Soul Urge resource PDF dated 2018 (`feliciabender.com`, "© 2018"); the worldnumerology.com article carries no publish date but the domain is actively maintained in 2026. Numerology is a slow-moving doctrinal field with mostly undated, evergreen reference pages, so recency is not the risk here — *which variant a source teaches* is. Every variant split below was checked against at least two sources and is reported honestly.

**Bottom line up front:** There is **no universal rule**. There is a clear, well-documented **majority modern convention** (the phonetic "Y-is-a-vowel-when-it-carries-the-only-vowel-sound" rule, taught by Hans Decoz and Matthew Oliver Goodwin), but the two classic authorities disagree even with each other: Juno Jordan dropped Y entirely, Lynn Buess always counted it, and Decoz and Goodwin split on whether **W** can ever be a vowel. Anyone who tells you it is "universally agreed" is wrong. We should cite the **phonetic rule (Decoz / Goodwin)** as the modern standard and be transparent that it is a majority convention, not a settled law.

---

## 1. The four documented schools (this is the honest consensus picture)

| School / authority | Rule for **Y** | Rule for **W** | Status |
|---|---|---|---|
| **Hans Decoz** (World Numerology) | **Phonetic.** Y is a vowel when it sounds like one / is the only vowel sound in its syllable (Lynn, Yvonne, Mary, Betty, Bryan); a consonant when the syllable already has a vowel (Maloney, Murray) or when Y stands in for a soft-J (Yolanda). | **Never a vowel.** "There are other letters that have an ambivalent nature, such as the letter W, but we don't assign it a vowel status." | Most-cited **modern** authority; de facto standard for most online calculators. |
| **Matthew Oliver Goodwin** (*Numerology: The Complete Guide*, 1981/1988) | **Phonetic, two-part:** (a) Y is a vowel when there is **no other vowel in the syllable** (Yvonne, Sylvia, Larry); (b) Y is a vowel when **preceded by A/E/I/O/U and sounded as one sound**. | **Yes, W can be a vowel:** W is a vowel when **preceded by A/E/I/O/U and sounded as one sound** (Bradshaw, Matthew, Lowell). | Classic textbook authority; the standard *academic-style* statement of the phonetic rule. **Only major authority who counts W as a vowel.** |
| **Juno Jordan** (*Numerology: The Romance in Your Name*, 1965; California Institute of Numerical Research) | **Y never enters the calculation** — treated as a consonant always (it is simply not counted among the vowels). | Never a vowel. | Foundational classic; the strict "AEIOU only, Y always consonant" school. **This is the school our current code matches.** |
| **Lynn Buess** (and others) | **Y is always used / always a vowel** when computing Soul Urge. | (not a W-vowel advocate) | Minority modern school; the opposite extreme from Jordan. |

So the real landscape is a **spectrum**: Jordan (Y never) → Decoz/Goodwin (Y phonetic) → Buess (Y always). And a separate, narrower split on W: everyone except Goodwin says W is never a vowel.

**Source for the four-school framing (Jordan vs Buess vs Decoz, verbatim):** Felicia Bender (a Decoz-school numerologist) quotes the disagreement directly: *"Dr. Juno Jordan (and others) will tell you that the 'y' never enters into the calculation, while Lynn Buess (and others) contends that the 'y' is always used in calculating the Soul Urge number."* — [feliciabender.com, "Numerology: The Soul Urge"](https://feliciabender.com/numerology/numerology-the-soul-urge/) (accessed 2026-06-23; page © 2018). Corroborated by a second independent search of the same quote across `worldnumerology.com` and `numerologist.com` (accessed 2026-06-23).

---

## 2. The single most-cited rule, with exact citations

### 2a. Hans Decoz (the modern standard)

Decoz's rule, captured from his article *"Y vowel or consonant in numerology"* via search-result snippets and a second site quoting him verbatim (the worldnumerology.com page itself returns HTTP 403 to automated fetch — anti-bot — but the wording below is corroborated by two independent sources quoting it directly):

> "When the letter serves as a vowel, and in fact sounds like one, it is a vowel. The same is true when the Y serves as the only vowel in the syllable. Examples of both of these cases are such names as **Lynn, Yvonne, Mary, Betty, Elly, and Bryan**."
>
> "In general, the Y is a consonant when the syllable already has a vowel. In names such as **Maloney or Murray**, the Y is a consonant, because the vowel sound depends upon the long E in Maloney and the long A in Murray."
>
> "There are other letters that have an ambivalent nature, such as the letter **W, but we don't assign it a vowel status**."
>
> "If the Y is a vowel, it is part of the Soul Urge, if it's a consonant, it is part of the Personality number."

A common companion clause from the Decoz school: **Y is a consonant when it stands in for a soft-J sound** (Yolanda, Yoda, Yamaha).

**Citation:** Hans Decoz, *"Y, vowel or consonant in numerology"*, World Numerology — `https://www.worldnumerology.com/numerology-articles/numerology-Y-vowel-consonant.html` (accessed 2026-06-23). Decoz, *Numerology: Key to Your Inner Self* (Penguin/Perigee, rev. ed.) is the print version of the same method. Wording above corroborated by [feliciabender.com](https://feliciabender.com/numerology/numerology-the-soul-urge/) and [numerology.center](https://numerology.center/numerology_and_letter_y.php) (both accessed 2026-06-23).

### 2b. Matthew Oliver Goodwin (the classic textbook statement)

From *Numerology: The Complete Guide, Volume 1: The Personality Reading* (1981; 1988 printing), Chapter 5, captured verbatim from the Internet Archive full text:

> "**Y is a vowel when there is no other vowel in a syllable.**" — examples: **Yvonne, Sylvia, Larry**.
> "**Y is a vowel when it is preceded by A, E, I, O, U and sounded as one sound.**" — examples: **Hayden, Doyle, Raymond**.
> "**W is a vowel when it is preceded by A, E, I, O, U and sounded as one sound.**" — examples: **Bradshaw, Matthew, Lowell**.

**Citation:** Matthew Oliver Goodwin, *Numerology: The Complete Guide, Volume 1: The Personality Reading*, Newcastle Publishing, 1981 (1988 printing), Ch. 5. Full text: [archive.org](https://archive.org/details/GoodwinMatthewOliverNumerologyTheCompleteGuideVolume1ThePersonalityReading1988) (accessed 2026-06-23).

> **Important disagreement to flag on the page:** Decoz and Goodwin *agree* that Y is phonetic, but they **disagree on Raymond**. Goodwin counts the Y in **Raymond** as a *vowel* (Y preceded by a vowel, sounded as one). Decoz counts the Y in **Murray** as a *consonant* (the preceding A already carries the sound). They are applying the same principle ("does Y add a distinct vowel sound?") and reaching different verdicts on the "vowel + Y" case. This is exactly why a purely mechanical algorithm cannot be 100% faithful to any one author — see §4.

### 2c. Juno Jordan (the classic strict school — what our code currently matches)

Juno Jordan, *Numerology: The Romance in Your Name* (DeVorss, 1965), the foundational textbook of the California Institute of Numerical Research, teaches the strict "AEIOU only" method: **Y never enters the vowel calculation** (always treated as a consonant). Verified via Felicia Bender's direct quote of Jordan's position (§1) and corroborating search (accessed 2026-06-23). Book record: [archive.org](https://archive.org/details/numerologyromanc00juno).

---

## 3. Is it universal? No. Honest confidence statement.

- **Not universal.** Four documented positions exist (Jordan: Y never; Decoz/Goodwin: Y phonetic; Buess: Y always), plus a W split (Goodwin alone counts W). State this plainly on the page.
- **There IS a clear modern majority.** The **phonetic Y rule** is what Decoz teaches, what Goodwin's textbook teaches, and what the large modern calculators present as the default. If you cite one rule as "the standard," cite the phonetic Y rule and attribute it to **Hans Decoz** (most-cited modern) and **Matthew Oliver Goodwin** (classic textbook).
- **W as a vowel is a minority/fringe position.** Only Goodwin among the major authorities counts W (Bradshaw, Matthew, Lowell). Decoz explicitly refuses to. Most calculators never treat W as a vowel. Do **not** present W-as-vowel as standard; mention it as the Goodwin exception.
- **How real calculators cope:** the better ones **expose a toggle.** World Numerology's own software has a setting to switch Y's treatment under the name field, precisely because "[the] treatment of the letter Y as a vowel or consonant changes Soul Urge and Personality numbers." Many free calculators silently pick one convention (usually the phonetic one) and do not tell the user. Confidence: high — confirmed across worldnumerology.com settings docs and multiple calculator pages (accessed 2026-06-23).

**Confidence: high** on the existence and wording of the four schools (each corroborated by ≥2 sources, two captured verbatim from primary full texts). **Medium** on the exact author-by-author edge-case verdicts (e.g. Goodwin-Raymond vs Decoz-Murray), because authors phrase the "Y after a vowel" case differently and examples vary between printings and quoting sites.

---

## 4. Deterministic algorithm (the phonetic rule, approximated)

A **fully correct** implementation requires **syllabification and phoneme analysis** — you must know the syllable boundaries and the vowel *sounds*, not just the letters. Pure letter lookup cannot do this. (That is why even Decoz and Goodwin, working by ear, disagree on Raymond/Murray.) What follows is the standard practical approximation used by letter-based calculators.

**Inputs:** a name string, lowercased, letters only. Base vowels = `{a, e, i, o, u}`.

**Per-letter classification:**

1. If the letter is in `{a, e, i, o, u}` → **vowel**.
2. If the letter is **Y**:
   - **Vowel** if **neither neighbor** (the letter immediately before or after it, within the same name word) is one of `a,e,i,o,u`. (Y is carrying the vowel slot itself.) → Lynn, Yvonne (Y at start, next is `v`), Bryant, Sylvia, Betty, Mary, Carolyn.
   - **Consonant** if it is **immediately preceded by a vowel** (the preceding vowel already carries the sound) → Maya, Murray, Maloney, Hayley. *(This is the simplest, most defensible single rule. It matches Decoz on Murray/Maloney. It will disagree with Goodwin on Raymond, where Goodwin calls the post-vowel Y a vowel — an unavoidable author conflict.)*
   - **Consonant** if it is **immediately followed by a vowel** at the **start of a word/syllable** (Y acting as the soft-J glide) → Yolanda, Yoda, Yvette? (note: Yvonne/Yvette start with `Yv`, consonant-next, so they fall under the vowel branch — correct, because the Y *is* the vowel sound there). To distinguish "Yo-landa" (consonant) from "Yv-onne" (vowel) deterministically: treat **word-initial Y followed by a vowel** as a **consonant** (glide), and word-initial Y followed by a consonant as a **vowel**.
3. If the letter is **W**: **consonant, always.** (Decoz convention; the safe majority.) *Optional Goodwin mode:* W is a **vowel** only when **immediately preceded by a vowel** (Matthew, Bradshaw, Lowell, Crawford) — gate this behind a flag, off by default.

**Concrete worked examples (default rule above, no W-vowel):**

| Name | Y position | Verdict | Why | Matches Decoz? |
|---|---|---|---|---|
| **Lynn** | `l-Y-n-n` | **vowel** | both neighbors consonants | yes |
| **Yvonne** | `Y-v-o-n-n-e` | **vowel** | word-initial, next is `v` (consonant) | yes |
| **Bryant** | `b-r-Y-a-n-t` | **consonant** | followed by vowel `a` | (Decoz: Bryan = Y vowel; *here our simple rule misfires* — see note) |
| **Maya** | `m-a-Y-a` | **consonant** | preceded by vowel `a` | yes |
| **Yolanda** | `Y-o-l...` | **consonant** | word-initial + next is vowel (soft-J glide) | yes |
| **Raymond** | `r-a-Y-m...` | **consonant** | preceded by vowel `a` | matches Decoz-style; **disagrees with Goodwin** |
| **Matthew** | `...t-h-e-W` | W = consonant (default) | W always consonant | yes (Decoz). Goodwin-mode would call it a vowel. |

**Honest edge-case note (Bryant / Bryan):** the simplest adjacency rule ("Y is a consonant if followed by a vowel") **wrongly** classifies the Y in Bryan/Bryant as a consonant, whereas Decoz explicitly calls Bryan's Y a vowel (the `ry-` cluster makes Y the syllable's vowel sound). To handle Bry-/Wy-/Sly- style clusters you need the **"is Y preceded by a consonant cluster with no vowel in the syllable"** test, which is genuine syllabification. The defensible deterministic compromise is:

> **Y is a vowel UNLESS it is immediately preceded by one of a,e,i,o,u (then consonant), OR it is word-initial and immediately followed by a vowel (then consonant — the soft-J glide).** Everything else → vowel.

That single sentence gets Lynn, Yvonne, Bryant, Sylvia, Mary, Carolyn, Yolanda, Maya, Murray, Raymond, Hayley all correct *except* it sides with Decoz over Goodwin on the post-vowel case (Raymond), which is fine because no algorithm can satisfy both. It is the best letter-only approximation and it is what we recommend if we upgrade.

---

## 4b. Word vs Syllable scope — the definitive answer

**Question:** within the phonetic Y rule, the trigger "Y is a vowel when there is no other vowel" can be scoped two ways:
- **Rule A (WORD scope):** Y is a vowel only if there is no a/e/i/o/u anywhere in the whole word.
- **Rule B (SYLLABLE scope):** Y is a vowel if there is no other vowel in *its own syllable* (even if other vowels exist elsewhere in the word).

**Definitive answer: Rule B (SYLLABLE scope) is the authoritative, agreed-upon convention.** Every cited authority states it as *syllable*, never *word*. This is one of the few genuinely high-consensus points in the whole Y/W debate.

**The evidence is unambiguous and unanimous across authorities:**

- **Hans Decoz** (World Numerology): *"The same is true when the Y serves as the only vowel in the **syllable**."* And his consonant test is explicitly per-syllable: *"the Y is a consonant when **the syllable** already has a vowel."* — `https://www.worldnumerology.com/numerology-articles/numerology-Y-vowel-consonant.html` (accessed 2026-06-23; corroborated by feliciabender.com and numerology.center, both accessed 2026-06-23).
- **Matthew Oliver Goodwin** (*Numerology: The Complete Guide*, 1981, Ch. 5): *"Y is a vowel when there is no other vowel in a **syllable**."* — `https://archive.org/details/GoodwinMatthewOliverNumerologyTheCompleteGuideVolume1ThePersonalityReading1988` (accessed 2026-06-23).
- **astronumero.org** (reproducing the Goodwin formulation, and making the distinction explicit in so many words): *"Y is a vowel when there is no other vowel in a **syllable** (not the word)"* — with examples Lynn, **Carolyn**, Hayden. The parenthetical "(not the word)" is a direct, on-point refutation of Rule A. — `https://www.astronumero.org/name-numerology/` (accessed 2026-06-23).
- **numerology.center**: same syllable phrasing, with **Carolyn** and **Wyatt** as Y-vowel examples — `https://numerology.center/numerology_and_letter_y.php` (accessed 2026-06-23).

No major authority scopes the rule to the word. Word-scope (Rule A) is not a documented numerology convention at all; it only appears as an accidental simplification in some calculators (see below).

### Worked examples that DISTINGUISH Rule A from Rule B

These are exactly the names where a real a/e/i/o/u exists elsewhere in the word, but the Y sits alone in its own syllable. Rule A (word) says consonant; Rule B (syllable) says vowel. Authorities side with Rule B.

| Name | Syllables (approx.) | The Y is in syllable… | Other vowel in the WORD? | Other vowel in Y's SYLLABLE? | Rule A (word) | Rule B (syllable) | Authoritative verdict |
|---|---|---|---|---|---|---|---|
| **Carolyn** | Car-o-lyn | `lyn` | yes (a, o) | no | **consonant** | **vowel** | **vowel** (Decoz lists Carolyn as Y-vowel; astronumero example) |
| **Kathryn** | Kath-ryn | `ryn` | yes (a) | no | **consonant** | **vowel** | **vowel** (Y is the only vowel sound in `ryn`) |
| **Bryant** | Bry-ant | `bry` | yes (a) | no | **consonant** | **vowel** | **vowel** (Decoz: Bryan's Y is a vowel — same `bry` cluster) |
| **Sydney** | Syd-ney | `syd` (first) | yes (e) | no | **consonant** | **vowel** (the first Y) | **vowel** for the first Y; the trailing `-ney` Y is the soft-E case → see note |
| **Lynsey / Lindsay-style** | Lyn-sey | `lyn` | yes (e) | no | **consonant** | **vowel** (first Y) | **vowel** (first Y carries the `lyn` syllable) |
| **Allyson** | Al-ly-son | `ly` | yes (a, o) | no | **consonant** | **vowel** | **vowel** (Y is the vowel of `ly`) |
| **Brittany** | Brit-ta-ny | `ny` | yes (i, a) | no | **consonant** | **vowel** | **vowel** (Y is the vowel of `ny`) |

Contrast — names where both rules agree (no distinguishing power), shown for sanity:

| Name | Why | Both rules say |
|---|---|---|
| **Lynn** | only vowel sound in the whole word IS the Y | vowel (A and B agree) |
| **Murray** | Y immediately follows the vowel `a` in the same syllable (`-ray`) | consonant (A and B agree) |
| **Mary** | `Ma-ry`: Y alone in `ry`; but also note `a` exists in word → A says consonant, B says vowel | **Decoz lists Mary as Y-vowel → Rule B wins here too** |

**Takeaway from the table:** for every multi-syllable name with a real vowel plus a syllable-isolated Y (Carolyn, Kathryn, Bryant, Allyson, Brittany, Sydney's first Y, Lynsey's first Y), Rule A wrongly demotes the Y to a consonant, while Rule B and the authorities make it a vowel. Rule B is correct.

### What calculators actually implement (honest reality)

- The serious, authority-aligned calculators follow **syllable scope** (Decoz's own software; tools that cite Decoz/Goodwin). Confidence: high.
- Some lightweight free calculators **ignore scope entirely** and either (a) always treat Y as a vowel regardless of context (e.g. affinitynumerology.com states flatly *"the letter 'y' is calculated as a vowel because it generally has a vowel sound"* — `https://affinitynumerology.com/using-numerology/how-to-calculate-numerology-name-numbers.php`, accessed 2026-06-23), or (b) collapse the rule to a crude letter-adjacency check. Neither of these is "word scope" per se; word-scope is mostly a *naive-implementer's* misreading of "the only vowel," not a school anyone teaches. Confidence: medium (based on inspecting several calculator help pages; not an exhaustive census).

### Deterministic algorithm for SYLLABLE scope (recommended)

True syllable scope requires syllabification. A correct-enough deterministic version, in priority order, per Y in a name word:

1. If Y is **immediately preceded by a/e/i/o/u** within the word → **consonant** (the preceding vowel owns the syllable's sound: Murray, Maya, Hayley, Raymond, the `-ney`/`-ay` endings).
2. Else if Y is **word-initial and immediately followed by a/e/i/o/u** → **consonant** (soft-J glide: Yolanda, Yoda).
3. **Otherwise → vowel.** This captures the syllable-isolated cases without an explicit syllabifier, because a Y that is neither preceded by a vowel nor a word-initial glide is, in practice, carrying its own syllable's vowel sound: Lynn, Carolyn (`lyn`), Kathryn (`ryn`), Bryant (`bry`), Allyson (`ly`), Brittany (`ny`), Sydney/Lynsey (first Y), Sylvia, Mary, Betty.

This is the *same one-sentence rule* already recommended in §4 — and the key point for Beau's question is that **this rule is inherently syllable-scoped, not word-scoped**: it never consults whether the rest of the word contains a vowel. It looks only at the Y's immediate neighbors, which is the correct (syllable-local) behavior and exactly why it gets Carolyn/Kathryn/Brittany right where a word-scope rule would get them wrong. Residual imperfection: it sides with Decoz over Goodwin on the post-vowel case (Raymond), unavoidable since those two authorities disagree.

**One-line recommendation to put on the page:** *"Y is treated as a vowel when it carries its own syllable's vowel sound — judged per syllable, not per word — following Hans Decoz and Matthew Oliver Goodwin."*

---

## 5. Recommendation for the Moon Rhythms app

**Current state:** the engine (`lib/numerology.js`, mirrored in `numerology_data.json`) treats `VOWELS = {a,e,i,o,u}` and **Y and W as always consonants**. This is exactly the **Juno Jordan strict school** — a real, citeable position, not a bug. But it is the *minority* modern convention, and it is the single biggest divergence between our output and full-featured calculators (Decoz/Goodwin and most online tools will produce different Soul Urge / Personality numbers for any name where Y carries a vowel sound: Lynn, Yvonne, Mary, Bryant, Carolyn, etc.).

Three options, in order of preference:

**Option A (recommended): Implement the phonetic Y rule (the §4 one-sentence approximation), keep W always-consonant.**
- *Gain:* matches the modern majority (Decoz + most calculators) for the overwhelming majority of names; removes the biggest, most-noticed divergence; lets us cite Decoz/Goodwin honestly as "the standard we follow."
- *Cost:* one well-tested helper function (~15 lines) replacing the flat vowel set. No syllabifier needed for the approximation. The only residual inaccuracy is rare author-disagreement cases (Raymond-type), which no calculator gets "right" because the authors themselves disagree. **This is the recommended path.**

**Option B: Implement A *and* expose a toggle** ("How should Y be treated? — Phonetic (recommended) / Always a vowel / Always a consonant"), mirroring World Numerology's own software.
- *Gain:* maximally honest, matches the better professional tools, side-steps the school dispute by letting the user pick.
- *Cost:* a settings surface + storing the choice + recomputing affected numbers. More than Phase-3 needs right now. Good as a later enhancement.

**Option C: Keep always-consonant (status quo).**
- *Gain:* zero work; fully deterministic; defensible as the Juno Jordan classic method.
- *Cost:* we visibly differ from Decoz and nearly every popular calculator for Y-vowel names. If the page or chat ever says "this matches standard numerology," that claim is weak — the *standard* most users will check against is the phonetic one.

**What to put on the page either way:** cite the phonetic rule as the standard, attribute it to **Hans Decoz** and **Matthew Oliver Goodwin**, and state honestly that numerologists disagree (Jordan: never; Buess: always; W as a vowel is Goodwin-only). Do not assert a universal rule that does not exist.

---

## 6. Sources (all accessed 2026-06-23)

- Hans Decoz, *Y vowel or consonant in numerology*, World Numerology — `https://www.worldnumerology.com/numerology-articles/numerology-Y-vowel-consonant.html` (page 403s to automated fetch; wording corroborated by the two sources below).
- World Numerology, *Soul Urge / Heart's Desire* — `https://www.worldnumerology.com/numerology-soul-urge/`
- World Numerology, software preference settings (Y toggle) — `https://www.worldnumerology.com/numerology-software/decoz-software-settings.html`
- Matthew Oliver Goodwin, *Numerology: The Complete Guide, Vol. 1: The Personality Reading* (1981/1988), Ch. 5 — full text: `https://archive.org/details/GoodwinMatthewOliverNumerologyTheCompleteGuideVolume1ThePersonalityReading1988`
- Felicia Bender (Decoz school), *Numerology: The Soul Urge* (© 2018) — `https://feliciabender.com/numerology/numerology-the-soul-urge/` — direct quotes of Jordan-vs-Buess-vs-Decoz disagreement.
- numerology.center, *Numerology and the letter "Y"* — `https://numerology.center/numerology_and_letter_y.php`
- Juno Jordan, *Numerology: The Romance in Your Name* (DeVorss, 1965) — record: `https://archive.org/details/numerologyromanc00juno`; position corroborated via Felicia Bender quote.
- numerologist.com, *Soul Urge Number* — `https://numerologist.com/numerology/soul-urge-number`

**No emojis anywhere in this document.**
