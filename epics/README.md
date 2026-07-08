# SplitFair — Build Epics

The end-to-end plan to build SplitFair, sequenced so each epic's finishing state is the next epic's starting state. **Money before UI; foundations before components; components before screens.**

Each epic is one file. Inside: what it's for, the state before starting, the definition of done, and a full task list. **Every task begins with the `splitfair-*` skill(s) to load before starting it** — load those first, then follow the task.

## Order & dependencies

```
01 Foundation ─▶ 02 Money Engine ─▶ 03 State & Persistence ─┐
                                                             ▼
        06 Screen 1 ◀─ 05 Components ◀─ 04 Design System ◀──┘
             │
             ▼
        07 Screen 2 ─▶ 08 Motion/Haptics/A11y ─▶ 09 Compliance & Release
```

## The epics

| # | Epic | Tasks | From → To |
|---|---|:--:|---|
| [01](EPIC-01-project-foundation.md) | **Project Foundation & Tooling** | 6 | empty repo → buildable iOS 17 app + BillCore package + tooling + privacy config |
| [02](EPIC-02-money-engine.md) | **The Money Engine (BillCore)** | 7 | empty package → tested pure domain, `allocate()`, `$97.20` acceptance green |
| [03](EPIC-03-state-and-persistence.md) | **App State & Local Persistence** | 5 | engine only → `BillStore` drives the app; bill auto-saves & restores |
| [04](EPIC-04-design-system-foundation.md) | **Design System Foundation** | 5 | default styling → color/font tokens, diner palette, Shapes, theme |
| [05](EPIC-05-ui-components.md) | **Reusable UI Components** | 7 | tokens only → chip, split-ring, buttons, cards, tip controls, banner, flags |
| [06](EPIC-06-screen-the-bill.md) | **Screen 1 — The Bill** | 6 | components → working assign-by-item screen + unassigned guard |
| [07](EPIC-07-screen-tax-tip-totals.md) | **Screen 2 — Tax, Tip & Totals** | 6 | Screen 1 → live totals, SETTLED stamp, round-up, share, clear |
| [08](EPIC-08-motion-haptics-accessibility.md) | **Motion, Haptics & Accessibility** | 5 | plain screens → delightful + fully accessible (passes audit) |
| [09](EPIC-09-compliance-and-release.md) | **Privacy, Compliance & Release Prep** | 5 | feature-complete → shippable, CI-gated, store-ready |

**52 tasks total.**

## How to use these

1. Work the epics in order; within an epic, work tasks in order.
2. For each task, **load the named skill(s) first** (e.g. `/splitfair-money-math`), then follow the steps and hit the "Done when" criterion before moving on.
3. The recurring anchors every epic protects: **per-person totals reconcile to the exact cent** (the `$97.20` bill), **offline / no-account / no data beyond the current bill**, the **two-screen flow**, and **bold-but-legible** HARD COPY design (ink-on-paper numbers).
