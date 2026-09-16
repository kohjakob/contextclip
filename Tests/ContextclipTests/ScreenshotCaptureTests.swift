import XCTest
@testable import Contextclip

final class ScreenshotCaptureTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("contextclip-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }

    func testFileNameMatchesBuiltInScreenshotTool() {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 16
        components.hour = 14
        components.minute = 5
        components.second = 9
        let date = Calendar.current.date(from: components)!

        XCTAssertEqual(ScreenshotCapture.fileName(for: date), "Screenshot 2026-09-16 at 14.05.09")
    }

    func testStoreMovesCaptureIntoFolderAndAvoidsCollisions() throws {
        let workDirectory = try temporaryDirectory()
        let folder = workDirectory.appendingPathComponent("shots", isDirectory: true)
        let now = Date()

        let firstCapture = workDirectory.appendingPathComponent("one.png")
        let secondCapture = workDirectory.appendingPathComponent("two.png")
        try Data("one".utf8).write(to: firstCapture)
        try Data("two".utf8).write(to: secondCapture)

        let first = try ScreenshotCapture.store(firstCapture, in: folder, now: now)
        let second = try ScreenshotCapture.store(secondCapture, in: folder, now: now)

        XCTAssertEqual(first.lastPathComponent, ScreenshotCapture.fileName(for: now) + ".png")
        XCTAssertEqual(second.lastPathComponent, ScreenshotCapture.fileName(for: now) + " (2).png")
        XCTAssertFalse(FileManager.default.fileExists(atPath: firstCapture.path))
        XCTAssertEqual(try String(contentsOf: second, encoding: .utf8), "two")
    }
}
