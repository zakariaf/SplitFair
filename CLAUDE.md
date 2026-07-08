# CLAUDE.md — SplitFair

**This file is a NON-NEGOTIABLE CONTRACT.** Every rule below is binding on every task, every session. When a rule conflicts with convenience, speed, or a "better idea," the rule wins — if a change would violate it, stop and raise it instead of working around it.

SplitFair is a native **iOS / SwiftUI** app that splits a restaurant/grocery bill by **who ordered what** — fully offline, no account, no ads, nothing stored beyond the current bill.

## The four non-negotiables

1. **Exact-cent reconciliation.** Per-person totals MUST sum to the grand total to the exact cent, for any bill. All money is `Int` minor units routed through the single `allocate()` largest-remainder primitive. A `Double`/`Float` must NEVER touch money. Never store a total — totals are always computed. The `$97.20` acceptance bill must stay green.
2. **Offline & private.** No network calls, no analytics, no SDKs, no accounts. Persist only the single current bill on device. The App Store privacy label reads "Data Not Collected."
3. **Right-sized, not enterprise.** Two screens, complexity 2/5. One `@Observable` store. NO ViewModels, NO SwiftData, NO TCA/VIPER/Coordinators. If you reach for one of those, you are wrong — reconsider.
4. **Bold but legible (HARD COPY).** A number NEVER sits on a gradient, chip fill, or glass — money is always ink-on-paper. Depth is a hard offset shadow (0 blur). Exactly one glass element (the footer rail).

## How we build: skills first, epics in order

Detailed rules are NOT in this file — they live in the skills and epics, which are the source of truth:

- **Skills** (`.claude/skills/splitfair-*`) hold the how-to for every area and load on demand. **Before starting any build task, load the `splitfair-*` skill(s) that task names** (e.g. `/splitfair-money-math`). This is mandatory, not optional.
- **Epics** (`epics/`) are the ordered build plan. **Work epics in order; work tasks within an epic in order.** Every task states the skills to load, the steps, and a "Done when" acceptance criterion. Do not skip ahead.

## Finishing a task — the ritual (YOU MUST run every step, in order)

When a task's "Done when" is met, run this ritual before starting the next task. Every step is mandatory:

1. **Verify.** The relevant build/tests are green — run `swift test` for any BillCore/math task.
2. **Review.** Run **`/code-review`** on the working diff and address every finding it surfaces. (You asked for `/review`; on our local `main` workflow with no PRs, `/review` is the GitHub-PR reviewer, so the working-diff reviewer is `/code-review` — use it.)
3. **Simplify.** Run **`/simplify`** and apply its reuse/simplification/efficiency cleanups.
4. **Re-verify** if review or simplify changed code (re-run `swift test`).
5. **Commit — task by task.** One task = one commit, **directly on `main`** (do NOT create branches; no PRs). Never batch multiple tasks into one commit. Message = an imperative one-line summary of the task (e.g. `Implement allocate() largest-remainder primitive`), optional short body, always ending with the trailer:
   `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
6. **State the next task.** This whole ritual — verify → `/code-review` → `/simplify` → commit, once per task — is part of the contract.

## Commands

- **`swift test`** (run in `Packages/BillCore`, available once the package exists — EPIC 02) — the money-math suite, including the `$97.20` reconciliation gate. Run before committing any domain/math task.
- **Build/run the app:** `xcodebuild -scheme SplitFair -destination 'platform=iOS Simulator,name=iPhone 15' build` (available once the Xcode project exists — EPIC 01).
- **Lint/format:** `swiftlint --strict` and `swiftformat .` (configured in EPIC 01; must pass before committing).

## Repo map (pointers — read on demand, do not treat as loaded)

- `epics/` — the build plan (start at `epics/README.md`).
- `.claude/skills/` — the skill library (architecture, money math, design system, per-component rules).
- `SplitFair.md` — product spec (positioning, competitors, roadmap). Product context only, not build rules.
- `SplitFairMockup.html` — the interactive HARD COPY design mockup (reference for how the UI should look/feel).

## Hard gotchas (these cause real bugs)

- **Two rounding sites, not one:** `allocate()` AND `percent → cents`. Round the percent to `Int` once before `allocate()`.
- **`@State private var store` is constructed once at the App root**, then injected — never inside a rebuilt child view.
- **Persist to Application Support, atomic writes, default file protection** (not `.completeFileProtection`); debounce + flush on `scenePhase` leaving `.active`.
- **The design/architecture guidance is the skills** — there is no separate architecture or design doc; do not look for or cite one.
- **Identity is a stored `let id = UUID()`**, never `Equatable`-on-all-fields.

<!-- Maintainer note: keep this file short. Detail belongs in .claude/skills/ (loads on demand) and epics/. If a rule stops mattering, delete it. -->
