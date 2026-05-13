# Moon Rhythms Mobile

> Native mobile companion to [moonrhythms.io](https://moonrhythms.io) — an ambient lunar awareness app for iOS and Android. Open it and instantly see where the moon is: sign, phase, illumination, degree.

Built with **Expo SDK 54**, **React Native**, **TypeScript**, and **Supabase**. This is my **Nucamp React Native Bootcamp Honors Project**.

---

## 📸 Screens

| Welcome | Home | Dashboard |
| :---: | :---: | :---: |
| ![Welcome screen with moon and starfield](docs/screenshots/welcome.png) | ![Home screen with live moon position](docs/screenshots/home.png) | ![Dashboard with saved readings](docs/screenshots/dashboard.png) |
| Animated moon + starfield gate before auth | Live phase, illumination, zodiac sign, and 72-hour time scrubber | Saved birth charts, Human Design, and quiz results |

---

## ✨ Features

- **Live moon position** — current zodiac sign, phase name, illumination %, and degree, refreshed in real time
- **72-hour time scrubber** — drag back and forward in time to see where the moon was or will be (60fps Reanimated gestures)
- **Personality quizzes** — MBTI (32q), Big Five (50q), Enneagram (36q), DISC (28q). Scored client-side, work offline
- **Birth matrix** — natal chart and Human Design bodygraph from your birth data
- **Saved readings dashboard** — review your charts and quiz results, organized by type
- **Local notifications** — get pinged when the moon changes signs (no push server; transits are deterministic)
- **Offline-capable** — cached data with stale-indicator fallback
- **Persistent auth** — Supabase sessions stored via `expo-sqlite`

---

## 📱 Tech Stack

| Layer            | Choice                                            |
| ---------------- | ------------------------------------------------- |
| Framework        | Expo SDK 54 (managed workflow) + Expo Router     |
| Runtime          | React Native 0.81.5 / React 19.1                  |
| Language         | TypeScript (strict mode)                          |
| Styling          | NativeWind v4 (Tailwind CSS for React Native)     |
| Auth & DB        | Supabase (shared with the web app)                |
| Session storage  | `expo-sqlite` (localStorage polyfill)             |
| Animations       | React Native Reanimated 4 + Gesture Handler       |
| Images           | `expo-image` (CDN-cached moon frames)             |
| Notifications    | Local notifications (deterministic moon transits) |

---

## 🏗️ Architecture

Thin HTTP client. All astronomical calculations are server-side (Swiss Ephemeris on Node.js at moonrhythms.io). The mobile app consumes 14 API endpoints at `moonrhythms.io/api/`:

- **Public** endpoints (moon position, quizzes, chart data) — no auth required
- **Protected** endpoints (profile, readings, save-reading) — accept Bearer tokens

Quiz scoring is pure JS copied from the web app's `lib/` so it can run client-side for offline support.

Moon phase imagery comes from 712 pre-rendered WebP frames (indices 649–1360) served from the Vercel CDN at `moonrhythms.io/images/moon-cycle/moon.NNNN.webp`.

```
┌──────────────────────┐        ┌──────────────────────┐
│ Moon Rhythms Mobile  │  HTTP  │ moonrhythms.io       │
│ (this repo)          │ ─────► │ Next.js + Swiss Eph. │
│                      │        │                      │
│ Expo / RN / NW       │ ◄───── │ Vercel CDN (frames)  │
└──────────────────────┘        └──────────────────────┘
         │
         │ Auth + reads/writes
         ▼
   ┌──────────────┐
   │   Supabase   │
   └──────────────┘
```

---

## 🚀 Getting Started

### Prerequisites

- **Node.js** ≥ 18
- **npm** ≥ 10
- **Xcode** (for iOS Simulator) or **Android Studio** (for the Android Emulator)
- An **Expo Go** install on a physical device works too

### Install

```bash
git clone https://github.com/beausterling/moon-rhythms-mobile.git
cd moon-rhythms-mobile
npm install
```

### Environment

Create `.env.local` in the project root:

```env
EXPO_PUBLIC_SUPABASE_URL=your-supabase-url
EXPO_PUBLIC_SUPABASE_ANON_KEY=your-supabase-anon-key
EXPO_PUBLIC_GOOGLE_MAPS_API_KEY=your-google-maps-key
```

### Run

```bash
npx expo start -c
```

Then press `i` for iOS Simulator, `a` for Android Emulator, or scan the QR code in Expo Go on your device.

---

## 📂 Project Structure

```
moon-rhythms-mobile/
├── app/                      # Expo Router (file-based routes)
│   ├── _layout.tsx           # Root layout: fonts, providers, gate
│   ├── (auth)/               # Pre-auth stack
│   │   ├── welcome.tsx       # Welcome screen w/ moon loop animation
│   │   ├── sign-in.tsx
│   │   └── sign-up.tsx
│   └── (tabs)/               # Authenticated tab nav
│       ├── index.tsx         # Home: live moon + 72h scrubber
│       ├── quizzes.tsx       # Personality quizzes
│       └── dashboard.tsx     # Saved readings
├── components/               # Shared UI
├── hooks/                    # React hooks (useMoonPosition, etc.)
├── lib/                      # API client, moon-calc, scoring
├── assets/                   # Fonts, icons, splash
├── supabase/                 # Migration scripts
└── docs/                     # Internal docs
```

---

## 🗺️ Roadmap

- [x] **Phase 1 — Foundation & Auth.** Tab nav, dark theme, Josefin Sans, Supabase auth with persistent sessions, sign in/up/out flows
- [x] **Phase 2 — Home Screen.** Live moon position, 72-hour scrubber, offline fallback
- [ ] **Phase 3 — Birth Matrix.** Birth-data entry, natal chart SVG wheel, Human Design bodygraph (WebView v1)
- [ ] **Phase 4 — Personality Quizzes.** MBTI, Big Five, Enneagram, DISC with client-side scoring
- [ ] **Phase 5 — Dashboard.** Saved readings viewer with offline cache
- [ ] **Phase 6 — Notifications & Settings.** Moon-sign-change notifications, settings screen
- [ ] **Phase 7 — Moon Animation.** Full-year animated moon player
- [ ] **Phase 8 — Platform Polish.** iOS/Android Simulator verification, safe-area handling, keyboard avoidance

---

## 🎨 Design Tokens

| Token            | Value     | Use                                 |
| ---------------- | --------- | ----------------------------------- |
| `background`     | `#0a0a1a` | Deep navy — 60% dominant            |
| `surface`        | `#12122a` | Cards, input fields                 |
| `border`         | `#2a2a4a` | Input borders (idle)                |
| `text-primary`   | `#e8e8f0` | Body text                           |
| `text-secondary` | `#8888aa` | Muted labels, placeholders          |
| `accent`         | `#7BA5FF` | CTAs, active tab, focused borders   |
| `destructive`    | `#ef4444` | Error text, error borders           |

**Typography:** Josefin Sans (400 Regular, 600 SemiBold)
**Spacing:** multiples of 4px. Touch targets ≥ 44×44px.

---

## 🔗 Related

- **Web companion:** [moonrhythms.io](https://moonrhythms.io)
- **Source for astronomical calculations:** Swiss Ephemeris (server-side)

---

## 🎓 About

This project is my **Honors Project** for the [Nucamp](https://www.nucamp.co) React Native Mobile App Development bootcamp. It's a real, ship-ready mobile companion to a production web app I built — exercising end-to-end product thinking, native UX patterns, offline-capable design, and integration with an existing backend.

---

## 👤 Author

**Beau Sterling**
[github.com/beausterling](https://github.com/beausterling)
