import SwiftUI
import Testing
@testable import SplitFair

@Suite("Diner palette")
struct DinerPaletteTests {
    @Test("has 10 styles indexed 0..<10")
    func count() {
        #expect(DinerPalette.all.count == 10)
        #expect(DinerPalette.all.map(\.index) == Array(0 ..< 10))
    }

    @Test("every diner has a distinct notch + texture identity (colourblind-safe)")
    func distinctIdentity() {
        let signatures = DinerPalette.all.map { "\($0.notches)|\($0.texture)" }
        #expect(Set(signatures).count == 10)
    }

    @Test("style(for:) cycles past 10 and reports a badge for the 11th onward")
    func cycling() {
        #expect(DinerPalette.style(for: 0).index == 0)
        #expect(DinerPalette.style(for: 10).index == 0) // cycles
        #expect(DinerPalette.style(for: 12).index == 2)
        #expect(DinerPalette.cycleBadge(for: 3) == nil) // within the first 10
        #expect(DinerPalette.cycleBadge(for: 10) == 2) // 11th diner -> badge 2
    }
}
