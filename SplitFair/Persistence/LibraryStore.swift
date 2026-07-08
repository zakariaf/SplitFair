import BillCore
import Foundation

/// The on-device library (EPIC 10): one JSON file per bill under `Bills/`, plus a `roster.json`
/// holding the persistent friends and which one is "you". Everything lives in Application Support
/// (never Documents, which is user-visible and iCloud-exposed), writes atomically with default file
/// protection. No history limit, no accounts, no sync — still "Data Not Collected."
///
/// The base directory is injectable so tests point it at a temp directory.
struct LibraryStore {
    let baseURL: URL

    init(baseURL: URL? = nil) {
        self.baseURL = baseURL ?? URL.applicationSupportDirectory
    }

    private var billsDirectory: URL { baseURL.appending(path: "Bills", directoryHint: .isDirectory) }
    private var rosterURL: URL { baseURL.appending(path: "roster.json") }
    private var legacyBillURL: URL { baseURL.appending(path: "current-bill.json") }
    private func billURL(_ id: Bill.ID) -> URL { billsDirectory.appending(path: "\(id.uuidString).json") }

    /// The persisted friends roster plus which person is "you" (nil until the first-run picker sets it).
    struct RosterSnapshot: Codable, Equatable {
        var people: [Person] = []
        var meID: Person.ID?
    }

    // MARK: - Bills

    /// Every saved bill, newest first. A corrupt or undecodable file is skipped, never fatal.
    func loadBills() -> [Bill] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: billsDirectory, includingPropertiesForKeys: nil
        ) else { return [] }
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? JSONDecoder().decode(Bill.self, from: Data(contentsOf: $0)) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Write one bill's file atomically (only the edited bill's file is rewritten).
    func saveBill(_ bill: Bill) throws {
        try FileManager.default.createDirectory(at: billsDirectory, withIntermediateDirectories: true)
        try JSONEncoder().encode(bill).write(to: billURL(bill.id), options: [.atomic])
    }

    /// Remove one bill's file (ignoring "no such file").
    func deleteBill(_ id: Bill.ID) {
        try? FileManager.default.removeItem(at: billURL(id))
    }

    // MARK: - Roster

    func loadRoster() -> RosterSnapshot {
        guard let data = try? Data(contentsOf: rosterURL),
              let snapshot = try? JSONDecoder().decode(RosterSnapshot.self, from: data)
        else { return RosterSnapshot() }
        return snapshot
    }

    func saveRoster(_ snapshot: RosterSnapshot) throws {
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
        try JSONEncoder().encode(snapshot).write(to: rosterURL, options: [.atomic])
    }

    // MARK: - Migration

    /// One-time migration of the legacy single-bill draft (`current-bill.json`) into the library:
    /// import it as a saved bill and seed the roster from its people (leaving "you" unset — the
    /// first-run picker sets it). A corrupt legacy file is discarded quietly, matching the old
    /// corrupt→empty rule. Idempotent: the legacy file is deleted afterward, so it never runs twice.
    func migrateLegacyDraftIfNeeded() {
        guard FileManager.default.fileExists(atPath: legacyBillURL.path) else { return }
        defer { try? FileManager.default.removeItem(at: legacyBillURL) }
        guard let data = try? Data(contentsOf: legacyBillURL),
              let bill = try? JSONDecoder().decode(Bill.self, from: data)
        else { return }
        try? saveBill(bill)
        if loadRoster().people.isEmpty, !bill.people.isEmpty {
            try? saveRoster(RosterSnapshot(people: bill.people, meID: nil))
        }
    }
}
