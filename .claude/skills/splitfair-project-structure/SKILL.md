---
name: splitfair-project-structure
description: The folder/file layout for SplitFair — a local BillCore Swift package for pure domain logic plus one app target organized by feature. Use when creating files, deciding where new code belongs, setting up the Xcode project or Swift package, or naming targets and folders.
---

# SplitFair — project structure

One app target + **one local Swift package (`BillCore`)** for the pure domain. That package declares **no SwiftUI/UIKit dependency** — the missing import is a compile firewall (a `Double`-in-money or a UI import into the math becomes a build error), and it lets the whole test suite run via `swift test` in milliseconds with no simulator.

```
SplitFair/                                  # repo root
├─ SplitFair.xcodeproj
├─ Packages/
│  └─ BillCore/                            # LOCAL package — pure domain, Foundation ONLY
│     ├─ Package.swift                     # swift-tools 6.0; 1 library + 1 Swift Testing target; NO UI deps
│     ├─ Sources/BillCore/
│     │  ├─ Money.swift                    # Money (Int minor units) + typealias Cents = Int
│     │  ├─ Currency.swift                 # code + exponent (2 USD, 0 JPY, 3 BHD), derived from OS
│     │  ├─ Allocate.swift                 # allocate(amountCents:weights:) — the ONE rounding path
│     │  ├─ MoneyEdge.swift                # parse (Decimal+FormatStyle → Cents) & format (Cents → String)
│     │  ├─ Model.swift                    # Person, Item, TipMode, Bill — Codable/Sendable/Equatable
│     │  ├─ BillMath.swift                 # compute(bill) → BillResult
│     │  └─ Summary.swift                  # pure plain-text summary builder
│     └─ Tests/BillCoreTests/             # AllocateTests, BillMathTests, SummaryTests
├─ SplitFair/                              # APP TARGET — file-system-synchronized group
│  ├─ App/          SplitFairApp.swift · BillStore.swift
│  ├─ Features/
│  │  ├─ Bill/      BillScreen · DinerBar · ItemRow · PersonChip · AddItemRow
│  │  └─ Totals/    TotalsScreen · TaxTipControls · PersonTotalCard · ReconciliationBar
│  ├─ DesignSystem/ Theme · Color+Tokens · Font+Tokens · Modifiers · Shapes · DinerPalette
│  ├─ Persistence/  BillDraftStore.swift
│  ├─ Sharing/      ShareSummary.swift
│  ├─ Assets.xcassets
│  └─ PrivacyInfo.xcprivacy
└─ SplitFairUITests/ SmokeTests.swift      # 1-2 happy-path smokes carrying performAccessibilityAudit()
```

## Rules

- **Pure domain (`Sources/BillCore/`)** imports only Foundation. Money math, model types, formatting, summary text live here. UI never leaks in.
- **App target** organized **by feature** (`Features/Bill`, `Features/Totals`), not by type (no `Views/`, `Models/` mega-folders). Design tokens live in `DesignSystem/` (see `splitfair-design-system`).
- Use **Xcode file-system-synchronized groups** (folders are groups) → no `.pbxproj` churn, so XcodeGen/Tuist are unnecessary.
- **Name the package `BillCore`, not `SplitFair`**, so a future brand rename never churns the core.
- Add it via *File → Add Package Dependencies → Add Local*; app files `import BillCore`.
- One file per primary type; view files named for the view (`ItemRow.swift`). See `splitfair-swift-conventions` for naming.
- `Info.plist` auto-generated (`GENERATE_INFOPLIST_FILE=YES`). No `.entitlements` file (no network/iCloud/push).
