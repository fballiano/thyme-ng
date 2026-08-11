import Foundation
import Testing
@testable import ThymeNG

@MainActor
@Suite("SessionStore")
struct SessionStoreTests {
    private func makeStore() throws -> SessionStore {
        SessionStore(container: try SessionStore.makeContainer(inMemory: true))
    }

    @Test("It stores a session")
    func storesSession() throws {
        let store = try makeStore()

        store.add(duration: 90, tag: "writing")

        let sessions = store.all()
        #expect(sessions.count == 1)
        #expect(sessions[0].duration == 90)
        #expect(sessions[0].tag == "writing")
    }

    @Test("It throws away a session shorter than one second")
    func discardsShortSession() throws {
        let store = try makeStore()

        #expect(store.add(duration: 0) == nil)
        #expect(store.add(duration: 0.9) == nil)
        #expect(store.add(duration: 1) != nil)
        #expect(store.count == 1)
    }

    @Test("It trims the whitespace of a tag")
    func trimsTag() throws {
        let store = try makeStore()

        store.add(duration: 10, tag: "  reading  ")

        #expect(store.all()[0].tag == "reading")
    }

    @Test("It lists the newest session first")
    func newestFirst() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        store.add(duration: 10, tag: "old", date: base)
        store.add(duration: 20, tag: "new", date: base.addingTimeInterval(60))

        #expect(store.all().map(\.tag) == ["new", "old"])
    }

    @Test("It keeps only the last N sessions")
    func prunesToLimit() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        for index in 0 ..< 12 {
            store.add(
                duration: 60,
                tag: "s\(index)",
                date: base.addingTimeInterval(Double(index) * 60),
                keeping: 10
            )
        }

        let sessions = store.all()
        #expect(sessions.count == 10)
        #expect(sessions.first?.tag == "s11")
        #expect(sessions.last?.tag == "s2")
    }

    @Test("A limit of zero keeps every session")
    func zeroLimitKeepsAll() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        for index in 0 ..< 25 {
            store.add(duration: 60, date: base.addingTimeInterval(Double(index)), keeping: 0)
        }

        #expect(store.count == 25)
    }

    @Test("Lowering the limit deletes the extra sessions")
    func pruneAfterTheFact() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        for index in 0 ..< 8 {
            store.add(duration: 60, date: base.addingTimeInterval(Double(index)), keeping: 0)
        }

        store.prune(keeping: 3)

        #expect(store.count == 3)
    }

    @Test("Clear removes everything")
    func clear() throws {
        let store = try makeStore()

        store.add(duration: 10)
        store.add(duration: 20)
        store.clear()

        #expect(store.count == 0)
    }

    @Test("The export has date, duration and tag, newest first")
    func exportShape() throws {
        let store = try makeStore()
        let base = Date(timeIntervalSince1970: 1_700_000_000)

        store.add(duration: 65.7, tag: "first", date: base)
        store.add(duration: 3661, tag: "", date: base.addingTimeInterval(3600))

        let records = store.records()
        #expect(records.count == 2)
        #expect(records[0].duration == 3661)
        #expect(records[0].tag == "")
        #expect(records[1].duration == 65)
        #expect(records[1].tag == "first")

        // The date is an ISO 8601 stamp with an offset.
        #expect(records[0].date.contains("T"))

        let data = try store.exportData()
        let decoded = try JSONDecoder().decode([SessionStore.Record].self, from: data)
        #expect(decoded == records)
    }

    @Test("The export file name carries the date")
    func exportFileName() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let name = SessionStore.exportFileName(for: date)

        #expect(name.hasPrefix("thyme-ng-"))
        #expect(name.hasSuffix(".json"))
    }

    @Test("A session prints the way the menu shows it")
    func menuText() throws {
        let store = try makeStore()

        let tagged = try #require(store.add(duration: 3661, tag: "work"))
        #expect(tagged.menuText.hasPrefix("01:01:01 - "))
        #expect(tagged.menuText.hasSuffix(" - work"))

        let untagged = try #require(store.add(duration: 61))
        #expect(untagged.menuText.hasPrefix("01:01 - "))
        #expect(!untagged.menuText.hasSuffix(" - "))
    }
}
