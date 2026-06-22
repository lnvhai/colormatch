# ColorMatch — Product & Engineering Plan

A minimalist iOS color-perception game that merges the two best-selling mechanics from
[Dialed GG](https://apps.apple.com/us/app/dialed-gg/id6762853449) and
[One Color](https://apps.apple.com/us/app/one-color/id6761573298):

1. **Spot the Odd Color** — find the single different tile in a grid (Dialed GG's signature "outlier" mode).
2. **Match the Color** — recreate a target color with sliders and get scored on precision (One Color's signature mode).

Wrapped in a clean dark UI, progressive difficulty, haptics, daily challenges, and a local leaderboard.

---

## 1. Product Overview

| | Dialed GG | One Color | **ColorMatch (this clone)** |
|---|---|---|---|
| Core loop | Spot the outlier tile in a grid | Recreate a target color, one shot | **Both, selectable from home** |
| Difficulty | Grid grows, hue delta shrinks | Levels / Practice | Progressive in both modes |
| Feel | Minimal dark, haptics | Minimal, precision scoring | Minimal dark + haptics + precision |
| Modes | Outlier, Sound | Daily, Multiplayer, Levels, Practice | Daily, Endless, Levels, Practice |
| Extras | Leaderboards | Ranking, Coins/IAP, Remove Ads | Local stats + Game Center (post-MVP) |

### Target
- Platform: iPhone, iOS 17+ (matches both source apps), SwiftUI.
- Orientation: Portrait only.
- Offline-first; no account required to play.

### Success metric for MVP
A user can open the app, choose either game mode, play progressively harder rounds, see a precision/score result, feel haptic feedback, and have their best score + daily streak persisted between launches.

---

## 2. Core MVP Features

### F1 — Home / Mode Select
- Title, current streak + best score badges.
- Two large mode cards: **Spot the Odd Color** and **Match the Color**.
- Secondary entries: **Daily Challenge**, **Settings**.

### F2 — Spot the Odd Color (Outlier mode)
- Render an `N x N` grid of identical tiles; exactly one has a slightly shifted hue/brightness.
- Tap the odd tile → advance; tap wrong → lose a life / end run.
- **Progressive difficulty:** grid size grows (e.g. 2x2 → 3x3 → … capped), and the color delta (ΔE) between odd tile and the rest shrinks per level.
- Timed pressure (optional per level) + score = levels cleared.
- Win/lose haptics.

### F3 — Match the Color (Recreation mode)
- Show a target color swatch (optionally hidden after a memorize window for a memory variant).
- Player adjusts **Hue / Saturation / Brightness** (or R/G/B) sliders to recreate it.
- Submit once → compute **accuracy %** from perceptual color distance.
- Show side-by-side target vs. guess + accuracy result.

### F4 — Daily Challenge
- One deterministic seeded puzzle per calendar day (same for all users via date-based seed).
- Tracks **streak** (consecutive days played) and stores today's result.

### F5 — Results / Scoring
- Per-round result screen: score / accuracy %, "New best!" indicator, Play Again, Home.
- Precision scoring engine shared across modes.

### F6 — Persistence & Stats
- Store best scores per mode, daily streak, last-played date, total games.
- `UserDefaults` (or SwiftData) — local only for MVP.

### F7 — Design System & Feel
- Dark, minimalist theme; single accent color; large tap targets.
- Haptic feedback (success/failure/selection) via Core Haptics / `UIFeedbackGenerator`.

### Explicitly OUT of MVP (Phase 2+)
- Sound-matching mode (Dialed GG), Multiplayer (One Color), Coins/IAP & Remove-Ads, Game Center leaderboards, ads SDK, localization.

---

## 3. Color Scheme & Visual Design

Minimalist "focus the eye on the colors" aesthetic. The chrome is near-monochrome so the gameplay colors pop.

### Palette (dark, primary theme)
| Token | Hex | Use |
|---|---|---|
| `background` | `#0B0B0F` | App background (near-black) |
| `surface` | `#16171D` | Cards, sheets, tiles container |
| `surfaceElevated` | `#1F2129` | Elevated cards, modals |
| `textPrimary` | `#F5F5F7` | Headlines, scores |
| `textSecondary` | `#9A9AA5` | Subtitles, captions |
| `accent` | `#5E9BFF` | Primary buttons, highlights, streak badge |
| `accentMuted` | `#33406B` | Pressed/disabled accent |
| `success` | `#3DDC84` | Correct answer, high accuracy |
| `failure` | `#FF5C5C` | Wrong answer, low accuracy |
| `divider` | `#26272F` | Hairlines |

> Define these once in a `Theme`/`AppColor` enum and reference everywhere. Provide a light variant later; dark is the default and matches both source apps.

### Typography
- System font (SF), rounded design for a friendly minimal look.
- Scale: Display 34/Bold, Title 22/Semibold, Body 17/Regular, Caption 13/Medium. Respect Dynamic Type.

### Layout & motion
- Generous spacing (16/24 grid), large rounded cards (corner radius 20–24).
- Subtle spring animations on tile tap, result reveal, slider feedback.
- Reduce-motion respected.

### Accessibility
- Don't rely on color alone for UI state (use icons/labels).
- The *gameplay* is intentionally color-based, but provide a "colorblind hint" toggle (Phase 2) and ensure all chrome meets WCAG AA contrast.

---

## 4. Code Architecture

**Pattern:** SwiftUI + MVVM, feature-foldered, with a small shared services layer. Pure-Swift game logic (color gen + scoring) kept UI-independent so it is unit-testable.

### Folder structure (under `Code/colormatch/colormatch/`)
```
colormatch/
├─ App/
│  └─ colormatchApp.swift            // @main, root navigation
├─ Core/
│  ├─ DesignSystem/
│  │  ├─ AppColor.swift              // palette tokens
│  │  ├─ AppTypography.swift         // font styles
│  │  └─ Components/                 // PrimaryButton, Card, StatBadge, ColorTile…
│  ├─ Models/
│  │  ├─ GameMode.swift              // enum: spotOdd, match, daily
│  │  ├─ ColorChallenge.swift        // target color, grid spec, level, seed
│  │  └─ RoundResult.swift           // score, accuracy, isNewBest
│  ├─ Services/
│  │  ├─ ColorGenerator.swift        // builds grids & targets per difficulty/seed
│  │  ├─ ScoringEngine.swift         // perceptual color distance → accuracy %
│  │  ├─ DifficultyCurve.swift       // level → gridSize, ΔE, time
│  │  ├─ HapticManager.swift         // success/failure/selection
│  │  ├─ PersistenceStore.swift      // best scores, streak, stats (UserDefaults/SwiftData)
│  │  └─ DailySeed.swift             // date → deterministic seed
│  └─ Extensions/
│     └─ Color+Hex.swift, Color+Lab.swift
├─ Features/
│  ├─ Home/                          // HomeView + HomeViewModel
│  ├─ SpotOdd/                       // SpotOddView + SpotOddViewModel
│  ├─ MatchColor/                    // MatchColorView + MatchColorViewModel
│  ├─ Daily/                         // DailyChallengeView + ViewModel
│  ├─ Results/                       // ResultView
│  └─ Settings/                      // SettingsView
└─ Resources/
   └─ Assets.xcassets
```

### Key design decisions
- **`ColorGenerator` & `ScoringEngine` are deterministic, side-effect-free** → seedable for Daily Challenge and fully unit-testable.
- **Scoring uses perceptual distance.** Convert RGB → CIELAB and compute ΔE (CIE76 for MVP, CIEDE2000 later); map to a 0–100% accuracy. This is fairer than naive RGB Euclidean distance.
- **Difficulty is data, not branching.** `DifficultyCurve` maps `level → (gridSize, colorDelta, timeLimit?)` so both balancing and testing are easy.
- **Navigation** via a single `NavigationStack` + an enum `Route`; ViewModels own state, Views are declarative.
- **State containers** use `@Observable` (iOS 17 Observation) ViewModels; inject services via initializers (lightweight DI) for testability.
- **Persistence** behind a `PersistenceStore` protocol so the backing store (UserDefaults now, SwiftData/CloudKit later) can change without touching features.

### Testing
- Unit tests: `ScoringEngine` (known color pairs → expected %), `ColorGenerator` (odd tile differs by exactly ΔE; same seed → same output), `DifficultyCurve` (monotonic), `DailySeed` (stable per date).
- Snapshot/UI smoke tests for Home and each game screen (Phase 2).

---

## 5. Actionable Task Breakdown

### Milestone 0 — Project setup
- [ ] Reorganize project into the `App / Core / Features / Resources` folder structure.
- [ ] Set deployment target to iOS 17, portrait-only, dark appearance default.
- [ ] Add `AppColor` palette and `AppTypography` from §3.
- [ ] Add reusable components: `PrimaryButton`, `Card`, `StatBadge`, `ColorTile`.

### Milestone 1 — Core engine (no UI)
- [ ] `Color+Hex` and `Color → CIELAB` conversion extensions.
- [ ] `ScoringEngine`: ΔE-based accuracy % (0–100). Add unit tests.
- [ ] `DifficultyCurve`: level → grid size, color delta, optional time. Add unit tests.
- [ ] `ColorGenerator`: seedable grid (one odd tile) + target color generation. Add unit tests.
- [ ] `DailySeed`: date → stable seed.
- [ ] `PersistenceStore` protocol + UserDefaults implementation (best scores, streak, stats).

### Milestone 2 — Navigation shell & Home
- [ ] `NavigationStack` + `Route` enum.
- [ ] `HomeView`: title, streak + best-score badges, two mode cards, Daily + Settings entries.
- [ ] Wire `HomeViewModel` to `PersistenceStore` for displayed stats.

### Milestone 3 — Spot the Odd Color
- [ ] `SpotOddViewModel`: level state, grid generation, tap handling, lives/time, scoring.
- [ ] `SpotOddView`: responsive `N x N` grid, tap to select, win/lose flow.
- [ ] Progressive difficulty + haptics (success/failure).
- [ ] Route to Results on game over; persist best.

### Milestone 4 — Match the Color
- [ ] `MatchColorViewModel`: target generation, HSB slider state, submit → accuracy.
- [ ] `MatchColorView`: target swatch, 3 sliders, live preview, submit.
- [ ] Result reveal: target vs. guess side-by-side + accuracy %. Haptics.
- [ ] Persist best accuracy.

### Milestone 5 — Daily Challenge
- [ ] `DailyChallengeView` using `DailySeed` (same puzzle per day).
- [ ] Streak tracking + "already played today" state.
- [ ] Surface streak on Home.

### Milestone 6 — Results & Settings polish
- [ ] Shared `ResultView` (score/accuracy, New best!, Play Again, Home).
- [ ] `SettingsView`: haptics toggle, reduce motion respect, reset stats, about/links.
- [ ] Spring animations + reduce-motion handling.

### Milestone 7 — QA & ship prep
- [ ] Run on iPhone 17 Pro simulator; verify both modes, daily, persistence across relaunch.
- [ ] Fix linter/build warnings; ensure unit tests green.
- [ ] App icon + accent color asset; basic App Store metadata draft.

### Phase 2 (post-MVP backlog)
- [ ] Sound-matching mode (Dialed GG parity).
- [ ] Game Center leaderboards & achievements.
- [ ] Multiplayer / pass-and-play.
- [ ] Monetization: ads SDK + Remove-Ads IAP + coins.
- [ ] Colorblind assist mode, light theme, localization, CloudKit sync.

---

## 6. Open Questions / Assumptions
- **Match mode input:** assuming HSB sliders (more intuitive than RGB). Confirm preferred control.
- **Match mode memory variant:** One Color hides the target ("memory"); MVP shows it persistently. Add hide-after-delay as a difficulty toggle.
- **Scoring model:** assuming ΔE (CIELAB) for fairness; confirm if a simpler RGB% is preferred to match a specific competitor's feel.
- **Persistence backend:** UserDefaults for MVP; revisit SwiftData if stats grow.
