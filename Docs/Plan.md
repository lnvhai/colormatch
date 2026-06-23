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
- No unit tests (out of scope).

---

## 5. Actionable Task Breakdown

### Milestone 0 — Project setup  ✅ DONE
- [x] Create folder structure on disk: `App/`, `Core/DesignSystem/Components/`, `Core/Models/`, `Core/Services/`, `Core/Extensions/`, `Features/{Home,SpotOdd,MatchColor,Daily,Results,Settings}/`.
- [x] Move `colormatchApp.swift` → `App/`; delete `ContentView.swift`.
- [x] Portrait-only (`UIInterfaceOrientationPortrait`), dark appearance (`UIUserInterfaceStyle = Dark`), iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) in project.pbxproj.
- [x] Add `AppColor.swift` (all 10 palette tokens) in `Core/DesignSystem/`.
- [x] Add `AppTypography.swift` (Display/Title/Body/Caption, SF rounded) in `Core/DesignSystem/`.
- [x] Add reusable components in `Core/DesignSystem/Components/`: `PrimaryButton`, `Card`, `StatBadge`, `ColorTile`.
- [x] `colormatchApp.swift` uses `.preferredColorScheme(.dark)` + stub `HomeView`.

### Milestone 1 — Core engine (no UI)  ✅ DONE
- [x] `Color+Hex.swift` in `Core/Extensions/` (hex string → Color).
- [x] `Color+Lab.swift` in `Core/Extensions/` — sRGB ↔ CIELAB, `deltaE`, `fromLab`. Uses `Color.resolve(in:)` (SwiftUI-only, no UIKit).
- [x] `ScoringEngine.swift` — ΔE → accuracy % (0–100) + level-bonus score.
- [x] `DifficultyCurve.swift` — level → gridSize (2–6), colorDelta (30→3), timeLimit (nil until L5).
- [x] `ColorGenerator.swift` — splitmix64 seeded; `spotOddChallenge` + `matchChallenge`.
- [x] `DailySeed.swift` — date → stable UInt64 seed (YYYYMMDD).
- [x] `PersistenceStore.swift` — protocol + `UserDefaultsStore` (best scores, streak, stats).

### Milestone 2 — Navigation shell & Home  ✅ DONE
- [x] `Route` enum (`spotOdd`, `match`, `daily`, `settings`) in `App/Route.swift`.
- [x] `HomeView`: dark bg, title, stats row (streak/best score/match %), two mode cards, Daily + Settings entries, `NavigationStack` with stub destinations.
- [x] `HomeViewModel` (`@Observable`) wired to `PersistenceStore`, refreshes `onAppear`.

### Milestone 3 — Spot the Odd Color  ✅ DONE
- [x] `GamePhase` enum (`playing`, `levelComplete`, `gameOver`) in `Core/Models/`.
- [x] `SpotOddViewModel` (`@Observable`): level, lives (3), score, timer tick, tap handling, persist best on game over.
- [x] `SpotOddView`: `LazyVGrid` N×N responsive grid, header (level + hearts), timer capsule bar, score, game-over overlay with Play Again / Home.
- [x] Progressive difficulty via `DifficultyCurve` — grid grows, ΔE shrinks, timer kicks in at L5.
- [x] Haptics via `.sensoryFeedback(.success/.error)` on correct/wrong tap counters.
- [x] `HomeView` destination wired: `.spotOdd` → `SpotOddView()`.

### Milestone 4 — Match the Color  ✅ DONE
- [x] `MatchColorViewModel` (`@Observable`): generates match challenge, HSB slider state, `submit()` → accuracy via `ScoringEngine`, persists best.
- [x] `MatchColorView`: target swatch + live guess preview, 3 HSB sliders (tinted to current value), submit button → animated result reveal.
- [x] Result reveal: side-by-side target vs. guess swatches, large accuracy %, color-coded (green ≥90 / blue ≥65 / red <65), "New Best!" badge, Play Again / Home.
- [x] Haptic on submit via `.sensoryFeedback(.success)`.
- [x] `HomeView` `.match` destination wired to `MatchColorView()`.

### Milestone 5 — Daily Challenge  ✅ DONE
- [x] `DailyState` enum: `.lobby / .playing / .done(accuracy, isNewBest) / .alreadyPlayed`.
- [x] `DailyChallengeViewModel`: seeded from `DailySeed.seed()` → level-3 match challenge, checks `lastPlayedDate` on init, `submit()` calls `recordDailyPlay` (updates streak).
- [x] `DailyChallengeView`: lobby (date + streak badge + play button), playing (sliders), done (rating card + streak badge + "Back to Home"), already-played (checkmark + "Come back tomorrow").
- [x] Streak already surfaced on HomeView via `HomeViewModel` (was done in M2).
- [x] `HomeView` `.daily` destination wired to `DailyChallengeView()`.

### Milestone 6 — Results & Settings polish  ✅ DONE
- [x] `SettingsView`: Haptic Feedback toggle (`@AppStorage`), Reset All Stats (confirmation dialog), Version info. Dark card-based layout matching design system.
- [x] `HomeView` `.settings` destination wired to `SettingsView()`.
- [x] Reduce-motion: `@Environment(\.accessibilityReduceMotion)` added to `SpotOddView`, `MatchColorView`, `DailyChallengeView`. All `.animation` + `.transition` + `.scaleEffect` calls conditioned on it.
- [ ] Shared `ResultView` — deferred; each mode has inline result (adequate for MVP).

### Milestone 7 — QA & ship prep
- [ ] Run on iPhone simulator; verify both modes, daily, persistence across relaunch.
- [ ] Fix linter/build warnings.
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
