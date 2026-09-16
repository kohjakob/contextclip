import XCTest
@testable import Contextclip

@MainActor
final class HistoryStoreTests: XCTestCase {
    private func temporaryHistoryURL() -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("contextclip-tests-\(UUID().uuidString)", isDirectory: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory.appendingPathComponent("history.json")
    }

    func testAddInsertsNewestFirstAndPersists() {
        let fileURL = temporaryHistoryURL()
        let store = HistoryStore(fileURL: fileURL, maxItems: 10)

        store.add(HistoryItem(imagePath: "/tmp/a.png", text: "first"))
        store.add(HistoryItem(imagePath: "/tmp/b.png", text: "second"))

        XCTAssertEqual(store.items.map(\.text), ["second", "first"])

        let reloaded = HistoryStore(fileURL: fileURL, maxItems: 10)
        XCTAssertEqual(reloaded.items, store.items)
    }

    func testAddTrimsToMaxItems() {
        let store = HistoryStore(fileURL: temporaryHistoryURL(), maxItems: 2)

        for index in 1...3 {
            store.add(HistoryItem(imagePath: "/tmp/\(index).png", text: "\(index)"))
        }

        XCTAssertEqual(store.items.map(\.text), ["3", "2"])
    }

    func testRemoveAndClear() {
        let fileURL = temporaryHistoryURL()
        let store = HistoryStore(fileURL: fileURL)
        let keep = HistoryItem(imagePath: "/tmp/keep.png", text: "keep")
        let drop = HistoryItem(imagePath: "/tmp/drop.png", text: "drop")
        store.add(keep)
        store.add(drop)

        store.remove(drop)
        XCTAssertEqual(store.items, [keep])

        store.clear()
        XCTAssertTrue(store.items.isEmpty)
        XCTAssertTrue(HistoryStore(fileURL: fileURL).items.isEmpty)
    }

    func testLoadsHistoryWrittenByPreviousVersion() throws {
        let fileURL = temporaryHistoryURL()
        let legacy = """
        [{"timestamp":811081659.059589,"id":"1945D306-A871-4D16-B3FD-1A2E831BD912","imagePath":"/tmp/x.png","text":"hello"}]
        """
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try legacy.write(to: fileURL, atomically: true, encoding: .utf8)

        let store = HistoryStore(fileURL: fileURL)

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items.first?.text, "hello")
        XCTAssertEqual(store.items.first?.id.uuidString, "1945D306-A871-4D16-B3FD-1A2E831BD912")
        XCTAssertEqual(store.items.first?.timestamp.timeIntervalSinceReferenceDate ?? 0, 811081659.059589, accuracy: 0.001)
    }

    func testCorruptFileYieldsEmptyHistory() throws {
        let fileURL = temporaryHistoryURL()
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "not json".write(to: fileURL, atomically: true, encoding: .utf8)

        XCTAssertTrue(HistoryStore(fileURL: fileURL).items.isEmpty)
    }
}
