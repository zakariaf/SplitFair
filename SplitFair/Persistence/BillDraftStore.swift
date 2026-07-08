import BillCore
import Foundation

/// Persists exactly ONE `Bill` — the current draft — to a single JSON file. No history, no accounts,
/// no sync: "no data beyond the current bill" is a feature. Loading a missing or corrupt file falls
/// back to `.empty`, so no schema-migration machinery is ever needed for this ephemeral draft.
struct BillDraftStore {
    let url: URL

    /// Defaults to a file in Application Support (NOT Documents, which is user-visible and
    /// iCloud-exposed). The URL is injectable so tests can point at a temp directory.
    init(url: URL? = nil) {
        self.url = url ?? URL.applicationSupportDirectory.appending(path: "current-bill.json")
    }

    /// Load the saved bill, or `.empty` if the file is missing or can't be decoded.
    func load() -> Bill {
        guard let data = try? Data(contentsOf: url),
              let bill = try? JSONDecoder().decode(Bill.self, from: data)
        else { return .empty }
        return bill
    }

    /// Write atomically, keeping DEFAULT file protection — `.completeFileProtection` would make a
    /// save firing exactly at screen-lock fail, which is the loss case we most need to survive.
    func save(_ bill: Bill) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(bill)
        try data.write(to: url, options: [.atomic])
    }

    /// Remove the saved draft (used by Clear bill).
    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}
