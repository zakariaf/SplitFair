---
name: splitfair-reconciliation-banner
description: SplitFair's reconciliation banner — a perforated success-green check-stub with a rubber-stamp "SETTLED ✓" that thunks in and a counting-up grand total proving the parts equal the whole. Use when building the Screen 2 totals confirmation, the settled state, or the round-up surplus note.
---

# SplitFair — reconciliation banner

The emotional climax: proof that "you're charged right." A perforated tear-edge stub (`PerforationEdge`, `splitfair-shapes-and-depth`) in **success green** above the Screen 2 actions.

## Anatomy

- **Text:** "Totals add up to $97.20" — the grand total in SF Rounded Black, `.monospacedDigit()`.
- **Stamp:** a `checkmark.seal.fill` ✓ rubber-stamp that **thunks in** via `PhaseAnimator` (scale 1.4→0.95→1.0 + slight rotation), rotated ~−9° for a hand-stamped feel.
- **Count-up:** the total counts up on entry, capped by a single `.sensoryFeedback(.success)` (`splitfair-motion-and-haptics`).
- **Word, not just color:** carries the label "SETTLED / adds up" — green is never the only signal (`splitfair-accessibility`).
- **Self-healing note** (SF Mono 13pt) when rounding was applied: "rounding balanced · +$0.02 → tip".
- **Failure path:** if totals ever fail to reconcile, it flips to amber + ⚠ and names the gap — but with correct math (`splitfair-money-math`) this never fires.

## Round-up (adjacent)

A single toggle "Round each person up to $1." When on, it shows the honest surplus ("Adds $1.40 across the table → tip"). Round-up is **display-only**, layered on the exact reconciled totals — it never becomes the source of truth and never makes the parts silently disagree with the whole.

## Rules

- The stamp and count-up animate the **exact reconciled integer-cent value** the math produces — never a rounded or faked number.
- Green here is **reserved** for this settled state (`splitfair-color-system`); don't reuse it for "owed."
- Re-fire the stamp whenever the tip changes (`splitfair-tip-controls`) — it always reconciles again.
- Under Reduce Motion the stamp just fades in with the haptic; the number sets instantly.
- Post a VoiceOver announcement: "Totals add up, settled."
