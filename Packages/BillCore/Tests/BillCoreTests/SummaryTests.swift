import Foundation
import Testing
@testable import BillCore

@Suite("Summary")
struct SummaryTests {
    @Test("Golden per-person summary text")
    func golden() {
        let ana = Person(name: "Ana", colorIndex: 0)
        let ben = Person(name: "Ben", colorIndex: 1)
        var bill = Bill(people: [ana, ben], tax: .zero, tip: .percent(20))
        bill.items = [
            Item(label: "Salad", amount: Money(1000), assigneeIDs: [ana.id]),
            Item(label: "Steak", amount: Money(2000), assigneeIDs: [ben.id]),
        ]
        // subtotal 3000, 20% tip = 600, grand 3600 -> Ana 1200 / Ben 2400.
        let text = Summary.text(for: bill, locale: Locale(identifier: "en_US"))
        #expect(text == """
        SplitFair — total $36.00
        Ana: $12.00
        Ben: $24.00
        (tax + 20% tip, split by what each ordered)
        """)
    }
}
