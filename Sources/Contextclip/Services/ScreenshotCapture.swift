import Foundation

enum ScreenshotCaptureError: LocalizedError {
    case launchFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .launchFailed(let error):
            return "Could not start screencapture: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Could not save the screenshot: \(error.localizedDescription)"
        }
    }
}

enum ScreenshotCapture {
    private static let executable = URL(fileURLWithPath: "/usr/sbin/screencapture")

    /// Shows the system region selector and returns the PNG it wrote, or nil when the user cancelled.
    static func captureInteractive() async throws -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("contextclip-\(UUID().uuidString)")
            .appendingPathExtension("png")

        let process = Process()
        process.executableURL = executable
        process.arguments = ["-i", "-x", "-t", "png", url.path]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            process.terminationHandler = { _ in continuation.resume() }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ScreenshotCaptureError.launchFailed(error))
            }
        }

        // screencapture writes nothing on Escape, so an absent or empty file means "cancelled".
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? Int) ?? 0
        guard size > 0 else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return url
    }

    /// Moves a captured PNG into the screenshot folder, named like the built-in screenshot tool.
    static func store(_ captureURL: URL, in folder: URL, now: Date = Date()) throws -> URL {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            let destination = availableURL(in: folder, baseName: fileName(for: now), fileManager: fileManager)
            try fileManager.moveItem(at: captureURL, to: destination)
            return destination
        } catch {
            throw ScreenshotCaptureError.saveFailed(error)
        }
    }

    static func fileName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        return "Screenshot \(formatter.string(from: date))"
    }

    private static func availableURL(in folder: URL, baseName: String, fileManager: FileManager) -> URL {
        var candidate = folder.appendingPathComponent(baseName).appendingPathExtension("png")
        var counter = 2
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(baseName) (\(counter))").appendingPathExtension("png")
            counter += 1
        }
        return candidate
    }
}
