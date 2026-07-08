---
name: splitfair-accessibility
description: Accessibility rules for SplitFair — contrast for money, never-color-alone redundancy, Dynamic Type behavior, 44pt targets, and VoiceOver labeling. Use when building or reviewing any view, choosing colors/states, sizing type, or adding labels, to keep the bold look legible for everyone.
---

# SplitFair — accessibility

The bold look must never cost legibility or trust. These rules are requirements, not suggestions.

## Contrast

- **Money is always ink-on-cream (14.8:1) / cream-on-aubergine (~15:1).** Big totals clear 7:1; all amounts ≥ 4.5:1.
- **No number ever renders on a gradient, chip fill, or glass** — the footer number sits on an opaque cream pill.
- Every diner fill is pre-paired with white/ink initials clearing 4.5:1; Acid-Lime always carries ink text. Verify amber/green in BOTH modes against their **composited** (not nominal) backgrounds.

## Never color alone (5 channels)

- Diner identity = color + initials + corner-notch shape + micro-texture (`splitfair-color-system`, `splitfair-diner-chip`).
- Assignment = fill + keyline + scale + split-ring arc (`splitfair-split-ring`).
- Unassigned = hazard-tape stripes + ⚠ icon + "tap a name" text (`splitfair-status-flags`).
- Settled = green + ✓ stamp + the word "adds up" (`splitfair-reconciliation-banner`).
- Verify the whole UI in a grayscale pass and deuteranopia/protanopia/tritanopia simulation.

## Dynamic Type

- All text maps to text styles via `relativeTo:` so it scales.
- Display/hero sizes **cap** their growth and **wrap** prices to a second line rather than truncate.
- `.monospacedDigit()` everywhere numbers change so they never reflow or jitter mid-animation (`splitfair-typography`).
- Reflow the horizontal chip bar at accessibility Dynamic Type sizes.

## Targets & flow

- Every interactive element ≥ **44×44pt**.
- **Single-tap only** — no long-press or precise gestures (the phone is passed at arm's length).
- Exactly **one** confirm dialog in the whole app (Clear bill).

## VoiceOver

- Chips announce name + assignment + action: "Ana, assigned to Nachos, double-tap to remove."
- Totals read the full amount; the split-ring is described ("split 3 ways").
- The reconciliation banner posts an announcement "Totals add up, settled."
- Unassigned rows are grouped and reachable via the blocked-Next action.
- Honor Reduce Motion and Reduce Transparency (`splitfair-motion-and-haptics`).
