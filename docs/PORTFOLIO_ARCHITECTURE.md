Moon Rhythms — Architecture Design & Software Structure

What I'm building

Moon Rhythms is a personal-astrology app. You enter your birth details, it builds your chart, and an AI guide explains what it all actually means in plain language instead of generic horoscope stuff. The main feature is a chat advisor that answers questions about you using your real chart data, and on the paid tier it can talk about your relationship with one other person too.

I'm building it as two front-ends on one back-end: a web app at moonrhythms.io (Next.js) and a native mobile app (Expo / React Native). Both hit the same REST API and the same Supabase (PostgreSQL) database, so you can sign up on one and log in on the other. The rest of this describes how the pieces fit together.

Overall architecture

It's a three-tier setup. The front-end (mobile + web) handles the UI, navigation, and the login session, plus a little quick math on the device so things feel instant. The back-end is a set of REST endpoints at moonrhythms.io/api that does all the real work: the astrology calculations, the AI calls, security, and cost tracking. The data tier is Supabase — PostgreSQL with the pgvector extension for AI search, plus auth. The back-end also calls out to Anthropic (Claude) for the AI text and OpenAI for embeddings.

The key decision is that the mobile app is a thin client. It does no astrology and holds no secrets — everything important happens on the server. That keeps the two front-ends consistent (they can't drift apart because they share one source of truth) and keeps the expensive, sensitive logic off people's phones. The one thing the client does locally is light, predictable stuff like picking the right moon image and smoothly animating the moon's position between server updates.

REST API

It's a normal REST API over HTTPS using JSON, with the usual verbs (GET to read, POST to create, PATCH to update, DELETE to remove). Public endpoints don't need a login — current moon position, the moon timeline, timezone lookup, and chart calculation. Protected endpoints require a Bearer token (the login token from Supabase) and return 401 if it's missing or 403 if you try to touch data that isn't yours.

The main endpoints:

- /moon-position and /moon-timeline — current and upcoming moon data (public)
- /timezone — resolve a birthplace's UTC offset (public)
- /SwissEphemerisChart — calculate a natal chart (public)
- /save-reading and /readings — save and list a user's charts (protected)
- /profile — read or update your own profile (protected)
- /synthesize-profile-summary — generate the AI summary of a person (protected)
- /chat-sessions and /chat-messages — manage chat threads and their history (protected)
- /chat-respond — generate a streamed AI reply (protected)

Database

I'm using PostgreSQL, not a document database, so there's no Mongoose here. The design is a hybrid: normal relational tables and columns for anything I need to query, filter, or join (IDs, foreign keys, plan tier, timestamps), and JSONB document columns for blobs I just store and read back whole — like the full chart output, the AI's cited sources, and subscription webhook payloads. Columns for what you query, JSON for what you read as a unit.

The tables fall into three groups. User data (accounts, profiles, birth data, charts, AI summaries, relationships, subscriptions), knowledge (a table of interpretation text, each row carrying a vector embedding for AI search), and interaction (chat sessions, chat messages, and a log of every AI call with its token count and cost). There's also a set of reference tables holding fixed astrology facts.

Security lives in the database itself through Row-Level Security. Every user table has rules so a query only ever returns rows that belong to the logged-in user — default deny, no exceptions. AI-written data and reference data can only be written by the server, never directly by a client.

Server-side business logic

The interesting part is the AI pipeline, and it follows two rules. First, the AI never makes up astrology — it's handed real facts from the chart plus curated interpretation text, and its job is just to combine them into a useful answer. Second, synthesize once and reuse. When a chart is first created I make one high-quality Claude call to write a lasting summary of that person and store it. Every later chat message reuses that summary instead of re-reading the raw chart, which is far cheaper.

When someone sends a chat message, the server checks their login, saves the message, turns it into an embedding, pulls the most relevant interpretation chunks out of the database by similarity, builds a prompt from the saved summary plus those chunks plus recent history, calls Claude with streaming on, and sends the reply back word by word. Then it logs the cost and saves the answer. Free users are capped and the limit is checked before the expensive AI call, not after.

Communication

Normal calls send and receive JSON over HTTPS, and protected calls add an Authorization: Bearer <token> header that the app attaches automatically. The chat endpoint is the exception — instead of one big response it streams Server-Sent Events so the answer appears a few characters at a time and feels fast. The client listens for a start event, a stream of token events, and a final done event that includes the cost. Logins are handled by Supabase, which issues a token that the mobile app stores on the device and refreshes automatically, so you stay signed in between app launches.

Conclusion

The result is a cross-platform app (web and mobile) on one shared back-end where a user gets an accurate, server-calculated chart and an AI guide that answers questions grounded in their own data, with every AI call tracked and limited by tier so the costs stay sane and a paid relationship feature can sit on top cleanly. The whole structure is built around keeping the two front-ends consistent, the costs controlled, and people's data private by default — the device does fast, simple work and the server does everything that's expensive, sensitive, or has to be correct.

References

Fielding, R. T. (2000). Architectural Styles and the Design of Network-based Software Architectures (the REST dissertation) — https://ics.uci.edu/~fielding/pubs/dissertation/top.htm
Supabase docs (Database, Auth, Row-Level Security) — https://supabase.com/docs
PostgreSQL JSON/JSONB types — https://www.postgresql.org/docs/current/datatype-json.html
pgvector — https://github.com/pgvector/pgvector
Expo / React Native — https://docs.expo.dev
Next.js — https://nextjs.org/docs
Anthropic Claude API — https://docs.anthropic.com
OpenAI embeddings — https://platform.openai.com/docs/guides/embeddings
Server-Sent Events (MDN) — https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events
Swiss Ephemeris — https://www.astro.com/swisseph/
