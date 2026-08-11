import Foundation
import SwiftData

/// Reads and writes the saved sessions.
@MainActor
final class SessionStore {
    /// A session shorter than this is thrown away, as in the original app.
    static let minimumDuration: TimeInterval = 1

    let container: ModelContainer

    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    /// Builds the SwiftData container.
    ///
    /// The store gets its own folder. The SwiftData default is
    /// `~/Library/Application Support/default.store`, and this app is not
    /// sandboxed, so that path is shared with every other application of the
    /// user. Two applications would then fight over one file.
    ///
    /// - Parameter inMemory: `true` gives a throw-away store, used by the tests.
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        if inMemory {
            return try ModelContainer(
                for: Session.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }

        return try ModelContainer(
            for: Session.self,
            configurations: ModelConfiguration(url: try storeURL())
        )
    }

    /// `~/Library/Application Support/thyme-ng/thyme-ng.store`.
    static func storeURL() throws -> URL {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(path: "thyme-ng", directoryHint: .isDirectory)

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        return directory.appending(path: "thyme-ng.store", directoryHint: .notDirectory)
    }

    // MARK: - Read

    /// Every session, newest first.
    func all() -> [Session] {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    var count: Int {
        (try? context.fetchCount(FetchDescriptor<Session>())) ?? 0
    }

    // MARK: - Write

    /// Stores one session, then prunes the old ones.
    /// - Parameter limit: how many sessions to keep. `0` means keep every one.
    /// - Returns: the new session, or `nil` if the duration was too short.
    @discardableResult
    func add(
        duration: TimeInterval,
        tag: String = "",
        date: Date = .now,
        keeping limit: Int = 0
    ) -> Session? {
        guard duration >= Self.minimumDuration else { return nil }

        let session = Session(
            date: date,
            duration: duration.rounded(.down),
            tag: tag.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        context.insert(session)
        prune(keeping: limit)
        save()

        return session
    }

    /// Deletes the oldest sessions above the limit.
    /// - Parameter limit: how many to keep. `0` or less means keep every one.
    func prune(keeping limit: Int) {
        guard limit > 0 else { return }

        let sessions = all()
        guard sessions.count > limit else { return }

        for session in sessions[limit...] {
            context.delete(session)
        }

        save()
    }

    /// Deletes every session.
    func clear() {
        try? context.delete(model: Session.self)
        save()
    }

    private func save() {
        guard context.hasChanges else { return }
        try? context.save()
    }

    // MARK: - Export

    /// The export shape of the original: `[{ "date", "duration", "tag" }]`, newest first.
    struct Record: Codable, Equatable {
        let date: String
        let duration: Int
        let tag: String
    }

    func records() -> [Record] {
        all().map { session in
            Record(
                date: Self.exportDateFormatter.string(from: session.date),
                duration: Int(session.duration.rounded(.down)),
                tag: session.tag
            )
        }
    }

    func exportData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(records())
    }

    /// The suggested file name, for example `thyme-ng-2026-08-11.json`.
    static func exportFileName(for date: Date = .now) -> String {
        "thyme-ng-\(fileDateFormatter.string(from: date)).json"
    }

    private static let exportDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = .current
        return formatter
    }()

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
