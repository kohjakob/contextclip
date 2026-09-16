import Foundation
import os

/// Newest-first list of captures, persisted as JSON in Application Support.
@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var items: [HistoryItem] = []

    let maxItems: Int
    let fileURL: URL

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Contextclip", category: "HistoryStore")

    nonisolated static var defaultFileURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return appSupport
            .appendingPathComponent("Contextclip", isDirectory: true)
            .appendingPathComponent("history.json")
    }

    init(fileURL: URL = HistoryStore.defaultFileURL, maxItems: Int = 50) {
        self.fileURL = fileURL
        self.maxItems = maxItems
        items = load()
    }

    func add(_ item: HistoryItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items.removeLast(items.count - maxItems)
        }
        save()
    }

    func remove(_ item: HistoryItem) {
        items.removeAll { $0.id == item.id }
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() -> [HistoryItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        do {
            return try JSONDecoder().decode([HistoryItem].self, from: data)
        } catch {
            logger.error("Could not read history: \(error.localizedDescription)")
            return []
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(items).write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Could not write history: \(error.localizedDescription)")
        }
    }
}
