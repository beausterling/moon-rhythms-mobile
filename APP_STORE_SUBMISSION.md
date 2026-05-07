# App Store Submission Checklist — Moon Rhythms

Master tracker for getting Moon Rhythms onto the iOS App Store and Google Play Store. Work top-to-bottom; items in **bold** block submission.

---

## 0 · Accounts & Tooling (one-time)

- [ ] **Apple Developer Program** enrollment — $99/yr — https://developer.apple.com/programs/enroll/
  - Individual or Organization? Org needs D-U-N-S number (~2 weeks lead time). Individual is faster.
- [ ] **Google Play Console** account — $25 one-time — https://play.google.com/console/signup
- [ ] **Expo account** — free — `eas login`
- [ ] `eas init` run in repo root → adds `extra.eas.projectId` to `app.json`
- [ ] `eas credentials` configured — let EAS manage iOS certs/provisioning + Android keystore (recommended; skip Xcode cert hell)

---

## 1 · App Configuration (`app.json`)

- [x] `name`: Moon Rhythms
- [x] `slug`: moon-rhythms
- [x] `version`: 1.0.0 — bump for each store release (semver: 1.0.1, 1.1.0, etc.)
- [x] `ios.bundleIdentifier`: com.moonrhythms.app
- [x] `android.package`: com.moonrhythms.app
- [x] `icon`: ./assets/icon.png (1024×1024, no alpha)
- [x] `splash`: configured, black background
- [x] `android.adaptiveIcon.backgroundColor`: #000000
- [x] `userInterfaceStyle`: dark
- [x] `orientation`: portrait
- [x] `ios.infoPlist.NSLocationWhenInUseUsageDescription`: present
- [ ] `ios.buildNumber` — incremented on every TestFlight upload (EAS `autoIncrement: true` handles this in production profile)
- [ ] `android.versionCode` — same, integer auto-incremented per Play upload
- [ ] `ios.supportsTablet`: confirm true is desired (current: true)
- [ ] `ios.requireFullScreen`: leave false (iPad multitasking)
- [ ] Add `ios.config.usesNonExemptEncryption: false` to `app.json` — avoids the export-compliance question on every TestFlight upload (true only if you ship custom crypto, which you don't — Supabase uses HTTPS, that's exempt)

---

## 2 · Legal & Privacy (BLOCKERS)

- [ ] **Privacy Policy URL** — public webpage. Apple + Google both require it. Must disclose:
  - Email address collection (Supabase auth)
  - Location collection (when-in-use, for moon position calc)
  - No third-party analytics yet → state that explicitly
  - Data retention, deletion request process
  - Recommended host: `moonrhythms.io/privacy` (you control the domain)
- [ ] **Terms of Service URL** — recommended, not required
- [ ] **Support URL** — required by Apple. Can be `moonrhythms.io/support` or a contact email page
- [ ] **Account deletion flow inside the app** — Apple requires this for any app with sign-up (App Store Review Guideline 5.1.1(v)). Add a "Delete Account" button in Settings → calls Supabase admin API to hard-delete user
- [ ] **App Tracking Transparency**: not needed unless you add an ad SDK or third-party analytics
- [ ] **Sign in with Apple**: NOT required currently (you only offer email/password). Becomes required the moment you add Google/Facebook/etc. sign-in
- [ ] **Privacy Manifest** (`PrivacyInfo.xcprivacy`) — Expo prebuild generates this automatically. Verify it lists data types collected: email, coarse location

---

## 3 · App Store Connect Listing (iOS)

- [ ] **App name** (30 char max): Moon Rhythms
- [ ] **Subtitle** (30 char max): suggest "Your daily lunar guide" or similar
- [ ] **Promotional text** (170 char max, editable without resubmit) — use for current campaign / what's new
- [ ] **Description** (4000 char max) — the long sell. Lead with the core value: *"Open the app, instantly see where the moon is — sign, phase, illumination, degree."*
- [ ] **Keywords** (100 char max, comma-separated, no spaces) — examples: `moon,lunar,astrology,zodiac,phase,human design,natal,birth chart,moon sign`
- [ ] **Category**: Lifestyle (primary), Reference (secondary)
- [ ] **Age rating questionnaire** — likely 4+ unless you add user-generated content
- [ ] **Pricing**: Free
- [ ] **Availability**: All territories (or restrict if needed)
- [ ] **In-App Purchases**: none for v1
- [ ] **Sign-In Required to Use App** flag: YES (you require auth before any tabs)
- [ ] **Demo account credentials** — Apple reviewers need a working test account. Create `reviewer@moonrhythms.io` in Supabase with a known password, document in App Review Information
- [ ] **App Review notes** — explain location permission rationale, demo account creds, anything non-obvious

### Screenshots (required sizes for iOS)

Apple uses the largest device sizes you submit and synthesizes the rest. Minimum required:

- [ ] **iPhone 6.9"** (iPhone 17 Pro Max): 1320×2868 — 3 to 10 screenshots
- [ ] **iPhone 6.5"** (iPhone 11 Pro Max / 14 Plus): 1242×2688 — 3 to 10 screenshots (legacy fallback)
- [ ] **iPad 13"** (iPad Pro M4): 2064×2752 — only required if `supportsTablet: true` (yours is)

**Suggested screenshots:**
1. Home — moon position + scrubber
2. Sign in / welcome
3. Birth matrix / natal chart
4. Quiz results
5. Dashboard

Tip: capture in iOS simulator (`Cmd+S` saves to Desktop), use Xcode > Window > Devices to grab from a real device, or use Fastlane Frameit / RocketSim for framed marketing shots.

- [ ] **App Preview videos** (optional, 15-30 sec, .mov/.m4v) — punchier than screenshots if you have time

### App icon for App Store listing

- [x] 1024×1024 RGB, no alpha, no rounded corners — already in `assets/icon.png`
- Apple displays it on the listing page; the home-screen icon is auto-generated from the same file by Expo prebuild

---

## 4 · Google Play Console Listing (Android)

- [ ] **App title** (30 char max): Moon Rhythms
- [ ] **Short description** (80 char max)
- [ ] **Full description** (4000 char max) — can largely reuse iOS
- [ ] **App category**: Lifestyle
- [ ] **Tags**: pick 5 from Google's predefined list (e.g., Lunar, Astrology, Astronomy, Personal, Reference)
- [ ] **Content rating questionnaire** — IARC-based, takes 5 min
- [ ] **Target audience and content** — declare 13+ or whatever fits
- [ ] **Data safety form** — Play's version of Apple's privacy nutrition label. Declare every data type collected by the app *and* by SDKs (Supabase = email + auth tokens)
- [ ] **News app declaration**: No
- [ ] **COVID-19 / health declaration**: No

### Graphic assets (Play Store)

- [ ] **App icon**: 512×512 PNG (Play resizes from this; supply higher than 512 if you want, max 1024)
- [ ] **Feature graphic**: 1024×500 PNG/JPG — appears at top of listing. Important for conversion
- [ ] **Phone screenshots**: at least 2, max 8. 16:9 or 9:16, min 320px, max 3840px on long edge
- [ ] **7" tablet screenshots** (optional)
- [ ] **10" tablet screenshots** (optional)
- [ ] **Promo video** (optional): YouTube URL

### Internal testing track (do this before production)

- [ ] Set up Internal Testing track in Play Console
- [ ] Add tester emails (yours + a few)
- [ ] `eas submit --profile production --platform android` first goes here
- [ ] Validate on real Android device, then promote to Production

---

## 5 · Build & Submit Commands

```bash
# One-time per repo
eas init
eas credentials      # configure signing for both platforms

# Test build for simulator (free, fast)
eas build --profile development --platform ios

# Internal-distribution build for sideloading or TestFlight internal
eas build --profile preview --platform ios
eas build --profile preview --platform android

# Production build for store submission
eas build --profile production --platform ios
eas build --profile production --platform android

# Submit to stores (requires App Store Connect / Play Console set up)
eas submit --profile production --platform ios
eas submit --profile production --platform android
```

---

## 6 · Pre-Submission QA

- [ ] **iOS Simulator** smoke test — launch, sign up, sign in, all tabs work, sign out
- [ ] **Real iPhone** test (any iOS 16+) — required to catch keyboard/safe-area/permission bugs the simulator hides
- [ ] **Android Emulator** smoke test — same flow
- [ ] **Real Android device** test (Android 10+)
- [ ] **Slow network** test — Network Link Conditioner on iOS, Throttling on Android emulator. App should not hang or crash on 3G
- [ ] **Offline** test — app should show cached data with stale indicator, not white-screen
- [ ] **Cold launch performance** — < 3s to first interactive screen on a 3-year-old device
- [ ] **Memory** — no leaks during 5-min session (Xcode Instruments → Allocations)
- [ ] **Accessibility** — VoiceOver basic flow works, dynamic type doesn't break layout, all touch targets ≥ 44pt
- [ ] **Crash-free** — TestFlight crash reports should be empty before promoting to App Store
- [ ] **Account deletion flow** — actually deletes the account, doesn't just sign out

---

## 7 · TestFlight (iOS) — Beta before public release

- [ ] First production build uploaded via `eas submit`
- [ ] Internal testers (up to 100, no review needed) — add via App Store Connect → TestFlight
- [ ] Accept Apple's "Export Compliance" prompt (answer No to encryption since you set `usesNonExemptEncryption: false`)
- [ ] External testers (up to 10,000, requires Beta App Review — usually approved in 24h)
- [ ] Collect feedback for ≥ 1 week before submitting for App Store Review
- [ ] Test deep links (`moon-rhythms://`) on real devices

## 7b · Closed Testing (Android) — same idea

- [ ] Internal testing track → Closed testing → Open testing → Production (gradual rollout)
- [ ] At least 14 days of closed testing with 12+ testers is required for new personal Play Console accounts (Google's 2024 policy)

---

## 8 · App Store Review Submission

- [ ] All checklist items above ✓
- [ ] Build uploaded and processed in App Store Connect
- [ ] Listing fully filled out (description, screenshots, keywords, etc.)
- [ ] Demo account creds provided in App Review Information
- [ ] App Review notes explain: location permission usage, what testers should try, anything non-obvious
- [ ] Click **Submit for Review**
- [ ] Typical review time: 24-48 hours. First submission often hits a rejection — read the message carefully, fix, resubmit. Don't take it personally.

---

## 9 · Post-Launch

- [ ] Monitor App Store Connect → Crashes
- [ ] Monitor Play Console → Android Vitals (ANRs, crashes)
- [ ] Set up Sentry or similar for prod error tracking (optional but recommended)
- [ ] Respond to App Store / Play Store reviews
- [ ] Plan next OTA update via `eas update` (no app review needed for JS-only changes)
- [ ] Watch retention metrics — ambient apps live or die on day-7 retention

---

## Common Rejection Reasons (avoid these)

1. **Missing account deletion** — must be in-app, not just "email us"
2. **Crashes on launch** — always test the production build before submitting
3. **Broken demo account** — reviewers can't get past sign-in → instant reject
4. **Misleading screenshots** — must reflect actual app, not mockups
5. **Permission usage descriptions too vague** — Apple wants specifics ("calculate moon position for your coordinates" ✓ vs "for app features" ✗)
6. **Privacy policy URL 404** — common stupid mistake; verify the link before submitting
7. **Login required without value** — if you require sign-up, the app must offer real value post-login. Phase 1+2 covers this.

---

## Reference Links

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Play Console policies: https://play.google.com/console/about/programs/playintegrity/
- Expo EAS docs: https://docs.expo.dev/eas/
- App Store Connect: https://appstoreconnect.apple.com/
- Play Console: https://play.google.com/console/
