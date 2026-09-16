import Foundation

/// One capture. Encoded with the default JSON strategies, so `timestamp` is seconds since 2001.
struct HistoryItem: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let imagePath: String
    let text: String

    init(id: UUID = UUID(), timestamp: Date = Date(), imagePath: String, text: String) {
        self.id = id
        self.timestamp = timestamp
        self.imagePath = imagePath
        self.text = text
    }
}
