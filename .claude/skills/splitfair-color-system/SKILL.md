---
name: splitfair-color-system
description: SplitFair's color tokens (warm cream / aubergine, ink, Tangerine CTA, Acid-Lime, semantic green/amber/red) for light and dark, plus the 10 colorblind-safe diner colors with four-channel redundant identity. Use when picking any color, defining Asset Catalog colors, assigning per-person colors, or checking contrast and dark mode.
---

# SplitFair — color system

Governing rule: **loud frame, calm center** — saturated color only on diner chips, CTA/footer, and the reconciliation stamp. Reading surfaces are opaque and warm.

## Core tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| Canvas | `#FAF2E2` | `#16121C` | Warm cream / deep aubergine (never white/gray). Carries a faint dot-matrix grid. |
| Surface | `#FFFFFF` | `#221C2E` | Cards, rows — lifted by a hard offset ink shadow. |
| Ink primary | `#1A1613` | `#F7EDDD` | **All money + body.** 14.8:1 / ~15:1 contrast. |
| Ink secondary | `#6E6152` | `#B3A594` | Labels, meta. |
| Keyline | `#1A1613` @2pt | `#F7EDDD` @2pt | Sticker/button borders. Divider `#E7DCC6` / `#3A3348`. |
| Shadow | `#1A1613` | `#0C0912` | Hard offset (0 blur). |

## Accent / semantic (dark re-tuned ~−12% chroma / +6% lightness)

| Role | Light | Dark | Rule |
|---|---|---|---|
| Primary CTA | Tangerine `#FF5A2C` | `#FF6E44` | White label clears 4.5:1. |
| Live tip readout | Acid-Lime `#B8E600` | `#D2FF3A` | **Always ink text** on lime. Only on the live tip pill (`splitfair-tip-controls`). |
| Reconciliation | Success `#1FB25A` | `#34D07A` | **Trust only** — the SETTLED ✓ state. |
| Warning (unassigned) | Amber `#FF9E1C` on `#FFEBC4` | on `#3A2A12` | Rendered as hazard-tape, never color alone (`splitfair-status-flags`). |
| Danger | Red `#E5453C` | `#FF5A50` | **Only** for Clear bill. Never for "owed." |

**Semantic stance — avoid the red/green trap:** "owed" is a neutral **ink number**, not red. "Settled" is green **+ ✓ + the word**. Danger-red appears exactly once, on destroy.

## The 10 diner colors

Assigned in **fixed roster order** (stable all session); beyond 10 the list cycles and appends a numeric badge. Dark = each lightened ~8%.

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

## Four-channel identity (never color alone)

Each diner reads by **(a) color + (b) initials** (in the pre-paired white/ink that clears 4.5:1) **+ (c) a unique corner-notch silhouette** (grayscale-legible) **+ (d) a micro-texture**. Verify every hue in a grayscale pass and deuteranopia/protanopia/tritanopia simulation. Consumed by `splitfair-diner-chip` and `splitfair-split-ring`; contrast rules in `splitfair-accessibility`.
