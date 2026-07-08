import Foundation

// MARK: - Running balances across the bill library

/// Net who-owes-whom balances relative to `me`, computed across every bill in the library.
///
/// This obeys the exact-cent contract: it is derived from the **same** reconciled per-person totals
/// as the on-screen split (`BillMath.compute`), never a parallel calculation, and it works purely in
/// integer minor units — no `Double` ever touches a balance.
///
/// For each bill, the payer fronted the whole grand total, so every *other* participant owes the
/// payer their own reconciled share:
///   - if `me` paid, each other participant's share is added → a **positive** balance ("they owe you");
///   - if a friend paid, `me`'s own share is subtracted against that friend → a **negative** balance
///     ("you owe them");
///   - if a third party paid, the bill contributes nothing to `me`'s balance with anyone (I owe the
///     payer, others owe the payer — not each other).
///
/// A bill with no recorded `payerID` (or a payer who isn't a participant) is skipped entirely — you
/// can't attribute a debt without knowing who fronted the money. Only non-zero balances are returned.
///
/// Positive value ⇒ that person owes you; negative ⇒ you owe that person.
public func netBalances(bills: [Bill], me: Person.ID) -> [Person.ID: Money] {
    var net: [Person.ID: Int] = [:] // minor units only — never Double

    for bill in bills {
        guard let payer = bill.payerID,
              bill.people.contains(where: { $0.id == payer })
        else { continue }

        let perPerson = BillMath.compute(bill).perPerson

        if payer == me {
            // Everyone else owes me their reconciled share of this bill.
            for person in bill.people where person.id != me {
                net[person.id, default: 0] += perPerson[person.id]?.total.minorUnits ?? 0
            }
        } else if bill.people.contains(where: { $0.id == me }) {
            // A friend paid; I owe them my reconciled share.
            net[payer, default: 0] -= perPerson[me]?.total.minorUnits ?? 0
        }
    }

    return net.compactMapValues { $0 == 0 ? nil : Money($0) }
}
