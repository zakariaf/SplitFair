---
name: splitfair-status-flags
description: SplitFair's status treatments — the unassigned-item hazard-tape flag (three simultaneous signals), the empty states, and the sticky glass footer rail. Use when building the unassigned warning, the Next-blocked behavior, first-run/empty screens, or the Screen 1 footer with the live subtotal and CTA.
---

# SplitFair — status flags & footer

Money must never be silently lost, and the app must be instantly actionable. These treatments enforce both.

## Unassigned flag (three simultaneous signals — never color alone)

Any item with zero assignees is flagged with all three (`splitfair-accessibility`):
1. The item row's left edge becomes amber + ink **hazard-tape** (diagonal stripes) — replacing the normal 4pt ink rule (`splitfair-cards`).
2. An `exclamationmark.triangle.fill` ⚠ in amber.
3. The text "tap a name".

The split-ring shows its hollow dashed state (`splitfair-split-ring`). The footer shows a running count ("Nachos + 1 unassigned"). **Tapping Next while any remain does NOT navigate** — the ⚠ symbols wiggle (`symbolEffect(.bounce)`) + `.sensoryFeedback(.warning)` and the offending rows scroll into view (`splitfair-motion-and-haptics`). Fully legible in grayscale.

## Empty states (teach the 2-step model, no splash)

- **First run:** giant Fraunces "WHO'S SPLITTING?" (`splitfair-typography`) centered on the drifting-blob cream canvas, a single ghost (dashed) sticker beneath, keyboard already up with the name field auto-focused; Return chains the next person.
- **Diners, no items:** a friendly dashed "+ Add item" sticker-card that expands inline with the numeric keypad already presented.
- **Cleared bill:** returns straight to the "WHO'S SPLITTING?" state.

## Sticky footer / subtotal rail (the ONE glass element)

The single Liquid-Glass surface (`splitfair-design-system`): a floating bottom rail using `.glassEffect` (fallback `.regularMaterial`) with a `PerforationEdge` top so the total "tears off" like a check stub.
- **Left:** live "Subtotal $75.50" odometer in SF Rounded Black, `.numericText()` roll on every change — but the number sits on an **opaque cream pill** so no digit composites over glass.
- **Right:** the Tangerine primary CTA (`splitfair-buttons`).
- Under Reduce Transparency the rail becomes opaque cream.

## Rules

- The "Unassigned" concept is one reusable guard covering three cases at once: never-assigned items, a shared item emptied of sharers, and a deleted person's solo items (`splitfair-state-store`).
- Block finalize/Clear-navigation while anything is unassigned so money is never dropped.
