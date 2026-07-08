# EPIC 04 — Design System Foundation

> Lay the HARD COPY foundation: color tokens, fonts, the diner palette, custom Shapes, hard-shadow depth, and a theme — everything components will be built from.

## What this epic is for

Every screen and component built after this point must be styled from tokens, never from ad-hoc literals. This epic creates the `SplitFair/DesignSystem/` layer that encodes the "HARD COPY" (Warm Receipt Brutalism) visual language: light/dark Asset-Catalog color tokens surfaced through a `Color` extension, the bundled Fraunces serif plus the three-voice `Font` token system, the fixed 10-color diner palette with four-channel redundant identity, the signature custom `Shape`s and the hard offset shadow, and a `Theme` injected at the app root. Getting this right means later views compose from a single source of truth so the app reads consistently — ink-on-cream numbers you can trust across a restaurant table, loud color only on the frame, hard shadows for confidence. Getting it wrong means every component re-invents spacing, color, and depth, and the app drifts off-brand.

## Where we are before starting (starting state)

- EPIC 01–03 are complete: an iOS 17 SwiftUI app that builds and launches; a linked local `Packages/BillCore` pure-domain package (Foundation-only) with a green Swift Testing suite (`allocate` invariants + the $97.20 acceptance bill).
- A `@MainActor @Observable BillStore` is injected at the App root, drives a live current bill with a computed totals property, and auto-saves/restores one JSON draft in Application Support.
- The folder skeleton exists: `SplitFair/App`, `SplitFair/Features`, `SplitFair/DesignSystem`, `SplitFair/Persistence`, `SplitFair/Sharing`, plus `Assets.xcassets` and `PrivacyInfo.xcprivacy`.
- The UI is still **default SwiftUI styling** — system fonts, system colors, no design tokens, no custom shapes, no shadows. `DesignSystem/` is empty (or holds only placeholders).
- SwiftFormat + SwiftLint + a pre-commit hook are wired; the app has no ATT, no entitlements, and the encryption flag set.

## What we will have after finishing (definition of done)

- **Color tokens (Task 4.1):** Every core, accent, and semantic token defined as an Asset-Catalog color set with Any (light) + Dark appearances at the exact hexes, surfaced through a `Color` extension in `DesignSystem/Color+Tokens.swift`. No manual `colorScheme` branches anywhere.
- **Diner palette (Task 4.2):** A `DinerStyle` value model carrying `color` + `NotchStyle` + `ChipTexture` per index, the fixed 10 entries in roster order, colorblind-safe, cycling with a numeric badge beyond 10, in `DesignSystem/DinerPalette.swift`.
- **Typography (Task 4.3):** Fraunces bundled and registered via `ATSApplicationFontsPath`; the `money` / `ledger` / `display` `Font` tokens; the full type scale mapped to Dynamic Type with `relativeTo:`; tabular-numeral and no-truncate rules encoded, in `DesignSystem/Font+Tokens.swift`.
- **Shapes & depth (Task 4.4):** `BrutalShadow` (solid rect, 0 blur), `.card()` / `.sticker()` modifiers, and the custom `Shape`s `PerforationEdge`, `CornerNotch`, `SplitRing`, the `Canvas` dot-matrix grid, and the drifting blur blobs, in `DesignSystem/Modifiers.swift` and `DesignSystem/Shapes.swift`.
- **Theme + gallery (Task 4.5):** A `Theme` in `EnvironmentValues` (radii / spacing / shadow offsets) injected at the App root, the documented Liquid-Glass stance for the one glass rail, and a SwiftUI `#Preview` token gallery rendering every token and shape in **both** light and dark.
- The app still builds and launches; the gallery preview renders with no missing-asset or missing-font warnings; every diner style survives a grayscale pass.

## Dependencies

- Depends on: EPIC 03 — App State & Local Persistence (a live `BillStore` at the App root to inject `Theme` alongside).
- Enables: EPIC 05 — Reusable UI Components (every component is built from these tokens, shapes, and the theme).

---

## Tasks

### Task 4.1 — Define color tokens (light/dark) via Asset Catalog

**Skills to load:** `splitfair-color-system`, `splitfair-design-system`

**Why this matters:** Color is the load-bearing part of the "loud frame, calm center" rule. Reading surfaces (anything holding a dollar amount) must stay opaque and warm; saturated color is allowed **only** on diner chips, the CTA/footer chrome, the lime tip pill, and the reconciliation stamp. If tokens are wrong or ad-hoc, numbers end up on gradients or low-contrast fills and the app loses the "trust across a restaurant table" quality. The single most expensive mistake here is the **red/green trap**: coloring an "owed" amount red or a normal total green. In this design, "owed" is a **neutral ink number**, "settled" is green **plus a ✓ plus the word SETTLED**, and danger-red appears exactly once (Clear bill). Asset-Catalog colors with Any/Dark appearances give automatic light/dark with **no manual `colorScheme` branches**, which is the only maintainable way to do this.

**What to do:**
1. In `SplitFair/Assets.xcassets`, create one **Color Set** per token below. For each set, set **Appearances = Any, Dark** and enter the exact light hex under Any and the exact dark hex under Dark. Use sRGB, 8-bit hex input.
2. Create `SplitFair/DesignSystem/Color+Tokens.swift` with an `extension Color` exposing each token as a `static let` bound to its Asset-Catalog name (e.g. `Color("Canvas")`). Do not compute colors in code — the asset drives light/dark.
3. Add the two divider tints and the two ink-shadow tints as their own sets (they differ light/dark just like everything else).
4. Add a doc comment above each token stating its **allowed use** and its **contrast target**, so component authors don't misuse it.

**Technical details & suggestions:**

Core tokens (Any = light, Dark = dark):

| Token (asset name) | Light | Dark | Use |
|---|---|---|---|
| `Canvas` | `#FAF2E2` | `#16121C` | Warm cream / deep aubergine background. **Never** white/gray. Carries the faint dot-matrix grid. |
| `Surface` | `#FFFFFF` | `#221C2E` | Cards, rows — lifted by the hard offset ink shadow. |
| `Ink` | `#1A1613` | `#F7EDDD` | **All money + body.** ~14.8:1 / ~15:1 contrast. |
| `InkSoft` (ink secondary) | `#6E6152` | `#B3A594` | Labels, meta. |
| `Keyline` | `#1A1613` | `#F7EDDD` | 2pt sticker/button borders. |
| `Divider` | `#E7DCC6` | `#3A3348` | Hairline rules, ring base. |
| `Shadow` | `#1A1613` | `#0C0912` | Hard offset shadow fill (0 blur). |

Accent / semantic tokens (dark re-tuned ≈ −12% chroma / +6% lightness):

| Token (asset name) | Light | Dark | Rule |
|---|---|---|---|
| `Tangerine` (primary CTA) | `#FF5A2C` | `#FF6E44` | White label must clear 4.5:1. |
| `AcidLime` (live tip readout) | `#B8E600` | `#D2FF3A` | **Always ink text on lime.** Only on the live tip pill. |
| `Success` (reconciliation) | `#1FB25A` | `#34D07A` | **Trust only** — the SETTLED ✓ state. |
| `Warning` (unassigned) | `#FF9E1C` | `#FF9E1C` | Amber; paired backgrounds `#FFEBC4` (light) / `#3A2A12` (dark). Rendered as hazard-tape, never color alone. |
| `WarningBg` | `#FFEBC4` | `#3A2A12` | Background behind the amber hazard state. |
| `Danger` | `#E5453C` | `#FF5A50` | **Only** for Clear bill. Never for "owed." |

Sketch of `Color+Tokens.swift`:

```swift
import SwiftUI

extension Color {
    // Core surfaces — opaque, warm, hold all numbers
    static let canvas   = Color("Canvas")     // background, never white/gray
    static let surface  = Color("Surface")    // cards/rows
    static let ink      = Color("Ink")        // ALL money + body, ~15:1
    static let inkSoft  = Color("InkSoft")    // labels/meta
    static let keyline  = Color("Keyline")    // 2pt borders
    static let divider  = Color("Divider")    // hairlines, ring base
    static let shadow   = Color("Shadow")     // hard offset shadow (0 blur)

    // Accent / semantic — LOUD FRAME ONLY, never behind a number
    static let tangerine = Color("Tangerine") // primary CTA/footer
    static let acidLime  = Color("AcidLime")  // live tip pill only
    static let success   = Color("Success")   // SETTLED ✓ only
    static let warning   = Color("Warning")   // unassigned, as hazard-tape
    static let warningBg = Color("WarningBg")
    static let danger    = Color("Danger")    // Clear bill only
}
```

Pitfalls to avoid: (a) do **not** add a `Color(light:dark:)` initializer that branches on `colorScheme` — the Asset Catalog is the branch. (b) Do not reuse `Success` green for anything except reconciliation, or `Danger` red for anything except Clear. (c) Do not put `Tangerine`, `AcidLime`, or any diner hue behind a dollar amount — those are frame colors. (d) Keep `Canvas` and `Surface` distinct even in dark (aubergine vs slightly lifted aubergine) so cards read against the background via both the tone step and the shadow.

**Done when:**
- Every token above exists as an Asset-Catalog color set with correct Any + Dark hexes, and `Color+Tokens.swift` exposes each as a `static let`.
- A throwaway `#Preview` swatch grid renders all tokens with no "missing asset" warning, and visibly changes between the light/dark preview variants.
- `Ink` on `Canvas` and `Ink` on `Surface` both read as near-black-on-cream (light) / cream-on-aubergine (dark); white on `Tangerine` and ink on `AcidLime` are legible.
- No `if colorScheme == .dark` branch exists anywhere in `DesignSystem/`.

---

### Task 4.2 — Encode the 10-color diner palette

**Skills to load:** `splitfair-color-system`, `splitfair-diner-chip`

**Why this matters:** The diner chip is the core identity element and drives the whole tap-to-assign interaction, so a person's identity must survive **four redundant channels**, never color alone: **(a) color + (b) initials** (in the pre-paired white/ink that clears 4.5:1) **+ (c) a unique corner-notch silhouette** (grayscale-legible) **+ (d) a micro-texture**. If we encode only color, the app fails for colorblind users and in grayscale — a core accessibility requirement. Assignment is by **fixed roster order** and must be **stable for the whole session**, so the palette is an ordered list indexed by roster position, not a hash of the name. Beyond 10 people the list cycles and appends a numeric badge so identity never collapses.

**What to do:**
1. Create `SplitFair/DesignSystem/DinerPalette.swift`.
2. Define the two identity enums: `NotchStyle` (corner + single/double + the two mid positions) and `ChipTexture` (the per-diner micro-texture kinds). These are consumed later by `CornerNotch` (Task 4.4) and the `TextureOverlay` in `splitfair-diner-chip`.
3. Define a `DinerStyle` value type carrying `color`, `notch`, `texture`, and the pre-paired label color (`labelInk` — white or ink) plus the badge number when cycling past 10.
4. Encode the fixed 10 entries **in roster order** exactly per the table below (each with its color, label pairing, notch position, texture).
5. Add each of the 10 diner hues as an Asset-Catalog color set (light hex from the table; **dark = the same hue lightened ≈ 8%**) named `Diner1`…`Diner10`, and reference them by name so light/dark stays automatic.
6. Provide the assignment function: `DinerPalette.style(forRosterIndex:)` returns the base 10 by `index % 10`, and sets `badge = (index / 10) + 1` (nil for the first cycle) so the 11th person is Vermilion + badge "2", etc.

**Technical details & suggestions:**

The fixed 10 (roster order — do not reorder):

| # | Name | Light hex | Label | Notch | Texture |
|---|---|---|---|---|---|
| 1 | Vermilion | `#F2542D` | white | top-left | solid |
| 2 | Bubblegum | `#E84AA6` | white | top-right | dots |
| 3 | Grape | `#8A5CF6` | white | bottom-left | diagonal |
| 4 | Ocean | `#2E7DF7` | white | bottom-right | horizontal-rule |
| 5 | Cyan | `#17BEBB` | **ink** | top-left ×2 | ring |
| 6 | Pine | `#16A085` | white | bottom-left ×2 | cross-hatch |
| 7 | Sunflower | `#F4B400` | **ink** | top-right ×2 | checker |
| 8 | Terracotta | `#B5651D` | white | bottom-right ×2 | vertical-bars |
| 9 | Slate | `#5C6B8A` | white | top-mid | grid |
| 10 | Fern | `#3FA34D` | white | bottom-mid | waves |

```swift
import SwiftUI

enum NotchStyle: Equatable {
    case topLeft, topRight, bottomLeft, bottomRight          // single
    case topLeftDouble, bottomLeftDouble, topRightDouble, bottomRightDouble
    case topMid, bottomMid
}

enum ChipTexture: Equatable {
    case solid, dots, diagonal, horizontalRule, ring
    case crossHatch, checker, verticalBars, grid, waves
}

struct DinerStyle: Identifiable, Equatable {
    let id: Int              // 0-based palette index
    let name: String
    let color: Color         // Diner1…Diner10 asset (auto light/dark)
    let labelInk: Color      // pre-paired: .white or .ink, clears 4.5:1
    let notch: NotchStyle
    let texture: ChipTexture
    var badge: Int? = nil    // set when cycling past 10 (2, 3, …)
}

extension Color {
    /// The pre-paired label color for THIS diner hue (never computed at call site).
    var pairedInk: Color { self == .diner5 || self == .diner7 ? .ink : .white }
}

enum DinerPalette {
    static let base: [DinerStyle] = [
        .init(id: 0, name: "Vermilion",  color: .diner1,  labelInk: .white, notch: .topLeft,           texture: .solid),
        .init(id: 1, name: "Bubblegum",  color: .diner2,  labelInk: .white, notch: .topRight,          texture: .dots),
        .init(id: 2, name: "Grape",      color: .diner3,  labelInk: .white, notch: .bottomLeft,        texture: .diagonal),
        .init(id: 3, name: "Ocean",      color: .diner4,  labelInk: .white, notch: .bottomRight,       texture: .horizontalRule),
        .init(id: 4, name: "Cyan",       color: .diner5,  labelInk: .ink,   notch: .topLeftDouble,     texture: .ring),
        .init(id: 5, name: "Pine",       color: .diner6,  labelInk: .white, notch: .bottomLeftDouble,  texture: .crossHatch),
        .init(id: 6, name: "Sunflower",  color: .diner7,  labelInk: .ink,   notch: .topRightDouble,    texture: .checker),
        .init(id: 7, name: "Terracotta", color: .diner8,  labelInk: .white, notch: .bottomRightDouble, texture: .verticalBars),
        .init(id: 8, name: "Slate",      color: .diner9,  labelInk: .white, notch: .topMid,            texture: .grid),
        .init(id: 9, name: "Fern",       color: .diner10, labelInk: .white, notch: .bottomMid,         texture: .waves),
    ]

    /// Deterministic assignment by roster position (stable all session).
    static func style(forRosterIndex i: Int) -> DinerStyle {
        var s = base[i % base.count]
        let cycle = i / base.count
        if cycle > 0 { s.badge = cycle + 1 }   // 11th person → badge 2
        return s
    }
}

// Asset tokens for the 10 hues (Task 4.2 asset step)
extension Color {
    static let diner1 = Color("Diner1");  static let diner2 = Color("Diner2")
    static let diner3 = Color("Diner3");  static let diner4 = Color("Diner4")
    static let diner5 = Color("Diner5");  static let diner6 = Color("Diner6")
    static let diner7 = Color("Diner7");  static let diner8 = Color("Diner8")
    static let diner9 = Color("Diner9");  static let diner10 = Color("Diner10")
}
```

Pitfalls: (a) `labelInk` is **precomputed per hue** (Cyan #5 and Sunflower #7 pair with ink; all others with white) — never pick label color by a runtime luminance calc at the chip, which can flicker across light/dark. (b) Assign by **roster index only** — never by a name hash, or the same person changes color when the roster reorders. (c) `NotchStyle` and `ChipTexture` are pure data here; the actual `Shape`/overlay rendering is Task 4.4 and `splitfair-diner-chip` — this task just guarantees each of the 10 has a **distinct** notch and a **distinct** texture so the grayscale silhouette is unique. (d) Dark hexes are the light hue lightened ≈ 8% — enter them in the Asset Catalog Dark appearance; do not tint in code.

**Done when:**
- `DinerPalette.base` has exactly 10 entries in the table's order, each with a distinct `notch` and distinct `texture`.
- `DinerPalette.style(forRosterIndex:)` returns the right hue for 0–9 and cycles with `badge == 2` at index 10, `badge == 3` at index 20.
- All 10 `DinerN` asset color sets exist with Any + Dark appearances.
- A grayscale render of the 10 styles shows 10 distinguishable chips by notch + texture alone (color removed).

---

### Task 4.3 — Bundle Fraunces and define the type system

**Skills to load:** `splitfair-typography`

**Why this matters:** SplitFair speaks in **three voices**, and mixing them up destroys the design's meaning: the **ledger** (SF Mono Heavy/Bold) is the printer-receipt trust cue that column-aligns prices and breakdown lines; the **display money** (SF Pro Rounded Black) carries the hero subtotal, per-person totals, live tip readout and reconciliation total at arm's length; the **voice** (Fraunces serif, bundled) is character — wordmark, section titles, and the "WHO'S SPLITTING?" hero **only**. The non-negotiable numeral rule is that **every changeable amount uses `.monospacedDigit()`** so columns align and numbers never reflow or jitter mid-animation, and **prices never truncate — they wrap**, while display/hero sizes **cap** their Dynamic Type growth. Overusing the serif or forgetting monospaced digits are the two failure modes.

**What to do:**
1. Add the Fraunces variable font file to the app target (e.g. `SplitFair/Resources/Fonts/Fraunces.ttf`, SIL OFL, bundled once) and ensure it's in the target's **Copy Bundle Resources**.
2. Register it: since `GENERATE_INFOPLIST_FILE=YES`, add `ATSApplicationFontsPath` via an `INFOPLIST_KEY_...` build setting or a small supplemental plist listing the font path. Confirm the PostScript family name is exactly `"Fraunces"` (what `Font.custom` will ask for).
3. Create `SplitFair/DesignSystem/Font+Tokens.swift` with the three `Font` factory tokens and the type-scale helpers, mapping every text style to Dynamic Type via `relativeTo:`.
4. Add a `.moneyText()` view modifier (or a small `MoneyText` wrapper) that always applies `.monospacedDigit()`, disables truncation, allows wrapping to a second line, and applies `.contentTransition(.numericText())` for odometer amounts.
5. Encode the type scale as named token functions so callers use `.money(.hero)` etc. rather than raw sizes.

**Technical details & suggestions:**

```swift
import SwiftUI

extension Font {
    static func money(_ s: CGFloat)   -> Font { .system(size: s, weight: .black, design: .rounded).monospacedDigit() }
    static func ledger(_ s: CGFloat)  -> Font { .system(size: s, weight: .heavy, design: .monospaced).monospacedDigit() }
    static func display(_ s: CGFloat) -> Font { .custom("Fraunces", size: s) }  // registered via ATSApplicationFontsPath
}
```

Type scale (map to Dynamic Type with `relativeTo:` on the matching text style; **cap** display/hero growth):

| Element | Voice | Size | relativeTo |
|---|---|---|---|
| Hero subtotal / odometer | money | 56 (cap 64) | `.largeTitle` |
| "WHO'S SPLITTING?" hero | display | ~48 | `.largeTitle` |
| Wordmark / section title | display | 32–34 | `.title` |
| Per-person total | money | 40 | `.title` |
| Live tip readout pill | money | 26 | `.title2` |
| Item price (ledger) | ledger | 24 | `.title3` |
| Body / person name | SF Pro | 17 | `.body` |
| Chip initials | rounded semibold | 15 | `.subheadline` |
| Breakdown ledger line | ledger | 15 | `.footnote` |
| Caption / meta | SF Pro | 13 | `.caption` |

Suggested Dynamic-Type-aware helpers and the money guard:

```swift
extension Font {
    static let heroMoney   = Font.money(56)   // caller caps at 64 via ScaledMetric/lineLimit
    static let personTotal = Font.money(40)
    static let tipReadout  = Font.money(26)
    static let itemPrice   = Font.ledger(24)
    static let breakdown   = Font.ledger(15)
    static let sectionTitle = Font.display(32)
    static let hero        = Font.display(48)
}

extension View {
    /// Every changeable amount: tabular digits, never truncates, wraps, animates as an odometer.
    func moneyText() -> some View {
        self.monospacedDigit()
            .lineLimit(nil)
            .minimumScaleFactor(1)          // do NOT shrink money — wrap instead
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.numericText())
    }
}
```

Pitfalls: (a) Confirm the family name by loading the font in a `#Preview` and printing `UIFont.familyNames` / the specific font names — a wrong PostScript name silently falls back to system and the "voice" disappears. (b) Bundle Fraunces **once**; do not add multiple weights if the variable file covers them. (c) `.monospacedDigit()` is already baked into `money`/`ledger`, but any raw `Text` showing an amount must still call `.moneyText()` (or `.monospacedDigit()`) — a bare `Text("$40.00")` in a system font will jitter. (d) **Never** enable `minimumScaleFactor < 1` on money — the rule is wrap, not shrink; and **cap** hero/display growth so a huge accessibility size can't blow the layout. (e) Use the serif only for wordmark, section titles, and the hero — never for a number or body copy.

**Done when:**
- Fraunces renders in a `#Preview` (visibly serif, not a system fallback), confirmed via the printed font family name.
- `Font.money`, `Font.ledger`, `Font.display` and the named scale tokens exist and compile.
- A sample amount grows with Dynamic Type up to its cap, wraps rather than truncates at the largest sizes, and its digits stay column-aligned (tabular) when the value changes.
- `.moneyText()` applies `.numericText()` content transition so a changing amount animates as an odometer without reflow.

---

### Task 4.4 — Build shapes, depth and background

**Skills to load:** `splitfair-shapes-and-depth`

**Why this matters:** Depth in HARD COPY is a **hard offset shadow — a solid ink/aubergine rectangle offset x+3 y+4 with 0 blur** — never a soft iOS blur. That flat, printed-sticker shadow is the neo-brutalist confidence cue that makes cards read at arm's length; a soft blur reads 2011-skeuomorphic, not 2026. Corners stay **warm-rounded** (radius 22 for item rows, 26 for per-person cards) so the brutalism stays friendly. The custom `Shape`s are signatures: `PerforationEdge` (torn check-stub top), `CornerNotch` (the per-diner redundant-identity silhouette), `SplitRing` (N equal arcs around a price), and the `Canvas` dot-matrix receipt grid. The **only** gradient/blur allowed in the whole app is 2–3 very-low-opacity drifting accent ellipses **behind** the grid — and **never behind a number**.

**What to do:**
1. Create `SplitFair/DesignSystem/Modifiers.swift` with `BrutalShadow` and the `.card()` / `.sticker()` / `.perforatedTop()` view modifiers.
2. Create `SplitFair/DesignSystem/Shapes.swift` with the custom `Shape`s: `PerforationEdge`, `CornerNotch`, `SplitRing`, plus the `DotMatrixGrid` (`Canvas`) view and the `DriftingBlobs` background view.
3. Implement `CornerNotch` so it renders each `NotchStyle` case from Task 4.2 as a distinct grayscale-legible silhouette (single vs double square subtracted from the named corner; the two mid variants centered on an edge).
4. Implement `SplitRing` per `splitfair-split-ring`: a 3pt ink-bordered ring dividing into N equal arcs tinted by assignee diner hue with a ~1pt ink gap, rotated −90° so arc 0 starts at top, animatable via `.trim`.
5. Implement `DotMatrixGrid` as a single `Canvas` drawing a faint dot grid on `Canvas` color, and `DriftingBlobs` as 2–3 blurred low-opacity ellipses whose offsets drift slowly via `TimelineView`.

**Technical details & suggestions:**

```swift
import SwiftUI

// Depth = SOLID rect, 0 blur, offset behind the shape.
struct BrutalShadow: ViewModifier {
    var dx: CGFloat = 3; var dy: CGFloat = 4
    func body(content: Content) -> some View {
        content.background(Color.shadow.offset(x: dx, y: dy))
    }
    static var none: some ViewModifier { EmptyModifier() }
}

extension View {
    func card() -> some View {
        padding(20)
            .background(RoundedRectangle(cornerRadius: 26).fill(Color.surface))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.keyline, lineWidth: 2))
            .modifier(BrutalShadow())
    }
    func sticker(_ c: Color) -> some View {
        padding(10)
            .background(Capsule().fill(c))
            .overlay(Capsule().stroke(Color.keyline, lineWidth: 2))
            .modifier(BrutalShadow())
    }
    func perforatedTop() -> some View { clipShape(PerforationEdge()) }
}
```

Custom `Shape`s:

```swift
// Torn zig-zag + dotted top edge — the check-stub tear (footer rail, reconciliation stub).
struct PerforationEdge: Shape {
    var toothWidth: CGFloat = 10; var toothHeight: CGFloat = 6
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY + toothHeight))
        var x = r.minX; var up = true
        while x < r.maxX {                                  // trig/step loop across the top
            let nx = min(x + toothWidth, r.maxX)
            p.addLine(to: CGPoint(x: nx, y: r.minY + (up ? 0 : toothHeight)))
            x = nx; up.toggle()
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

// Subtracts a small square (or double square) from one corner — the per-diner identity silhouette.
struct CornerNotch: Shape {
    let style: NotchStyle
    var size: CGFloat = 9
    func path(in r: CGRect) -> Path { /* build a rounded-rect path, then subtract 1–2 squares
        at the corner/edge indicated by `style`; the two `*Mid` cases notch the mid of an edge */ }
}

// N equal arcs around a price — split reads spatially, legible in grayscale.
struct SplitRing: View {
    let assignees: [DinerStyle]     // roster order; empty = unassigned
    var body: some View {
        ZStack {
            Circle().stroke(Color.divider, lineWidth: 3)                       // base
            if assignees.isEmpty {
                Circle().stroke(Color.inkSoft, style: .init(lineWidth: 3.5, dash: [4, 6]))
            } else {
                let seg = 1.0 / Double(assignees.count)
                ForEach(Array(assignees.enumerated()), id: \.offset) { i, d in
                    Circle()
                        .trim(from: Double(i)*seg, to: Double(i+1)*seg - 0.02) // ~1pt ink gap
                        .stroke(d.color, style: .init(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))                          // arc 0 at top
                        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: assignees.count)
                }
            }
        }
    }
}
```

Background depth (the ONLY blur/gradient in the app):

```swift
struct DotMatrixGrid: View {        // faint receipt grid, drawn once in a Canvas
    var spacing: CGFloat = 14
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                             with: .color(Color.ink.opacity(0.06)))
                    x += spacing
                }
                y += spacing
            }
        }.allowsHitTesting(false)
    }
}

struct DriftingBlobs: View {        // 2–3 blurred ellipses drifting slowly, BEHIND the grid
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            ZStack {
                Ellipse().fill(Color.tangerine).blur(radius: 80).opacity(0.06)
                    .offset(x: 40 * sin(t/9), y: 30 * cos(t/11))
                Ellipse().fill(Color.diner4).blur(radius: 80).opacity(0.06)
                    .offset(x: -50 * cos(t/13), y: 40 * sin(t/8))
            }.allowsHitTesting(false)
        }
    }
}
```

Pitfalls: (a) `BrutalShadow` must use **`Color.shadow`** as a solid rect with **0 blur** — never `.shadow(radius:)`. (b) Keep the offset shallow (x3 y4); deep offsets read skeuomorphic. (c) The keyline is **2pt** ink (light) / cream (dark), from the tokens — don't hardcode black. (d) `DriftingBlobs` and `DotMatrixGrid` must set `.allowsHitTesting(false)` and sit at the very back of the `ZStack`, **never behind a number** (they belong to the canvas layer, and money always rides an opaque surface above them). (e) Under Reduce Motion the blobs should stop drifting (freeze `t`) — wire the actual honoring in EPIC 08, but structure `DriftingBlobs` so a static fallback is trivial. (f) Iconography is SF Symbols only (`checkmark.seal.fill`, `exclamationmark.triangle.fill`, `plus.circle`) — nothing bundled beyond Fraunces.

**Done when:**
- `BrutalShadow`, `.card()`, `.sticker()`, `.perforatedTop()` compile and a `.card()` renders a rounded surface with a **solid, 0-blur** offset ink shadow and a 2pt keyline.
- `CornerNotch` renders all 10 `NotchStyle` cases as visibly distinct silhouettes; `SplitRing([])` shows a dashed hollow ring and `SplitRing` with 3 assignees shows 3 equal arcs with ink gaps starting at top.
- `DotMatrixGrid` draws a faint dot grid in one `Canvas`, and `DriftingBlobs` shows 2–3 low-opacity blurred ellipses that drift; both are non-interactive and sit behind content.
- No soft `.shadow(radius:)` exists in `DesignSystem/`.

---

### Task 4.5 — Assemble the Theme and a preview gallery

**Skills to load:** `splitfair-design-system`

**Why this matters:** Tokens, fonts, and shapes need a single place that composes the **non-color** design constants — corner radii, spacing, shadow offsets — so components never hardcode `22` / `26` / `20` / `3,4` and drift. Injecting a `Theme` through `EnvironmentValues` at the App root (right next to the `BillStore` from EPIC 03) makes those constants available everywhere. This task also locks the **Liquid Glass stance**: content **diverges** from glass (opaque matte paper + die-cut stickers with hard offset shadows), and we **extend** glass on exactly **one** chrome element — the single sticky bottom rail via `.glassEffect` (fallback `.regularMaterial`, and opaque cream under Reduce Transparency), where even then the live number rides an opaque cream pill so no digit composites over glass. Finally, a `#Preview` gallery showing every token and shape in **light and dark** is the acceptance surface for the whole epic — it's how we prove the foundation is complete and correct before any component is built.

**What to do:**
1. Create `SplitFair/DesignSystem/Theme.swift` defining a `Theme` struct of the non-color constants and an `EnvironmentValues` key with a default.
2. Inject `.environment(\.theme, .default)` at the App root in `SplitFair/App/SplitFairApp.swift`, alongside the existing `BillStore` injection.
3. Add a documentation comment (and a single reusable `glassRail` helper or note) capturing the Liquid-Glass stance: diverge everywhere, extend on the one bottom rail with `.glassEffect` → `.regularMaterial` fallback → opaque cream under Reduce Transparency, live number always on an opaque cream pill.
4. Build a `#Preview("Token Gallery — Light")` and `#Preview("Token Gallery — Dark")` (via `.preferredColorScheme`) in a `DesignSystem/Gallery.swift` (preview-only, or gate it in `#if DEBUG`) that renders: the color swatches, the three type voices at scale, the 10 diner styles as chips (color + initials + notch + texture), a `.card()`, a `SplitRing` with 1/2/3 arcs, the `PerforationEdge` stub, the dot-matrix grid, and the drifting blobs.

**Technical details & suggestions:**

```swift
import SwiftUI

struct Theme: Equatable {
    // radii
    var itemRadius: CGFloat = 22
    var cardRadius: CGFloat = 26
    // spacing
    var contentPadding: CGFloat = 20
    var stickerPadding: CGFloat = 10
    // depth
    var shadowOffset: CGSize = .init(width: 3, height: 4)
    var keylineWidth: CGFloat = 2

    static let `default` = Theme()
}

private struct ThemeKey: EnvironmentKey { static let defaultValue = Theme.default }
extension EnvironmentValues {
    var theme: Theme { get { self[ThemeKey.self] } set { self[ThemeKey.self] = newValue } }
}
```

Root injection (next to `BillStore` from EPIC 03):

```swift
@main
struct SplitFairApp: App {
    @State private var store = BillStore()          // EPIC 03
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(\.theme, .default)
                .tint(.tangerine)
        }
    }
}
```

Liquid-Glass stance (document in `Theme.swift`, apply in EPIC 06/07 chrome):

```swift
// DIVERGE on all content: opaque matte paper + stickers + hard offset shadows. Never translucent.
// EXTEND on exactly ONE chrome element — the sticky bottom rail:
extension View {
    @ViewBuilder func glassRail() -> some View {
        if #available(iOS 26, *) { self.glassEffect() }     // one rail only
        else { self.background(.regularMaterial) }          // fallback
        // Under Reduce Transparency: swap to Color.canvas (opaque cream) — wired in EPIC 08.
        // The live number always rides an opaque cream pill so no digit composites over glass.
    }
}
```

Gallery skeleton:

```swift
#if DEBUG
private struct TokenGallery: View {
    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            DriftingBlobs(); DotMatrixGrid()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 1. Color swatches: canvas/surface/ink/inkSoft + tangerine/acidLime/success/warning/danger
                    // 2. Type voices: hero (display), section title (display), hero money 56,
                    //    person total 40, tip readout 26, item price ledger 24, breakdown ledger 15
                    // 3. Diner styles 1…10 as chips (color + initials + notch + texture) + one badged (index 10)
                    // 4. A .card() with a SplitRing (1, 2, 3 arcs) and a PerforationEdge stub
                }.padding()
            }
        }
    }
}
#Preview("Token Gallery — Light") { TokenGallery().preferredColorScheme(.light) }
#Preview("Token Gallery — Dark")  { TokenGallery().preferredColorScheme(.dark) }
#endif
```

Pitfalls: (a) The `Theme` holds **non-color** constants only — colors stay in the Asset Catalog / `Color+Tokens.swift`, fonts in `Font+Tokens.swift`; don't duplicate them into `Theme`. (b) `.glassEffect` requires compiling against the iOS 26 SDK while the **deployment target stays iOS 17** — the `#available` guard and `.regularMaterial` fallback are mandatory; never make glass a content surface. (c) The gallery is the epic's proof — it must render in **both** color schemes with no missing-asset/missing-font warnings, and every diner chip must stay identifiable with color stripped (grayscale). (d) Keep the gallery `#if DEBUG` / preview-only so it never ships in the app binary. (e) Inject `\.theme` at the **root** so previews that need it can also set it locally.

**Done when:**
- `Theme` exists with radii/spacing/shadow-offset/keyline constants, is registered in `EnvironmentValues`, and is injected at the App root alongside `BillStore`.
- The Liquid-Glass stance is documented in code (diverge on content; one `glassRail()` with `#available(iOS 26)` → `.regularMaterial` fallback), with the deployment target unchanged at iOS 17.
- Both `#Preview` gallery variants (light and dark) render every token, all three type voices, all 10 diner styles (plus one badged), a `.card()`, `SplitRing` at 1/2/3 arcs, a `PerforationEdge` stub, the dot-matrix grid, and drifting blobs — with no missing-asset or missing-font warnings.
- A grayscale screenshot of the gallery keeps all 10 diner chips distinguishable (notch + texture + initials), and no dollar figure in the gallery sits on a chip, gradient, or glass.
