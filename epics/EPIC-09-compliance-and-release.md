# EPIC 09 — Privacy, Compliance & Release Prep

> Verify the privacy promise, lock in CI gates, run full regression against the acceptance bill, and prepare the App Store submission.

## What this epic is for
The app is feature-complete, accessible, and animated — but "shippable" is a different bar than "done building." This epic proves the app's central promises are true rather than merely intended: that it collects **no data** (verified against actual runtime behavior, not aspiration), that quality can't silently regress (CI gates on `swift test`, UI smokes carrying `performAccessibilityAudit`, and `swiftlint --strict`), that the money still reconciles to the exact cent (the $97.20 anchor re-driven end-to-end on a device), and that the App Store submission is assembled and honest ("Data Not Collected"). When this epic is green, the build is submission-ready.

## Where we are before starting (starting state)
- Both screens are functionally complete, styled in HARD COPY (Warm Receipt Brutalism), with signature motion + haptics wired (`.sensoryFeedback`) and a full accessibility pass done (≥3 non-color signals per state, Dynamic Type reflow, VoiceOver labels, Reduce Motion / Reduce Transparency fallbacks).
- `BillCore` is a pure Foundation-only local package with a Swift Testing suite (allocate invariants + the $97.20 acceptance bill) that runs green via `swift test`.
- Persistence writes exactly one `current-bill.json` to Application Support (debounced + scenePhase flush), restores on launch, and `Clear` wipes it.
- `PrivacyInfo.xcprivacy` exists from EPIC 01 and build settings were set (no ATT, no entitlements, encryption flag), but none of it has been *verified against actual behavior* or wired into a merge gate; there are no store assets.

## What we will have after finishing (definition of done)
- A privacy manifest and posture **verified against real behavior**: proven-zero network calls / analytics / third-party SDKs, `NSPrivacyTracking = false`, empty collected-data and tracking-domain arrays, `UserDefaults` reason `CA92.1` only if UserDefaults is actually used, and an App Privacy nutrition label that can honestly read **Data Not Collected**.
- **CI gates merges**: `swift test` (BillCore), 1–2 XCUITest happy-path smokes whose real payload is `app.performAccessibilityAudit(...)`, and `swiftlint --strict` all run on every PR; any failure blocks merge.
- The **full invariant + acceptance suite** re-run green, and the **$97.20 acceptance bill manually driven on-device** (assign → tip changes → round-up → clear) with the reconciliation **SETTLED ✓** appearing every time.
- **App Store metadata/config prepared**: `ITSAppUsesNonExemptEncryption = NO`, no ATT, screenshots that lead with who-ordered-what + no-account + offline positioning, subtitle + keywords drafted, with the pending brand rename noted (the package stays `BillCore`).
- A **release checklist / definition of done** satisfied, tying back to the four non-negotiables (exact-cent reconciliation, offline/no-account, the two-screen flow, bold-but-legible), all green.

## Dependencies
- Depends on: EPIC 08 — Motion, Haptics & Accessibility (a feature-complete, accessible app with motion and haptics).
- Enables: App Store submission (this is EPIC 09 of 9 — the final epic; its output is the submitted build).

---

## Tasks

### Task 9.1 — Verify the privacy manifest against real behavior
**Skills to load:** `splitfair-persistence`, `splitfair-ios-platform`

**Why this matters:** "Data Not Collected" is a legal attestation on the App Store, not marketing copy. If the manifest claims no tracking while a stray SDK, an analytics import, or a `URLSession` call ships in the binary, the app is submitted under a false privacy label — a rejection risk and a trust breach that directly contradicts non-negotiable #3 (offline & private). The whole point of persisting *only* the current bill to one on-device file is that there is nothing to collect; this task proves that end-to-end so the nutrition label is honest.

**What to do:**
1. **Prove zero network at the source level.** Grep the entire app target and the `BillCore` package for any networking or analytics surface: `URLSession`, `URLRequest`, `URLConnection`, `Network.framework`, `NWConnection`, `dataTask`, `fetch`, `WebSocket`, `CFNetwork`, `Firebase`, `Analytics`, `Crashlytics`, `AppsFlyer`, `Amplitude`, `Sentry`, `os_log`-to-server, and any `http://` / `https://` string literal. Expect **zero** hits in product code. Confirm `BillCore/Package.swift` declares no dependencies and `Sources/BillCore/` imports only Foundation (the missing-import compile firewall from `splitfair-project-structure`).
2. **Prove zero third-party SDKs.** Confirm the Xcode project has no Swift Package / CocoaPods / Carthage dependencies beyond the local `BillCore`. There is no `.entitlements` file (no network client, no iCloud, no push) — verify none was added.
3. **Prove zero network at runtime.** Launch on a device/simulator, exercise both screens (add people, assign items, change tip, round-up, Copy/Share, Clear), and watch a network monitor (Xcode's Network instrument, or Console filtered on the process). There must be **no outbound connections**. The only platform touchpoints are `.sensoryFeedback` haptics, `ShareLink`/`UIPasteboard.general.string` for Copy summary, and the local JSON file write — none of which leave the device.
4. **Audit the persistence footprint.** Confirm the only thing written is `current-bill.json` in **Application Support** (not Documents — Documents is user-visible + iCloud-exposed), written `.atomic` with **default file protection** (not `.completeFileProtection`, which would make a save firing exactly at screen-lock fail). Confirm `clear()` removes the file. No history, no arrays of bills, no SwiftData, no sync — "no data beyond the current bill" is the feature.
5. **Reconcile the manifest fields with actual API usage.** Open `SplitFair/PrivacyInfo.xcprivacy` and verify: `NSPrivacyTracking = false`, `NSPrivacyTrackingDomains` empty, `NSPrivacyCollectedDataTypes` empty. For `NSPrivacyAccessedAPITypes`: include the `UserDefaults` reason `CA92.1` **only if the app actually reads/writes UserDefaults** — if it does not (persistence uses a JSON file, not UserDefaults), the array should be empty rather than declaring an unused reason. Add any other required-reason API entries only for APIs actually called (e.g. file-timestamp APIs) — do not pad the manifest.
6. **Map behavior to the nutrition label.** Write down the App Privacy answers you will enter in App Store Connect: every data-type question answered "not collected," "Data Used to Track You" = none. This becomes the source for Task 9.4.

**Technical details & suggestions:**
- Source scan, run from repo root:
  ```bash
  grep -rEn "URLSession|URLRequest|dataTask|NWConnection|https?://|Firebase|Crashlytics|Analytics|Amplitude|Sentry|AppsFlyer" \
    SplitFair Packages/BillCore/Sources | grep -v "PrivacyInfo.xcprivacy"
  ```
  A clean run prints nothing. Any hit must be explained or removed before proceeding.
- `PrivacyInfo.xcprivacy` is a plist; the key shape to verify:
  ```xml
  <key>NSPrivacyTracking</key><false/>
  <key>NSPrivacyTrackingDomains</key><array/>
  <key>NSPrivacyCollectedDataTypes</key><array/>
  <key>NSPrivacyAccessedAPITypes</key><array/>   <!-- add CA92.1 UserDefaults entry ONLY if UserDefaults is used -->
  ```
- Runtime check: in Xcode, Product → Profile → Network, or `log stream --predicate 'process == "SplitFair"'` while driving the app.
- Pitfall: `ShareLink`/`UIPasteboard` do **not** count as data collection or transmission — the OS share sheet is user-initiated egress, not app telemetry. Note this so a reviewer of the review doesn't over-report it.
- Pitfall: don't declare `CA92.1` "just in case." An unused required-reason declaration is not itself a rejection, but the goal here is a manifest that *matches reality exactly*, so it can be defended.

**Done when:** The source grep is clean, no third-party SDKs or `.entitlements` exist, a runtime session shows zero outbound connections, the only on-disk artifact is `current-bill.json` in Application Support, and `PrivacyInfo.xcprivacy` fields match actual API usage — so the App Privacy label can be entered as **Data Not Collected** with a written behavior-to-label mapping backing every answer.

---

### Task 9.2 — Gate quality in CI
**Skills to load:** `splitfair-testing`, `splitfair-accessibility`

**Why this matters:** The math is the product (non-negotiable #1), and the bold look must never cost legibility (non-negotiable #4). Both are exactly the properties that erode invisibly over time — a refactor breaks a rounding tie-break, a restyle drops contrast below 4.5:1 — unless a machine refuses the merge. This task turns the test suite and the accessibility audit from "things you can run" into "things that must pass before code lands," so the guarantees survive future changes.

**What to do:**
1. **Add a CI workflow** (`.github/workflows/ci.yml` if GitHub Actions) on a `macos` runner, triggered on pull requests and pushes to the default branch, with three required jobs/steps.
2. **Gate on `swift test`.** Run the pure `BillCore` suite: `swift test --package-path Packages/BillCore`. This is the fast gate — the whole suite runs in milliseconds with no simulator (Foundation-only package, `import Testing`). It covers the allocate invariants (fuzzed conservation, residual < n, ascending-index tie-break, zero-weight fallback, negative mirror, the pathological set) and the $97.20 acceptance bill including the closing invariant `Σ perPerson.total == grandTotal`.
3. **Gate on the UI smokes carrying the accessibility audit.** Run the 1–2 XCUITest happy-path smokes on a simulator via `xcodebuild test`. Their real payload is `app.performAccessibilityAudit(...)`, not assertions about pixels — pixel-snapshot tests are deliberately skipped (poor ROI for 2 screens, brittle). The audit enforces the accessibility contract: 44×44pt targets, Dynamic Type, contrast, VoiceOver labels.
4. **Gate on `swiftlint --strict`.** Run the linter in strict mode so warnings become errors. SwiftFormat + SwiftLint already run in a pre-commit hook locally; CI is the backstop for anyone who bypasses the hook.
5. **Make all three blocking.** Configure branch protection so the workflow is a required status check — a red job blocks merge. No "allowed to fail" steps.

**Technical details & suggestions:**
- Workflow sketch:
  ```yaml
  name: CI
  on: { pull_request: {}, push: { branches: [main] } }
  jobs:
    quality:
      runs-on: macos-14
      steps:
        - uses: actions/checkout@v4
        - name: BillCore unit tests
          run: swift test --package-path Packages/BillCore
        - name: Lint (strict)
          run: swiftlint --strict
        - name: UI smoke + accessibility audit
          run: |
            xcodebuild test \
              -project SplitFair.xcodeproj \
              -scheme SplitFair \
              -destination 'platform=iOS Simulator,name=iPhone 15' \
              -only-testing:SplitFairUITests/SmokeTests
  ```
- The smoke test carrying the audit lives in `SplitFairUITests/SmokeTests.swift`:
  ```swift
  func testBillFlowIsAccessible() throws {
      let app = XCUIApplication(); app.launch()
      // drive: add a person, add an item, assign, tap Next, set tip
      try app.performAccessibilityAudit()   // real payload — fails CI on contrast/label/target regressions
  }
  ```
- Keep the fast gate (`swift test`) first so most regressions fail in seconds before the slow simulator boot.
- Pitfall: `performAccessibilityAudit()` throws — the test must be `throws` and not swallow it. Optionally scope with an options set, but don't silence categories just to make it pass; a real contrast failure means a real money-legibility bug.
- Pitfall: pin the SwiftLint version (the pre-commit hook and CI must agree) so a linter upgrade doesn't split local vs CI results.

**Done when:** A pull request cannot merge unless all three checks are green: `swift test` (BillCore) passes, the XCUITest smoke passes its `performAccessibilityAudit()`, and `swiftlint --strict` reports zero violations — verified by opening a PR that deliberately breaks each one and confirming the merge is blocked.

---

### Task 9.3 — Run full end-to-end regression
**Skills to load:** `splitfair-testing`, `splitfair-money-math`

**Why this matters:** Green unit tests prove the math primitive is correct in isolation; they do not prove the *assembled app* still reconciles when a human taps through it — that assignment, tip changes, round-up, and clear all funnel into the same `allocate()`-closed passes. Non-negotiable #1 is that per-person totals sum to the grand total **to the exact cent**, and the $97.20 anchor is the canonical proof. Driving it by hand on-device catches integration gaps (a stale computed total, a tip change that doesn't re-reconcile, a round-up that lies about the surplus) that no unit test sees.

**What to do:**
1. **Re-run the full automated suite** with `swift test --package-path Packages/BillCore` and confirm every case is green: fuzzed conservation (parts always sum to input), residual < n, the ascending-index tie-break, zero-weight equal-split fallback, the negative mirror (discounts), the pathological set (1¢/3-ways, single odd-cent item, everyone comped, 100% discount, large party), the single percent→cents rounding site, the persistence round-trip / corrupt-file→`.empty` / `clear()`, and the $97.20 acceptance bill with its closing invariant.
2. **Build the acceptance bill on-device** (or on a clean simulator) exactly as the anchor specifies. Three people (Ana, Ben, Cy). Items: 1250 → Ana, 2800 → Ben, 900 → Ben, 1600 → Cy, and nachos 1000 **shared across all three**. Tax **660** (entered as the printed amount, not recomputed from a %). Tip **20%** of the pre-tax subtotal → **1510**.
3. **Verify per-person and grand totals on screen.** The three cards must read Ana **$20.39** (2039), Ben **$51.93** (5193), Cy **$24.88** (2488), grand total **$97.20** (9720). The reconciliation banner must show **SETTLED ✓** ("adds up").
4. **Drive tip changes and confirm live re-reconciliation.** Switch tip presets and toggle the pre-tax / post-tax base. Each change must re-fire reconciliation and the per-person cards must still sum to the (new) grand total to the exact cent — the banner returns to SETTLED ✓ every time, never leaving a stale total.
5. **Exercise round-up.** Enable the display-only round-up and confirm the surplus shown is *honest* — the underlying reconciled integer-cent math is unchanged; round-up is a display convenience, not a new rounding site. The parts must still sum to the true grand total.
6. **Exercise clear.** Tap Clear (the single confirm dialog in the app), confirm, and verify the bill returns to empty, the file is removed, and relaunch restores an empty bill.

**Technical details & suggestions:**
- The math contract you're validating (from `splitfair-money-math`): every division of money routes through the one `allocate(amountCents:weights:)` largest-remainder primitive across the three passes — item subtotals (each shared item `allocate(itemCents, [1]*k)` in roster order), tax `allocate(taxCents, S)`, tip `allocate(tipCents, S)` — so `finalᵢ = S[i] + tax[i] + tip[i]` and the finals sum to the grand total structurally.
- Verified allocate vectors to sanity-check by eye if a number looks off: `allocate(660,[1584,4033,1933]) == [138,353,169]` (tax) and `allocate(1510,[1584,4033,1933]) == [317,807,386]` (tip). The per-person subtotals `S` are 1584 / 4033 / 1933 (Ana = 1250 + 334 nachos; Ben = 2800 + 900 + 333; Cy = 1600 + 333).
- Round-tabular check: money renders with `.monospacedDigit()` so live totals never jitter or reflow mid-animation — watch that columns stay aligned as the odometer animates the exact reconciled value.
- Trap to watch for while driving tip: percent→cents is a **second** rounding site. Confirm the tip is rounded to `Int` once (`tipCents = Int((assignedSubtotal * pct).rounded())` → 1510) before `allocate()`, not summed from independently-rounded per-person tips. If the grand total lands on 9719 or 9721, this is the bug.
- Do this pass on a real device once for haptics/share/keyboard reality, plus a clean-install simulator run to confirm first-launch (empty bill) and restore behavior.

**Done when:** `swift test` is fully green, and a manual on-device run of the acceptance bill shows Ana $20.39 / Ben $51.93 / Cy $24.88 / grand $97.20 with **SETTLED ✓**, the totals re-reconcile exactly on every tip-preset and base-toggle change, round-up shows an honest surplus without changing the true grand total, and Clear empties the bill (file removed, empty on relaunch).

---

### Task 9.4 — Prepare App Store metadata and assets
**Skills to load:** `splitfair-ios-platform`, `splitfair-design-system`

**Why this matters:** The submission config is where the privacy promise and the product positioning become the store listing users actually see. Getting the encryption/ATT flags wrong causes a rejection or an export-compliance stall; a listing that leads with the wrong thing buries what makes SplitFair different (it splits by *who ordered what*, offline, with no account). The screenshots must also honestly represent the HARD COPY look — bold and colorful, but with every number ink-on-cream and legible — so the store page matches the app.

**What to do:**
1. **Set export-compliance config.** `ITSAppUsesNonExemptEncryption = NO` (the app uses no non-exempt encryption). Confirm this is set so App Store Connect doesn't prompt for encryption docs on every upload. The Info.plist is auto-generated (`GENERATE_INFOPLIST_FILE = YES`); add the key via build settings / Info.plist config, not a hand-edited plist.
2. **Confirm no ATT.** No AppTrackingTransparency framework, no `NSUserTrackingUsageDescription` string, no tracking prompt. This matches the Task 9.1 finding and the "Data Not Collected" label.
3. **Enter the App Privacy nutrition label** using the behavior-to-label mapping from Task 9.1: every data type "not collected," no tracking → the label reads **Data Not Collected**.
4. **Capture screenshots** on the required device sizes. Lead the sequence with the differentiators: (1) Screen 1 with color-coded diner chips assigned to items — the "who ordered what" story; (2) the split item showing the split-ring so it's clear splits are evenly divided; (3) Screen 2 with per-person total cards and the **SETTLED ✓** reconciliation stamp; and captions/overlays that state **no account** and **works offline**. The screenshots must show real reconciled numbers (e.g. the $97.20 bill), ink-on-cream and legible — never a dollar amount sitting on a gradient, chip, or glass.
5. **Draft subtitle + keywords.** Subtitle should compress the positioning: split by who ordered what, offline, no account (e.g. "Split by who ordered — offline"). Keywords should include: split bill, who ordered, restaurant, tip, tax, offline, no account, receipt, group, dinner. Draft the description leading with the same three pillars, and note the app has no ads and stores nothing beyond the current bill.
6. **Note the pending brand rename.** The core package is intentionally named `BillCore`, not `SplitFair`, so a future brand rename never churns the domain code (`splitfair-project-structure`). Record that the display name / bundle marketing name may change before final submission, and that only the app target's display name + store listing are affected — `BillCore` and its tests stay put.

**Technical details & suggestions:**
- Encryption flag in the auto-generated Info.plist via build setting or `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`.
- Screenshot fidelity to HARD COPY (from `splitfair-design-system`): loud frame / calm center — saturated color only on people, chrome (CTA/footer), and the celebration stamp; every surface holding a number stays opaque and near-neutral; the single bottom rail is the one glass element, and even there the live number rides an opaque cream pill. Reserve green for the reconciliation stamp, amber for unassigned, red only for Clear — don't stage a screenshot that misuses those.
- Capture screenshots on a device set to a mid Dynamic Type size to show the design holds; optionally include one at a large accessibility size to demonstrate reflow (prices wrap to a second line, never truncate) — this reinforces the legibility promise.
- Pitfall: do not enable ATT "to be safe." Adding the framework or the usage string forces a tracking prompt and contradicts the Data-Not-Collected label.
- Pitfall: keep the store screenshots showing genuinely reconciled bills (parts summing to the shown grand total). A doctored total on the store page undercuts the entire trust proposition.

**Done when:** `ITSAppUsesNonExemptEncryption = NO` is set and confirmed on an upload, no ATT surface exists, the App Privacy label is entered as **Data Not Collected**, a screenshot set leads with who-ordered-what + no-account + offline (numbers legible and ink-on-cream), subtitle/keywords/description are drafted around those pillars, and the pending brand-rename note is recorded with `BillCore` confirmed to stay unchanged.

---

### Task 9.5 — Satisfy the release checklist / definition of done
**Skills to load:** `splitfair-overview`, `splitfair-testing`

**Why this matters:** The four non-negotiables are the spine of the whole product; a final, explicit checklist is what turns "I think it's done" into "it demonstrably meets the bar." This is the last gate before submission — it ties every prior epic's output back to the promises in `splitfair-overview` and refuses to ship if any one is not provably true. Skipping it risks submitting a build that's 95% there but violates the one guarantee (exact-cent reconciliation) that the product exists to make.

**What to do:**
1. **Verify non-negotiable #1 — correctness over features.** `swift test` fully green; the $97.20 acceptance bill green both in the suite and driven on-device (Task 9.3); the closing invariant `Σ perPerson.total == assignedSubtotal + taxCents + tipCents == grandTotal` holds exactly; all money is integer cents with a single `allocate()` rounding path (no `Double`/`Float` touches money — the `BillCore` Foundation-only firewall proves it structurally).
2. **Verify non-negotiable #3 — offline & private.** No network calls / analytics / accounts (Task 9.1 source grep + runtime monitor clean); only the current bill persists, as `current-bill.json` in Application Support; `PrivacyInfo.xcprivacy` matches behavior; store label reads Data Not Collected.
3. **Verify the two-screen flow.** Screen 1 "The Bill" (diner roster + item rows + tap-to-assign, 2+ = split, sticky footer subtotal + Next, unassigned hazard-tape guard blocks Next) → Screen 2 "Tax, Tip & Totals" (tax field, tip presets, per-person cards that expand, reconciliation SETTLED ✓, round-up, Clear). Both reachable and complete.
4. **Verify non-negotiable #4 — bold but legible.** The CI accessibility audit (Task 9.2) is green; a manual grayscale + CVD (deuteranopia/protanopia/tritanopia) pass confirms every stateful meaning carries ≥3 non-color signals; no number renders on a gradient, chip, or glass; Reduce Motion and Reduce Transparency fallbacks work (the rail → opaque cream).
5. **Verify non-negotiable #2 — right-sized.** One `@Observable` store, no ViewModels/TCA/VIPER/SwiftData; confirm nothing enterprise crept in during release prep.
6. **Confirm the CI gates and store assets** from Tasks 9.2 and 9.4 are in place: three blocking checks, encryption flag, no ATT, screenshots, metadata.
7. **Record the checklist result** and, only when every item is checked, cut the release build / archive for submission.

**Technical details & suggestions:**
- The release checklist (each line must be checkable to true):
  - [ ] `swift test --package-path Packages/BillCore` green (allocate invariants + persistence + $97.20).
  - [ ] $97.20 bill driven on-device: Ana $20.39 / Ben $51.93 / Cy $24.88 / grand $97.20, SETTLED ✓.
  - [ ] Reconciliation re-fires and holds on every tip-preset and base-toggle change; round-up surplus honest.
  - [ ] Source grep clean of network/analytics/SDKs; runtime monitor shows zero connections.
  - [ ] Only `current-bill.json` in Application Support; Clear removes it; empty on relaunch.
  - [ ] `PrivacyInfo.xcprivacy`: tracking false, empty collected-data/tracking-domains, API reasons match usage.
  - [ ] `ITSAppUsesNonExemptEncryption = NO`; no ATT; App Privacy = Data Not Collected.
  - [ ] CI blocks merge on `swift test`, the `performAccessibilityAudit` smoke, and `swiftlint --strict`.
  - [ ] Grayscale + CVD pass; ≥3 non-color signals per state; no number on gradient/chip/glass; Reduce Motion / Reduce Transparency fallbacks OK.
  - [ ] Two-screen flow complete; unassigned guard blocks Next; single Clear confirm dialog.
  - [ ] Architecture still right-sized (one `@Observable` store; no ViewModels/TCA/SwiftData).
  - [ ] Store screenshots + subtitle/keywords/description prepared; brand-rename note recorded.
- Anchor sanity line to keep visible on the checklist: **any change to the math or model must keep the $97.20 acceptance bill green** — if it's red, do not ship, regardless of what else is done.
- Pitfall: don't let release prep quietly add scope (a settings screen, an export feature, a network "share to cloud"). Each violates a non-negotiable; the checklist exists partly to catch that.

**Done when:** Every line of the release checklist is checked true — the four non-negotiables are each provably satisfied, CI gates and store assets are in place, and the $97.20 anchor is green in both the suite and on-device — and the release build/archive is cut for App Store submission.
