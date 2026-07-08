# SplitFair — Product Spec & Research Dossier

> An offline, no-login, ad-free bill splitter that splits by **who ordered what**, not by headcount.
> Solves the exact moment even-split calculators fail: *"I only had the salad, they had steak and three cocktails."*

**Status:** Concept / pre-build · **Target complexity:** 2/5 · **Screens:** 2 · **Platform stance:** offline-first, cross-platform (ship Android from day one)

This document is the single source of truth for the idea: what it is, why it's worth building, the exact feature set, the screen-by-screen flow, the correctness-critical math (verified to the penny), edge cases, the roadmap, and the open decisions you need to make before writing code.

---

## 0. TL;DR — the verdict

**Build it. The concept is one of the strongest "small utility" ideas you can pick** — it solves a real, felt, universal pain with pure local arithmetic and a tiny surface area. But three things separate a good version from a forgettable one:

1. **Rename it.** `SplitFair` is a direct collision with a live, funded, cross-platform incumbent (see §1). This is the one thing to fix *before* anything else.
2. **The differentiator is not "itemized" — it's "itemized AND zero-setup."** Itemization alone is now table stakes (Tab, splitty, Payback all do it). Your moat is the *whole relationship*: no account, no scan, no history, works on a plane, forgets the bill when you're done. Market the combination, not the feature.
3. **The math is the product.** If per-person totals don't sum to the receipt *to the exact cent*, users lose trust instantly. §5 gives a verified algorithm that always reconciles. Spend your engineering budget here, not on breadth.

---

## 1. ⚠️ The name problem (resolve first)

**`SplitFair` is already taken by a near-identical product.**

- **Splitfair — Group Expenses** exists on the [App Store](https://apps.apple.com/us/app/splitfair-group-expenses/id6744828986) (id `6744828986`) and [Google Play](https://play.google.com/store/apps/details?id=dev.thebill.app), with a marketing site at [splitfair.app](https://www.splitfair.app/) and a [2025 Product Hunt launch](https://www.producthunt.com/products/splitfair).
- It is **cross-platform and actively maintained**, and its headline features are *exactly your differentiator*: "assign individual items from a shared bill to specific people" and "split portions of items (½, ⅓, custom)."

**Why this matters:** you can never win App Store search for your own brand term against an established same-name app, users who hear the name will download *them*, and an identically-named app in the same category is a textbook trademark "likelihood of confusion" problem.

The whole `split*` namespace is saturated too: Splitwise, Splitfair, SplitFare, Fair Split, Fairsplit, Splid, spliit, SplitPay, SplitterUp, SplitPatron, Tab, Payback, Divvi… "Split" + "Fair" are both generic descriptive words → weak, hard-to-protect, invisible on a crowded shelf.

**Recommendation:** pick a distinctive, ownable, ideally **non-`split`** word before launch, and run a knockout search (App Store + [USPTO TESS](https://tmsearch.uspto.gov/)) plus a `.app` domain check.

Directions worth exploring (verify each for collisions):

| Angle | Candidates |
|---|---|
| The settle-up *moment* | Evenly, Settled, Square, Squared, Reckon, Tally, Doled, Fairly |
| The "just a calculator" honesty | Splitless, Kitty, Dutch, GoDutch |
| Invented / ownable | short brandable coinage you can trademark cleanly |

> Keep the working name "SplitFair" in this doc for now, but treat the rename as a hard pre-launch gate. Everywhere below, "SplitFair" = "the app."

---

## 2. The idea in one paragraph

Friends and roommates settling a shared restaurant bill or grocery run open the app, add the people at the table, add each line item, tap to assign items to the right people (or mark an item shared), enter the tax and tip off the receipt, and instantly get a fair per-person total — with each person's tax and tip **prorated by what they actually ordered**, and every total reconciled so the parts sum to the receipt exactly. Then they hit **Clear** and it's gone. No account, no ads, no network, nothing stored beyond the current bill.

---

## 3. Why it's worth building

- **The pain is real, felt, and universal.** Almost everyone who eats out in a group has felt the quiet unfairness of subsidizing someone else's steak-and-cocktails on an even split. Solving a *felt* pain beats solving a theoretical one.
- **The constraints ARE the marketing.** Offline + no-login + ad-free isn't just easier to build — it's the whole story. Splitwise's biggest friction is "everyone needs an account." You win the one-dinner moment precisely because you demand nothing.
- **Honest scope.** Complexity 2/5, two screens, pure local arithmetic, no backend, no data layer. Realistic to build well.
- **A genuinely vacated niche exists** — *Plates by Splitwise* nailed this exact drag-items-to-people model, then abandoned it (iOS-only, unmaintained since ~2013). On Android, essentially **nothing** occupies the manual-itemized + offline + no-account corner.

---

## 4. Competitive landscape

The market splits into two camps, and both miss the target. Group-ledger apps are built for *ongoing balances*; tip calculators only *divide by headcount*; the modern itemizers *require accounts and/or cloud OCR*.

| App | Itemized (who ordered what)? | No account? | Fully offline? | Ad-free? | Price | Verdict for "one dinner, by items" |
|---|:--:|:--:|:--:|:--:|---|---|
| **Splitwise** | Paywalled (Pro) | ❌ | ❌ (cloud ledger) | ❌ (ads + daily limits on free) | $4.99/mo · $40/yr | Overkill; account friction; the feature you need is behind the paywall |
| **Plates by Splitwise** | ✅ (drag to plates) | ✅ | ✅ | ✅ | Free | **The closest match — but iOS-only & abandoned (~2013).** This is the opening. |
| **Tricount** | ❌ | ✅ | ✅ | ✅ | Free (+~$10/yr) | Great offline group ledger, but no item-level assignment |
| **Settle Up** | ❌ | ✅ | ✅ | ❌ (ads on free) | ~$1–2 | Settle-up focus, not a per-item splitter |
| **Splid** | ❌ | ✅ | ✅ | ✅ | $4.99 one-time | Shares your constraints exactly — but can't do "who ordered what" |
| **KittySplit** | ❌ | ✅ | ❌ (web/link) | ✅ | Free | Zero-install share-by-link, but online + not itemized |
| **Tab** | ✅ (OCR scan) | ❌ | ❌ (scan + sync online) | ✅ | Free | Fastest itemization, but account + network required |
| **splitty / ReceiptSplit / Payback** | ✅ | ✅ (mostly) | ❌ (cloud OCR) | mixed | freemium | Occupy the "no-account itemized" edge, but depend on cloud scanning |
| **Venmo / PayPal** | ❌ | ❌ | ❌ | — | Free | Payments, even/custom splits only — not itemized |
| **Tip N Split / Tip Calculator Gold** | ❌ (even split) | ✅ | ✅ | ❌ / ✅ | $2.99 unlock / free | Dumb even-splitters; don't solve steak-vs-salad at all |

### The precise gap SplitFair fills

The **intersection of all seven**: (1) per-item assignment · (2) shared-item splitting · (3) proportional tax + tip + round-up · (4) no account · (5) fully offline *including no cloud OCR* · (6) ad-free · (7) one-off with no stored ledger — delivered in 2 screens.

**Be honest — the gap is thin, not empty.** Plates hit it and left. ReceiptSplit/splitty sit on the edge but depend on cloud scanning and freemium gates. So the defensible wedge is: **maintained · cross-platform (esp. Android) · manual-first (100% offline, no OCR) · free · ad-free · radically simpler than the scanner apps.**

---

## 5. Positioning & differentiation

Itemization is necessary but **no longer sufficient** to stand out. Shift the claim from the *feature* (itemizing) to the *experience* (a calculator you close, not a relationship you join).

- **One-line positioning:** *"Split the bill by who actually ordered what — no account, no sign-up, works offline."*
- **Tagline options:** *"Fair splits, no strings."* · *"The bill splitter you don't have to sign into."* · *"Everyone pays for what they ordered. Then it's gone."*
- **Contrast, don't list features** (put these in screenshot captions — they do the competitive work for you):
  - vs Splitwise → *"Splitwise is a ledger you join. This is a calculator you close."*
  - vs tip calculators → *"A tip calculator splits evenly. This splits by who ordered the steak."*
- **Privacy = respect + speed, not fear.** Nobody thinks their dinner receipt is "sensitive." The compelling story is *frictionlessness and honesty*: no account to make, no ads, works with no signal, forgets the bill when you're done. Back it with Apple's **"Data Not Collected"** privacy label — free, verifiable credibility competitors can't show.

---

## 6. Target user & the core moment

- **Who:** 2–20 friends, roommates, or coworkers splitting one shared restaurant bill or a grocery run. Optimize hard for the **4-person dinner**.
- **The moment:** the bill lands, someone's card will pay it, and the table needs to know who owes what — fairly — in under a minute, passing **one phone** around.
- **Design consequence:** every interaction must survive the phone changing hands (single taps only, big tap targets, no mode-switching, no precise gestures).

---

## 7. Feature set (MoSCoW)

### MUST — the core loop (11 items = definition of done for v1)

**The 8-step loop (remove any one and the app can't compute a fair answer or start a second bill):**
1. Add / name people.
2. Add a line item = **required amount** + optional label.
3. Assign an item to **one OR many** people (shared item splits equally among assignees).
4. Enter **tax** (dollar amount off the receipt).
5. Enter **tip** (amount OR %).
6. Live **grand-total readout** (Σitems + tax + tip) to eyeball against the paper receipt.
7. **Per-person total** = their item subtotal + prorated tax + prorated tip.
8. **Clear / reset** the whole bill (with confirm).

**The 3 correctness guarantees most splitters get wrong (these are the reason to use SplitFair over a calculator):**
9. **Prorate tax & tip by each person's item subtotal — never evenly.** Even-splitting tax/tip is exactly the unfairness the app exists to kill.
10. **Penny reconciliation (largest-remainder):** per-person totals must sum to the grand total *to the exact cent*. See §8.
11. **Unassigned-item guard:** an item with zero assignees silently vanishes from everyone's total and under-charges the table — flag it visibly and warn at the totals step.

**The 4 cheap friction-killers (their absence makes it feel broken):**
- **"Shared by all" / "Assign to everyone"** button on every item row (the table wine / shared appetizer is the single most common action).
- **Inline-editable amounts** (a mistyped price is a one-tap fix, never a reason to restart).
- **Delete item & delete person** (one wrong add shouldn't force a reset).
- **Fast person entry:** one name field where **Enter adds and re-focuses**, pre-filled with "Person N" so a name is optional.

### SHOULD — high value, v1 survives without them
- **Tip % presets** (15 / 18 / 20 / 25 + custom) — big win over typing a percent.
- **Copy summary** to clipboard / OS share sheet — the offline, no-account substitute for "requesting" money.
- **Per-person expandable breakdown** — tap a person to see which items + how much tax/tip make up their total. Kills "why do I owe that?" disputes.
- **Undo on delete** (a snackbar undo beats confirm dialogs everywhere).

### COULD — only if effectively free
- **Round-up toggle** (nearest $1), default **OFF**, showing the surplus explicitly (e.g. "+$2.00 → extra tip"). *If you treat round-up as a headline value, promote it to MUST — but keep it a dumb nearest-dollar toggle, not a configurable engine.*
- **Quantity field** ("2× beer"). · **Currency symbol** from locale. · **Dark mode.**
- Discounts need **no dedicated feature** — a negative-amount item covers coupons/comps.

### WON'T (for v1) — deliberate exclusions that hold complexity at 2/5
No accounts/login/sync · **no bill history or saved bills** · **no item templates/favorites** (they need persistence — this is the trap that turns a 2/5 into a 4/5) · **no receipt OCR/camera** (biggest complexity sink in the category) · no settle-up / who-owes-whom minimization graph · no weighted/percentage shares · no multiple-payer reconciliation · no multi-currency conversion · no payment deep-links · no categories/tags · no multi-bill management.

> Each excluded item is a real product on its own. Write this list down so scope creep during the build has a ready answer.

---

## 8. The process — screen-by-screen UX

**One interaction primitive to rule them all: per-item people-chip toggles (tap-to-assign).** Each item row shows the diners as tappable avatar chips (initials/color). Tap a chip to assign; tap 2+ to split *that item* evenly among them. This beats every alternative for the pass-the-phone case:
- **Drag-and-drop fails at 3+ people** — drop targets crowd and interfere.
- **A full person×item matrix** is too dense for a phone.
- **Person-centric "active user" modes** force error-prone mode switching.

With chip toggles, the driver never changes mode — they read down the list and toggle. Shared items use the *same gesture* as solo items. **No "Calculate" button anywhere — everything is live.**

### Screen 1 — "The Bill" (entry + assignment, merged)

Merging entry and assignment onto one screen removes a whole navigation pass — you assign each item *the moment you add it*.

```
┌─────────────────────────────────────────┐
│  [SA] [AL] [JO] [+ Add person]   ← sticky diner bar (h-scroll)
├─────────────────────────────────────────┤
│  Salad                    12.50   (SA)   │  ← tap chips to assign
│  Steak                    28.00   (AL)   │
│  Cocktail                  9.00   (AL)   │
│  Nachos (shared 3 ways)   10.00  SA AL JO│  ← 2+ chips = even split
│  ⚠ Fries — tap a name      6.00   · · ·  │  ← amber = unassigned
│  [ + Add item ]                          │
├─────────────────────────────────────────┤
│  Subtotal $65.50        [ Next: Tax & Tip → ]   ← sticky footer
└─────────────────────────────────────────┘
```

- **Top (sticky):** horizontal-scroll diner chips + "+ Add person".
- **Body:** item list — optional name, **large right-aligned bold price**, compact strip of diner chips, and a one-tap **"Shared by all"** affordance. Unassigned rows render **amber**.
- **"+ Add item"** opens an inline row with the **numeric keypad already up** on the price field.
- **Footer (sticky):** running subtotal + primary "Next: Tax & Tip →".

### Screen 2 — "Tax, Tip & Totals" (the settle screen)

```
┌─────────────────────────────────────────┐
│  Tax        [ $5.24 ]        ( % )       │  ← enter $ off receipt by default
│  Tip    [15][18][20*][25][Custom] = $11.79│ ← presets, live $, on pre-tax
│  Tip base: ● pre-tax   ○ total           │
├─────────────────────────────────────────┤
│  [AL]  Alex ....................  $51.93 ⌄│  ← tap to expand
│  [SA]  Sam .....................  $20.39 ⌄│
│  [JO]  Jo ......................  $24.88 ⌄│
│  ────────────────────────────────────────│
│  Totals add up to $97.20  ✓              │  ← reconciliation line, always ✓
├─────────────────────────────────────────┤
│  ☐ Round each person up to $1            │
│  [ Copy summary ]        [ Clear bill ]  │
└─────────────────────────────────────────┘
```

- **Tax:** enter the **dollar amount straight off the receipt** by default (a % toggle for the minority).
- **Tip:** preset % chips computed on **pre-tax subtotal** by default, resulting **$ shown live**, plus a pre/post-tax toggle and a flat-amount option.
- **Per-person cards:** big bold total, **tappable to expand** into that person's items + their share of tax/tip. Recalculates live.
- **Reconciliation line** ("Totals add up to $97.20 ✓") — always proves the parts equal the whole.
- **Round-up toggle** shows where surplus goes; then penny reconciliation keeps the sum exact.
- **Copy summary** (plain text to clipboard) + **Clear bill** (confirm).

### Empty states (teach the 2-step model, no splash)
- **First run:** headline *"Who's splitting?"* with the add-person field **auto-focused, keyboard up**. No "New bill" ceremony.
- **Diners, no items:** a ghost sample row + *"Add the first item — tap + Add item."*
- **Item added, unassigned:** amber row + non-blocking banner *"2 items still unassigned."*
- **Cleared bill:** straight back to *"Who's splitting?"*.

### Input-minimizing tactics
Numeric keypad up by default on price · item name optional (auto "Item N") · Enter-to-chain when adding names · "Shared by all" = 1 tap not N · tip presets = zero typing · chips/toggles replace every dropdown & stepper. Target: a 4-person / 8-item bill in **~2 taps per item + 1 tip chip**.

### Accessibility (phone changes hands)
Every control ≥ **44×44 pt** · high-contrast **filled vs outlined** chip states legible at arm's length · **single taps only** (no long-press or drag) · confirm **only** the destructive "Clear bill".

### Persistence nuance (within "no data stored beyond current bill")
Persist **only the current bill** to on-device storage so a screen-lock, backgrounding, or accidental refresh mid-split doesn't wipe the table's work (auto-save-draft behavior users expect). **"Clear bill" wipes it** and returns to empty. No history, no accounts, no network.

---

## 9. The math — the correctness core (verified to the penny)

> This section was independently re-computed by an adversarial checker and **reconciles exactly**. Treat it as the spec for the arithmetic. **Represent every monetary value as integer cents — a float must never touch money.**

### The single primitive: `allocate(A, weights[])`

Distributes an integer amount `A` (cents) across `n` parties by `weights`, returning integers that sum to **exactly `A`** (largest-remainder / Hamilton method):

```
allocate(A, w[0..n-1]) -> int[]:
  1. W = sum(w).  If W == 0, set w = [1,1,…,1] and W = n.   // equal-weight fallback
  2. for each i:
        base[i] = (A * w[i]) div W       // integer product FIRST, then div/mod — no float
        rem[i]  = (A * w[i]) mod W
  3. R = A - sum(base)                    // by floor construction, 0 <= R < n
  4. order indices by rem[i] DESCENDING, ties broken by index ASCENDING  // deterministic
  5. add 1 to base[i] for the first R indices
  // result sums to exactly A, because sum(base) + R = A
  // negative amounts (flat discounts): allocate the magnitude, then negate every element
```

Route **every** division through this one function — shared items, tax, tip, service charge, discounts. **One rounding code path = one thing to test.**

### Three passes, each closed by `allocate()`

1. **Item subtotals.** Personal item cents go directly to the owner. Each shared item is split among its `k` assignees with `allocate(itemCents, [1]*k)` (leftover cents go to the lowest roster-index assignees). Person *i*'s subtotal `S[i]` = personal items + shares of every shared item they're on. `Σ S == Σ item prices` exactly.
2. **Tax.** Do **not** recompute from a percentage — take the exact printed `taxCents` and `tax = allocate(taxCents, S)`. Honors the receipt's own rounding.
3. **Tip.** `tip = allocate(tipCents, S)`. Default base = **pre-tax subtotal** (toggle for post-tax).

`finalᵢ = S[i] + tax[i] + tip[i] (+ serviceCharge[i] − discount[i])`. Because every whole-bill figure is distributed by `allocate()`, **the per-person finals sum to the grand total to the exact cent.**

### Worked example (3 people — reconciles to $97.20)

**Items:** Ana Salad $12.50 · Ben Steak $28.00 + Cocktail $9.00 · Cy Pasta $16.00 · **Nachos $10.00 shared by all three.**

| Step | Computation | Result |
|---|---|---|
| Shared nachos | `allocate(1000, [1,1,1])` → base 333 each, 1¢ leftover → first assignee | **[334, 333, 333]** = 1000 ✓ |
| Item subtotals `S` | Ana 1250+334 · Ben 2800+900+333 · Cy 1600+333 | **[1584, 4033, 1933]** = 7550 ✓ |
| Tax = $6.60 | `allocate(660, S)`, W=7550 → base [138,352,168] (Σ658), rem [3540,4180,7380], R=2 → +1¢ to Cy & Ben | **[138, 353, 169]** = 660 ✓ |
| Tip = 20% pre-tax = $15.10 | `allocate(1510, S)` → base [316,806,386] (Σ1508), rem [6040,4530,4530], R=2 → +1¢ to Ana, then Ben (tie broken by index) | **[317, 807, 386]** = 1510 ✓ |

**Per-person finals:** Ana `1584+138+317 = 2039` → **$20.39** · Ben `4033+353+807 = 5193` → **$51.93** · Cy `1933+169+386 = 2488` → **$24.88**.

**Σ finals = 9720 = grand total (7550 + 660 + 1510).** ✅ Reconciles to the exact penny.

> Note the whole point: Ana (salad + share of nachos) pays **$20.39** while Ben (steak + cocktail) pays **$51.93** — versus a naive even split of **$32.40 each**.

### Invariants to enforce (kills the off-by-a-cent bug)
- **Never** derive a total by summing independently-rounded parts — always `allocate()` a known integer total and let the parts absorb the residual.
- Reconcile against the **actual integer receipt amount**, never a recomputed float.
- Keep **exactly one** rounding path (`allocate`) for shared items, tax, tip, service charge, discounts.
- `assert sum(result) == A` inside `allocate` as a runtime check.
- Use a **stable tie-break** (ascending index) so the same bill always splits identically across devices.

---

## 10. Edge cases & how to handle them (all v1-simple)

| Case | Handling in v1 |
|---|---|
| **Penny rounding** | Integer cents + single largest-remainder pass (§9). *The* correctness item. |
| **Person with zero items** | Falls out for free: 0 subtotal → 0 tax → 0 tip → $0.00. Keep them (may be a payer). |
| **Zero total subtotal** | Guard every proration divide: if subtotal is 0, shares are 0 (not NaN). Optional: equal split if tax/tip exist. |
| **Unassigned items** | One visible **"Unassigned" bucket**; block finalize/clear while non-empty. This single guard covers deleted-person items, emptied shared items, and never-assigned items. |
| **Deleting a person with items** | Drop them from shared-item sharer sets (others absorb via recompute); move solely-owned items to Unassigned. Never dangle a reference or silently drop cost. |
| **Editing an item after assignment** | Model assignments as person↔item **links**, separate from price/name. Editing price/name keeps links; just recompute. Almost no special-case code. |
| **Shared item, changing subset** | Splits equally among the *current* sharer set; add/remove just recomputes. Empty set → Unassigned. No drift (pennies reconcile once at the end). |
| **Discounts / coupons** | Editable per-item price (comp = set to $0), **or** one optional bill-level discount ($ or %) applied to subtotal *before* tax/tip and prorated by subtotal. Clamp person totals ≥ 0. *(Simplest: just use a negative-amount item.)* |
| **Service charge vs tip** | Keep **two distinct fields**. If a service charge is entered, default tip to 0 and hint "service already included" so nobody double-tips. Both prorate like tax. |
| **Tip pre- vs post-tax** | Store tip as an **absolute amount** (source of truth); % buttons compute on pre-tax by default + a single pre/post toggle. Once tip is a number, no ambiguity reaches the split. |
| **Someone already paid** | Optional per-person "paid" field. Net owed = share − paid; negative = "is owed $X". Covers the common "one card paid it all" case. |
| **Multiple payers** | Same "paid" field on more than one person; show "remaining unpaid". *(Defer optimal settlement graphs.)* |
| **Currency & locale** | One currency per bill (default device locale). Store the **minor-unit exponent** (2 USD/EUR, 0 JPY/KRW, 3 KWD/BHD) and do integer math in those units — JPY reconciles on whole yen automatically. Format via `Intl.NumberFormat`. **Don't hardcode 2 decimals.** |
| **Very large groups** | Math is O(n log n) — scales trivially. Keep the list scrollable; tune UX for 2–20. |
| **Round-up surplus** | Round-up is a **display toggle** layered on the exact reconciled totals (never the source of truth); label surplus honestly ("+$1.40 → tip/kitty"). |

**Fixed pipeline order:** item subtotals → shared-item split → bill discount → tax → service charge → tip → prorate tax/service/tip by share of the (discounted) subtotal → subtract per-person "paid" → net balances.

---

## 11. Suggested data model

```
Bill {
  currency: { code, exponent }          // e.g. { "USD", 2 }
  people:   [ { id, name } ]
  items:    [ { id, label?, amountCents, assigneeIds: [personId] } ]  // links, not embedded prices
  taxCents:      int
  tipCents:      int        // absolute amount = source of truth
  tipBase:       "pretax" | "total"
  serviceCents:  int        // optional, distinct from tip
  discount?:     { kind: "amount" | "percent", value }
  paidCents:     { [personId]: int }     // optional
  roundUp:       false | "dollar"        // display only
}
```

Persist exactly **one** `Bill` on-device (auto-save draft). "Clear bill" replaces it with an empty one. No arrays of bills, ever (that's history — a "Never").

---

## 12. Roadmap

Ship v1 as the core loop above. Then:

### v2 — "Close the loop" (the growth release; offline-safe, no new screens)
- **Share / export per-person summary** (copyable **text + rendered image** via OS share sheet). *The word-of-mouth engine* — the organizer pastes the breakdown into the group chat and everyone sees the app. **Drop the "share link" variant** — a hosted link needs a server and breaks the offline promise.
- **Payment deep-links** (`venmo://`, `upi://`, Cash App, PayPal, Zelle) via URL schemes — the OS opens the payment app, so SplitFair still makes **zero network calls, holds no money, needs no account** (stays out of money-transmitter/KYC territory). Region-aware, single "request payment" handoff — not a wall of icons. *The retention engine.*
- **Dark mode** + **haptics** — cheap polish that lifts store ratings. Respect system reduce-motion.

> Share = acquisition; payment deep-links = retention. Shipping both together is what makes v2 compound.

### v3 — "Fairness completeness" (still offline, account-free)
- **Discount handling** (prorated like tax — same engine).
- **Split by shares / percentage** for uneven shared items ("split the appetizer 2:1"). Build **one flexible shares control** — it subsumes "split by weight," so don't build a bespoke weight mode.
- **Per-person tip override** (niche, cheap — rides along).
- **Currency picker** (display symbol/locale only — *not* conversion).

### Receipt OCR — gated, probably Never
High *perceived* value, high effort, high promise-risk. Cloud OCR breaks offline outright; on-device OCR is inaccurate on receipts and forces a correction step that undermines the fast/simple feel. **Only pursue if** it runs 100% on-device, stays an optional pre-fill (never required), and doesn't add a mandatory screen or push past 2/5. If it can't meet all three → Never.

### Never (treat as a product contract, not a backlog)
**Bill history · multiple bills / bill manager · multi-currency conversion · iCloud/optional sync · ads · analytics/tracking SDKs · in-app payment processing · any network call · accounts.** Each erodes a specific pillar (ephemeral / offline / no-login / ad-free) and drifts you toward being Splitwise — i.e., the crowded incumbent instead of the honest alternative. **The promise is the moat.**

---

## 13. Monetization

- **A subscription is both unjustifiable and self-contradicting** here — pure local arithmetic, no server costs, no recurring value, and a recurring fee for offline math directly undercuts the privacy brand. **Ads and accounts are off the table by definition.**
- **Best fit: one-time unlock (paymium).** Keep the **entire split flow free — never paywall the fairness math.** A single ~$2.99–4.99 IAP can unlock *conveniences that don't compromise the ethos*: themes/appearance, export/share polish, custom rounding, unlimited people.
- **Most on-brand: a tip jar** ("pay what you want to support an indie, ad-free app," e.g. $1.99 / $4.99 / $9.99). Earns less than a gated unlock — choose by whether you're optimizing principle or revenue.
- **Turn constraints into public promises** in the store listing: *no ads ever, no account ever, no data sold, no subscription for offline math.* The promise is itself the marketing.
- **Set expectations:** median indie app earns < $50/mo after a year; only ~17% ever reach $1k/mo. With no analytics and thin paid-discovery, this is a **craft / portfolio piece and modest earner**, not a business. The growth lever is being so frictionless people screenshot it at the table — plan a Product Hunt / r/apple / indie-newsletter launch moment.

---

## 14. Definition of done for v1

- [ ] **Rename** decided; App Store name + `.app` domain confirmed free; knockout search done.
- [ ] The **11 MUST** items (8-step loop + 3 correctness guarantees) work end-to-end.
- [ ] The **4 friction-killers** ("Shared by all", inline-edit, delete item/person, Enter-to-chain names).
- [ ] **`allocate()`** implemented once, integer-cents throughout, routed through for shared items + tax + tip.
- [ ] **Unassigned bucket** blocks finalize/clear; amber flagging on Screen 1.
- [ ] **Reconciliation line** on Screen 2 always reads ✓.
- [ ] Two SHOULD features first: **tip presets** + **copy summary**.
- [ ] **Acceptance test:** a 4-person, 6-item bill with one item shared 3 ways and one assigned to everyone — confirm per-person totals sum to the grand total **to the penny**.
- [ ] Unit-test the pathological cases: 1¢ shared 3 ways · everyone comped · 100% discount · a single odd-cent item · a large party (verify residual < n).

---

## 15. Open decisions for you

1. **The name.** Highest-priority blocker. Pick a non-`split`, ownable word and clear it.
2. **Round-up: MUST or COULD?** Your brief lists it as core value. If it's a headline differentiator, promote it to MUST (but keep it a dumb nearest-dollar toggle). Otherwise it's a COULD, default OFF.
3. **Platform & stack.** Recommendation: build cross-platform and **ship Android from day one** (that's where the niche is genuinely empty). Any of Flutter / React Native / a local-only PWA fits a 2-screen, offline, no-backend app — pick what you'll enjoy maintaining.
4. **Tip default base:** pre-tax (recommended) vs post-tax — confirm the default, keep the toggle.
5. **Monetization stance:** free-forever, one-time unlock, or tip jar — decide before the store listing, since it shapes the copy.

---

### Sources

Competitive & positioning research drew on: Splitwise Pro pages, Plates by Splitwise (App Store + 2013 announcement), Tricount, Settle Up, Splid, KittySplit, Tab, Venmo Groups, Tip N Split, Tip Calculator Gold, splitty/ReceiptSplit, the live **Splitfair** listings (App Store `id6744828986`, splitfair.app, Product Hunt, Google Play), SplitFare / Fair Split, RevenueCat *State of Subscription Apps 2025*, and Apple's App Privacy details. The proration math was derived from first principles (integer largest-remainder / Hamilton apportionment, ISO 4217 minor units, `Intl.NumberFormat`) and **independently verified to reconcile to the exact cent**.

*Generated from a 7-dimension research sweep + adversarial math verification.*
