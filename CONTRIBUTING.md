# Contributing to SplitFair

Thanks for your interest! SplitFair is a public companion to a YouTube build, so the code is meant to be read, learned from, and improved. Contributions — fixes, tests, docs, thoughtful features — are welcome.

Please read this whole page before opening a pull request. It's short.

## The ground rules (non-negotiable)

SplitFair is defined by four rules in [`CLAUDE.md`](CLAUDE.md). A change that breaks any of them won't be merged:

1. **Exact-cent reconciliation.** All money is integer cents through the single `allocate()` primitive — no `Double`/`Float` ever touches money, and totals are never stored (always computed). **The `$97.20` acceptance bill must stay green.**
2. **Offline & private.** No network calls, analytics, SDKs, accounts, or sync. Nothing leaves the device.
3. **Right-sized.** One `@Observable` store. No ViewModels, SwiftData, TCA/VIPER/Coordinators.
4. **Bold but legible.** No number renders on a gradient, chip, or glass.

If your idea needs one of the things rule 2 or 3 forbids, please open an issue to discuss it first — it may be intentionally out of scope.

## Getting set up

- **Xcode 16+** (iOS 18 SDK), **iOS 17+** target.
- Run the money-math suite (fast, no simulator):
  ```bash
  swift test --package-path Packages/BillCore
  ```
- Build & run the app: open `SplitFair.xcodeproj` and ⌘R on a simulator.
- Formatting/linting (please run before pushing):
  ```bash
  swiftformat .
  swiftlint --strict
  ```

## How the code is organized

- **`Packages/BillCore/`** — the pure, Foundation-only money engine. Any change to money math or the model goes here and must keep the tests green.
- **`SplitFair/`** — the SwiftUI app (`App/`, `Features/`, `DesignSystem/`, `Persistence/`).
- **`epics/`** and **`.claude/skills/`** — the build plan and the how-to guides. If you're adding to an existing area, skim the matching skill first — it explains the intended approach.

## Pull request workflow

The maintainer commits directly to `main`; **external contributors work through pull requests**:

1. **Fork** the repo and create a branch from `main` (e.g. `fix/tip-rounding`).
2. Make one focused change per PR. Keep the diff small and readable.
3. **Run the checks locally:** `swift test --package-path Packages/BillCore`, `swiftformat .`, `swiftlint --strict`.
4. If you touched money math or the model, add or update tests — and make sure the **$97.20** reconciliation bill still passes.
5. Open a PR against `main` with a clear title and description (the template will prompt you). Link any related issue.
6. **CI must be green** and review comments resolved before merge. PRs are squash-merged.

### Commit messages

Use a concise, imperative summary (e.g. `Fix percent→cents double rounding`). Keep each commit to one logical change.

## Reporting bugs & requesting features

Open an issue using the templates. For bugs, include steps to reproduce and — if it's a money bug — the exact items/tax/tip and the expected vs. actual per-person totals (that's the fastest path to a fix).

## Code of conduct

Be kind and constructive. Assume good intent, keep discussion focused on the code, and help keep this a welcoming place to learn.

## License

By contributing, you agree that your contributions are licensed under the repository's [MIT License](LICENSE).
