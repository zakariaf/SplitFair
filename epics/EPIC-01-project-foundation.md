# EPIC 01 — Project Foundation & Tooling

> Turn an empty repo into a buildable, runnable, correctly-configured SwiftUI app skeleton.

## What this epic is for

This epic stands up everything that must exist *before* a single line of product logic is written: the Xcode app target, the pure `BillCore` Swift package (the "compile firewall" that keeps money math free of UI), the by-feature folder structure, the lint/format/CI tooling, and the privacy + build configuration that backs the "Data Not Collected" promise. Getting the scaffold right here is cheap; retrofitting it after eight epics of code is expensive — a wrong deployment target, a leaked `import SwiftUI` in the domain, or a missing privacy manifest are the kinds of mistakes that quietly compound. When this epic is done, every later epic simply drops files into a ready, correct place and builds.

## Where we are before starting (starting state)

- A git repo containing only the product spec (`SplitFair.md`), the HTML mockup (`SplitFairMockup.html`), and the `.claude/skills/` library.
- A `.gitignore` already tuned for Xcode/Swift (ignores `DerivedData/`, `.build/`, `xcuserdata/`, `.DS_Store`).
- **No** `SplitFair.xcodeproj`, **no** Swift code, **no** `Packages/BillCore`, **no** build product. Nothing compiles or runs yet.
- Xcode 26 available locally (required for the iOS 26 SDK / Liquid Glass), Swift 6.x toolchain.

## What we will have after finishing (definition of done)

- An **iOS 17.0** SwiftUI app that **builds and launches** in the simulator to a placeholder root screen, with no AppDelegate/SceneDelegate.
- The app configured for **Swift 6 language mode** with **Swift 6.2 Approachable Concurrency** (default actor isolation = `MainActor`), `GENERATE_INFOPLIST_FILE=YES`, built against the **newest SDK**.
- A **local `Packages/BillCore`** Swift package (`swift-tools 6.0`) with one library target + one **Swift Testing** target, **Foundation-only** (no SwiftUI/UIKit), linked into the app; `swift test` runs green (even with zero tests yet) from `Packages/BillCore`.
- The app target organized **by feature** with file-system-synchronized groups present: `App/`, `Features/Bill/`, `Features/Totals/`, `DesignSystem/`, `Persistence/`, `Sharing/`.
- **SwiftFormat + SwiftLint** configured, a **pre-commit hook** wired, `swiftlint --strict` and `swift test` running in a CI job.
- **`PrivacyInfo.xcprivacy`** present (`NSPrivacyTracking = false`, empty collected-data & tracking-domains, UserDefaults reason `CA92.1`), `ITSAppUsesNonExemptEncryption = NO`, **no** ATT, **no** `.entitlements`.

## Dependencies

- Depends on: none (this is the first epic).
- Enables: EPIC 02 — The Money Engine (BillCore), which fills the empty `BillCore` library and Swift Testing target with the domain and math.

---

## Tasks

### Task 1.1 — Create the Xcode app project

**Skills to load:** `splitfair-app-architecture`, `splitfair-project-structure`

**Why this matters:** The project settings chosen here are load-bearing for every later epic. The deployment target gates which APIs are legal (`@Observable` and `.sensoryFeedback` require iOS 17); the concurrency mode determines whether the whole codebase is `@MainActor` by default (so value-type models are trivially `Sendable` and you never hand-write `@Sendable`); and `GENERATE_INFOPLIST_FILE=YES` avoids a stale hand-maintained `Info.plist`. Get the target too high and you lose users; enable the wrong concurrency mode and you inherit a pile of Sendable warnings that mask real ones.

**What to do:**
1. In Xcode 26, `File → New → Project → iOS → App`. Product Name **`SplitFair`**, Interface **SwiftUI**, Language **Swift**, Storage **None** (no Core Data/SwiftData — see the architecture skill's explicit rejection of SwiftData), no tests checkbox needed yet (the UI test target comes later; the math tests live in the package). Uncheck "Host in CloudKit"/any iCloud option.
2. Create it at the repo root so the tree is `SplitFair/SplitFair.xcodeproj` and `SplitFair/SplitFair/` (app sources) alongside the existing `SplitFair.md` and `.claude/`.
3. Set **Minimum Deployments → iOS 17.0** on the app target. Keep the project building against the **newest SDK** (iOS 26) — Liquid Glass comes from the SDK you compile against, not the floor.
4. In Build Settings: **Swift Language Version = Swift 6**; enable **Approachable Concurrency** and set **Default Actor Isolation = MainActor** (Swift 6.2). Confirm **Generate Info.plist File = Yes** (`GENERATE_INFOPLIST_FILE`).
5. Delete any Xcode-generated `AppDelegate`/`SceneDelegate`/`@UIApplicationDelegateAdaptor` scaffolding — the SwiftUI App lifecycle (`@main App` + `WindowGroup`) is the only lifecycle used.
6. Commit the generated project.

**Technical details & suggestions:**
- Architecture decisions to honor from `splitfair-app-architecture`: **100% SwiftUI**, `@main App` + `WindowGroup` + `NavigationStack`, **zero third-party dependencies**, `@Observable` (Observation framework) — **never** `ObservableObject`/`@Published`/Combine.
- Approachable Concurrency with default actor = `@MainActor` is what lets the swift-conventions rule "you will essentially never hand-write `Sendable`/`@Sendable`/actors" hold. If you see Sendable warnings on your value-type models later, the setting is wrong — fix it here rather than annotating away.
- Xcode 26 is required for the iOS 26 SDK / Liquid Glass, but the deployment floor stays at **17.0** (18 acceptable). Do not let the New Project dialog silently set the floor to 26.
- Bundle identifier: pick a stable reverse-DNS id (e.g. `com.<you>.SplitFair`) now; it appears in the privacy label and store config in EPIC 09.
- Do **not** add an `.entitlements` file — there is no network/iCloud/push. The project-structure skill states this explicitly.

**Done when:** `SplitFair.xcodeproj` exists at the repo root; the app target's minimum deployment is iOS 17.0, Swift language version is 6, Approachable Concurrency is on with default actor MainActor, `GENERATE_INFOPLIST_FILE=YES`; there is no AppDelegate/SceneDelegate; the default template app builds and runs in the simulator.

---

### Task 1.2 — Create and link the BillCore local Swift package

**Skills to load:** `splitfair-project-structure`, `splitfair-swift-conventions`

**Why this matters:** `BillCore` is the "compile firewall." Because the package declares **no SwiftUI/UIKit dependency**, a stray `import SwiftUI` in the math — or a UI type leaking into the domain — becomes a *build error*, not a code-review comment. It also makes the entire math suite runnable via `swift test` in milliseconds with **no simulator**, which is what keeps EPIC 02's TDD loop fast. Naming it `BillCore` (not `SplitFair`) means a future brand rename never churns the core.

**What to do:**
1. Create the folder `Packages/BillCore/` at the repo root. Inside, create `Package.swift` with **swift-tools 6.0**, one **library** target `BillCore` and one **Swift Testing** test target `BillCoreTests`. Do **not** add any product/target dependency on SwiftUI/UIKit or any third-party package.
2. Create the source directory `Packages/BillCore/Sources/BillCore/` and the test directory `Packages/BillCore/Tests/BillCoreTests/`. Add a single placeholder source file so the target compiles (EPIC 02 replaces it with `Money.swift`, `Currency.swift`, `Allocate.swift`, `MoneyEdge.swift`, `Model.swift`, `BillMath.swift`, `Summary.swift`).
3. From the terminal, run `swift test` inside `Packages/BillCore/` to confirm the package resolves, builds, and the (empty) Swift Testing target runs green.
4. In Xcode: `File → Add Package Dependencies… → Add Local…`, select `Packages/BillCore`. Link the **`BillCore` library** into the **SplitFair app target** (General → Frameworks, Libraries, and Embedded Content).
5. Verify the app can `import BillCore` and still builds.

**Technical details & suggestions:**
- `Package.swift` sketch (Foundation-only, Swift Testing target):
  ```swift
  // swift-tools-version: 6.0
  import PackageDescription

  let package = Package(
      name: "BillCore",
      platforms: [.iOS(.v17)],
      products: [
          .library(name: "BillCore", targets: ["BillCore"]),
      ],
      targets: [
          .target(name: "BillCore"),                                   // imports Foundation ONLY
          .testTarget(name: "BillCoreTests", dependencies: ["BillCore"]) // Swift Testing (import Testing)
      ]
  )
  ```
- Placeholder source (`Sources/BillCore/BillCore.swift`) — keep it minimal and pure:
  ```swift
  import Foundation
  // Domain lands in EPIC 02: Money, Currency, allocate(), MoneyEdge, Model, BillMath, Summary.
  ```
- Placeholder test (`Tests/BillCoreTests/PackageSmokeTests.swift`) proving `swift test` and the framework work:
  ```swift
  import Testing
  @testable import BillCore

  @Test("package builds and the test runner is wired")
  func packageBuilds() { #expect(Bool(true)) }
  ```
  Use `import Testing` / `@Test` / `#expect` — **Swift Testing**, not XCTest. XCTest is reserved for the 1–2 UI smokes in EPIC 09.
- **Pitfall:** do not add `.iOS`-only or UI frameworks to the target dependencies; the whole point is that `swift test` runs headless on the command line. If you ever need UIKit here, you're writing the code in the wrong place.
- **Pitfall:** keep `swift-tools-version` at 6.0 exactly as the structure skill specifies; the app target's language mode (6) and the package's tools version are independent knobs — both must be set.
- Money-representation rules to carry into EPIC 02 (record them, don't implement yet): **all money is `Int` minor units** (`typealias Cents = Int` / a thin `Money`), a `Double`/`Float` **never** touches money, `Decimal` + `FormatStyle` appear only at the edges.

**Done when:** `Packages/BillCore/Package.swift` declares swift-tools 6.0 with one library + one Swift Testing target and no UI dependency; `swift test` run from `Packages/BillCore/` succeeds; the package is added to the project as a local package and the `BillCore` library is linked into the app target; the app builds with `import BillCore` present.

---

### Task 1.3 — Establish the app folder structure

**Skills to load:** `splitfair-project-structure`

**Why this matters:** Organizing **by feature** (not by type) keeps each screen's views, rows, and controls physically together, so later epics touch one folder instead of hunting across `Views/`/`Models/` mega-folders. Using **file-system-synchronized groups** means folders *are* groups — no `.pbxproj` churn on every new file, which removes the usual reason teams reach for XcodeGen/Tuist (unnecessary here). The empty scaffold now is the contract every later epic files into.

**What to do:**
1. Under the app sources folder `SplitFair/SplitFair/`, create these folders as **file-system-synchronized groups**:
   - `App/` — `SplitFairApp.swift` (Task 1.6), and later `BillStore.swift` (EPIC 03).
   - `Features/Bill/` — later `BillScreen`, `DinerBar`, `ItemRow`, `PersonChip`, `AddItemRow` (EPICs 05–06).
   - `Features/Totals/` — later `TotalsScreen`, `TaxTipControls`, `PersonTotalCard`, `ReconciliationBar` (EPICs 05–07).
   - `DesignSystem/` — later `Theme`, `Color+Tokens`, `Font+Tokens`, `Modifiers`, `Shapes`, `DinerPalette` (EPIC 04).
   - `Persistence/` — later `BillDraftStore.swift` (EPIC 03).
   - `Sharing/` — later `ShareSummary.swift` (EPIC 07).
2. Ensure `Assets.xcassets` and (Task 1.5) `PrivacyInfo.xcprivacy` live at the app-sources root.
3. Add a small placeholder in folders that would otherwise be empty (e.g. a `.gitkeep` or the actual first file) so the structure survives in git and Xcode shows the groups.
4. Confirm Xcode shows these as synchronized groups (blue folder-synced icon), not manually-managed groups.

**Technical details & suggestions:**
- Target tree (from `splitfair-project-structure`):
  ```
  SplitFair/SplitFair/
  ├─ App/            SplitFairApp.swift · (BillStore.swift later)
  ├─ Features/
  │  ├─ Bill/        BillScreen · DinerBar · ItemRow · PersonChip · AddItemRow
  │  └─ Totals/      TotalsScreen · TaxTipControls · PersonTotalCard · ReconciliationBar
  ├─ DesignSystem/   Theme · Color+Tokens · Font+Tokens · Modifiers · Shapes · DinerPalette
  ├─ Persistence/    BillDraftStore.swift
  ├─ Sharing/        ShareSummary.swift
  ├─ Assets.xcassets
  └─ PrivacyInfo.xcprivacy
  ```
  A separate `SplitFairUITests/` target (with `SmokeTests.swift`) is added in EPIC 09, not now.
- Naming conventions from the structure + swift-conventions skills: **one file per primary type**; view files named for the view (`ItemRow.swift`); types `UpperCamelCase`, properties/functions `lowerCamelCase`; no `Views/`/`Models/` type-buckets.
- **Why by-feature:** both screens read the same single `BillStore`, so the natural seam is the screen/feature, not the layer. Type-buckets would scatter a screen across four folders.
- **Pitfall:** don't pre-create files you can't yet compile — empty folders (with `.gitkeep`) are fine; half-written types that don't build are not. The goal is a green build with the structure in place.

**Done when:** `App/`, `Features/Bill/`, `Features/Totals/`, `DesignSystem/`, `Persistence/`, `Sharing/` exist under `SplitFair/SplitFair/` as file-system-synchronized groups, are committed to git, and the app still builds.

---

### Task 1.4 — Set up formatting, linting and CI

**Skills to load:** `splitfair-testing`, `splitfair-swift-conventions`

**Why this matters:** SwiftFormat + SwiftLint keep the codebase in one house style automatically, so review focuses on the math and the design, not on brace placement. The **pre-commit hook** stops unformatted/lint-failing code from ever landing; `swiftlint --strict` in CI makes warnings fail the build so they can't accumulate. Wiring the CI `swift test` job now means the moment EPIC 02 adds the allocate invariants and the $97.20 acceptance bill, they are already gating every push.

**What to do:**
1. Add a `.swiftformat` config and a `.swiftlint.yml` config at the repo root. Scope them to the app sources and the package sources.
2. Install a **pre-commit hook** that runs SwiftFormat (write mode) and `swiftlint` on staged Swift files and blocks the commit on failure. Provide a `scripts/install-hooks.sh` (or a `Makefile`/`.git/hooks/pre-commit`) so contributors wire it with one command; document the two Homebrew installs (`brew install swiftformat swiftlint`).
3. Create a CI workflow (`.github/workflows/ci.yml`) with two gates:
   - **Lint:** `swiftlint --strict` (warnings fail).
   - **Test:** `swift test` executed inside `Packages/BillCore/` (headless, no simulator).
4. Run both locally to confirm they pass on the current skeleton.

**Technical details & suggestions:**
- `.swiftlint.yml` sketch:
  ```yaml
  included:
    - SplitFair/SplitFair
    - Packages/BillCore/Sources
  excluded:
    - Packages/BillCore/.build
    - DerivedData
  opt_in_rules:
    - empty_count
    - force_unwrapping
  ```
  Keep it aligned with the swift-conventions rules (value types, no force-unwrapping in domain code, clear naming). Booleans read as assertions (`isReconciled`, `hasUnassignedItems`); intent methods read as commands (`addPerson`, `setTip`, `clear`).
- `.swiftformat` sketch: pin `--swiftversion 6.0`, standard indent/wrap rules; let it own whitespace so the hook is deterministic.
- Pre-commit hook sketch (`.git/hooks/pre-commit`, installed by the script):
  ```sh
  #!/bin/sh
  swiftformat . --lint || { echo "swiftformat failed"; exit 1; }
  swiftlint --strict || exit 1
  ```
- CI `swift test` step must `cd Packages/BillCore` (or `swift test --package-path Packages/BillCore`) — the tests live in the package, not the app target, and the testing skill's whole premise is that they run in **milliseconds with no simulator**.
- **Tripwire from the testing skill (record for EPIC 02):** assert `sum(result) == amount` inside `allocate` as a runtime tripwire that compiles out in release. Not implemented now, but the CI that guards it is being built here.
- **Pitfall:** don't let CI try to boot a simulator for the math suite — that's slow and defeats the firewall. Simulator-based UI smokes + `performAccessibilityAudit` arrive in EPIC 09.
- **Pitfall:** ensure `.build/` and `DerivedData/` are excluded from both linters (they're already git-ignored) so tooling doesn't scan generated code.

**Done when:** `.swiftformat` and `.swiftlint.yml` exist at the repo root; a pre-commit hook (plus install script) runs SwiftFormat + SwiftLint and blocks failing commits; a CI workflow runs `swiftlint --strict` and `swift test` on `Packages/BillCore`; both gates pass green on the current skeleton.

---

### Task 1.5 — Add the privacy manifest and compliance build settings

**Skills to load:** `splitfair-ios-platform`, `splitfair-persistence`

**Why this matters:** SplitFair's promise is **offline & private — no network, no analytics, no accounts, no data beyond the current bill**. The privacy manifest and build settings are how that promise is declared to Apple so the App Store label reads **"Data Not Collected."** Getting the `PrivacyInfo.xcprivacy` wrong (declaring tracking, or omitting the required-reason API) or forgetting `ITSAppUsesNonExemptEncryption` triggers App Review rejections and export-compliance prompts on every upload. Doing it now means EPIC 09 only has to *verify* the manifest against actual behavior, not author it.

**What to do:**
1. Add **`PrivacyInfo.xcprivacy`** at the app-sources root (`SplitFair/SplitFair/PrivacyInfo.xcprivacy`) and include it in the app target's Copy Bundle Resources.
2. Set its keys: `NSPrivacyTracking = false`, **empty** `NSPrivacyCollectedDataTypes`, **empty** `NSPrivacyTrackingDomains`. Add the required-reason API entry for **UserDefaults with reason code `CA92.1`** (declare it now since the app may read/write UserDefaults; keeping it present is harmless and pre-empts a rejection).
3. Set **`ITSAppUsesNonExemptEncryption = NO`** (via `GENERATE_INFOPLIST_FILE` Info.plist key entry: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`, or the Info.plist key) so uploads skip the export-compliance question.
4. Confirm there is **no** `AppTrackingTransparency` usage anywhere, **no** `NSUserTrackingUsageDescription`, and **no** `.entitlements` file.
5. Confirm there is **no** network code anywhere in the project (this is a standing invariant, verified again in EPIC 09).

**Technical details & suggestions:**
- `PrivacyInfo.xcprivacy` (property list) shape:
  ```xml
  <dict>
    <key>NSPrivacyTracking</key><false/>
    <key>NSPrivacyTrackingDomains</key><array/>
    <key>NSPrivacyCollectedDataTypes</key><array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
      <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array><string>CA92.1</string></array>
      </dict>
    </array>
  </dict>
  ```
- Persistence posture that this configuration backs (from `splitfair-persistence`): exactly **one** `Codable Bill` to a **single JSON file in Application Support** (not Documents — Documents is user-visible + iCloud-exposed), atomic writes, default file protection. That's added in EPIC 03; the privacy config asserting "nothing collected, nothing tracked" must be consistent with it.
- The `CA92.1` UserDefaults reason is the standard "access info from the app itself / app group" reason. Declaring it even if UserDefaults use is minimal avoids the "missing required reason" upload warning.
- **Pitfall:** do not add any `NSPrivacyCollectedDataTypes` entries "just in case" — the label must read Data Not Collected, and any entry breaks that.
- **Pitfall:** don't create an `.entitlements` file. No push, no iCloud, no network, no background modes means no entitlements — the architecture and structure skills both call this out.

**Done when:** `PrivacyInfo.xcprivacy` is in the app target with `NSPrivacyTracking = false`, empty collected-data and tracking-domains arrays, and the UserDefaults `CA92.1` reason; `ITSAppUsesNonExemptEncryption = NO` is set; there is no ATT usage, no `NSUserTrackingUsageDescription`, and no `.entitlements` file; the app still builds and archives without an export-compliance prompt.

---

### Task 1.6 — Wire a placeholder App entry and confirm it runs

**Skills to load:** `splitfair-app-architecture`

**Why this matters:** This is the proof-of-life for the whole scaffold: it demonstrates the SwiftUI App lifecycle, the `WindowGroup` + `NavigationStack` shell, and a launchable placeholder, without pulling in any real state or design yet. Establishing the exact ownership/injection shape now — one store constructed at the root, read via `@Environment` downstream — means EPIC 03 swaps a placeholder for the real `BillStore` with a one-line change instead of a refactor.

**What to do:**
1. Create `SplitFair/SplitFair/App/SplitFairApp.swift` with `@main struct SplitFairApp: App`, a `WindowGroup`, a `NavigationStack`, and a placeholder root view (e.g. a `BillScreen` stub or a simple `Text("SplitFair")`).
2. Include the `scenePhase` observation hook shape now (even as a no-op comment) so the persistence flush in EPIC 03 slots in without restructuring the App.
3. Build and **run in the simulator**; confirm the app launches to the placeholder screen with no console errors and no Sendable/concurrency warnings.

**Technical details & suggestions:**
- App entry sketch (mirrors the ownership/injection pattern from `splitfair-app-architecture`; the `@State private var store = BillStore()` line is commented until EPIC 03 provides `BillStore`):
  ```swift
  import SwiftUI

  @main
  struct SplitFairApp: App {
      // EPIC 03: @State private var store = BillStore()   // constructed ONCE at the root
      @Environment(\.scenePhase) private var phase

      var body: some Scene {
          WindowGroup {
              NavigationStack {
                  RootPlaceholderView()
              }
              // EPIC 03: .environment(store)
          }
          // EPIC 03: .onChange(of: phase) { _, new in if new != .active { Task { await store.flush() } } }
      }
  }

  private struct RootPlaceholderView: View {
      var body: some View {
          VStack {
              Text("SplitFair")
                  .font(.largeTitle.bold())
              Text("Foundation ready")
                  .foregroundStyle(.secondary)
          }
          .navigationTitle("The Bill")
      }
  }
  ```
- Honor the architecture decisions: **no AppDelegate/SceneDelegate**, **no `UIViewRepresentable`**, **no `NavigationPath`/route enums** — one plain `NavigationLink` to Screen 2 is all that's ever needed (added in EPIC 06). Downstream views will read state with `@Environment(BillStore.self) private var store` and use `@Bindable` only where a `TextField` needs a two-way binding.
- **Pitfall:** don't introduce a ViewModel for the placeholder — the app has exactly one state object (`BillStore`, later), and both screens read it. Adding a ViewModel here would fracture the single source of truth the architecture skill is built around.
- Keep the placeholder visually plain — the design system (loud-frame/calm-center, ink-on-paper numbers, hard offset shadows, the one glass rail) is EPIC 04. This screen exists only to prove the skeleton launches.

**Done when:** `SplitFair/SplitFair/App/SplitFairApp.swift` defines the `@main` App with `WindowGroup` + `NavigationStack` + a placeholder root view and no AppDelegate/SceneDelegate; the app builds and launches in the iOS 17+ simulator to the placeholder screen with no warnings; the `scenePhase` hook shape is present (no-op) ready for EPIC 03.
