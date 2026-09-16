import AppKit
import Combine
import os

/// Owns the long lived objects and runs the capture pipeline:
/// hotkey -> region selector -> OCR -> clipboard -> screenshot folder -> history.
@MainActor
final class AppCoordinator {
    static let shared = AppCoordinator()

    let settings: AppSettings
    let history: HistoryStore

    private let hotkeyManager = HotkeyManager()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Contextclip", category: "AppCoordinator")
    private var cancellables = Set<AnyCancellable>()
    private var isCapturing = false

    private init() {
        settings = AppSettings()
        history = HistoryStore()
    }

    func start() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.captureAndRecognize()
        }

        // @Published fires before the property changes, so use the delivered value, not settings.hotkey.
        settings.$hotkey
            .dropFirst()
            .sink { [weak self] hotkey in
                guard let self, !self.settings.isRecordingHotkey else { return }
                self.registerHotkey(hotkey)
            }
            .store(in: &cancellables)

        // Release the global hotkey while the recorder listens, otherwise the new combination
        // would trigger a capture instead of being recorded.
        settings.$isRecordingHotkey
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] isRecording in
                guard let self else { return }
                if isRecording {
                    self.hotkeyManager.unregister()
                } else {
                    self.registerHotkey(self.settings.hotkey)
                }
            }
            .store(in: &cancellables)

        registerHotkey(settings.hotkey)
    }

    func captureAndRecognize() {
        guard !isCapturing else { return }
        isCapturing = true
        Task {
            defer { isCapturing = false }
            await runCapture()
        }
    }

    private func runCapture() async {
        do {
            guard let captureURL = try await ScreenshotCapture.captureInteractive() else {
                logger.info("Capture cancelled")
                return
            }
            let text = try await OCRService.recognizeText(in: captureURL)
            let savedURL = try ScreenshotCapture.store(captureURL, in: settings.screenshotFolder)

            guard !text.isEmpty else {
                logger.info("No text found in \(savedURL.lastPathComponent)")
                NSSound.beep()
                return
            }

            Clipboard.copy(text)
            history.add(HistoryItem(imagePath: savedURL.path, text: text))
        } catch {
            logger.error("Capture failed: \(error.localizedDescription)")
            NSSound.beep()
        }
    }

    private func registerHotkey(_ hotkey: Hotkey) {
        do {
            try hotkeyManager.register(hotkey)
        } catch {
            logger.error("Could not register \(hotkey.displayString): \(error.localizedDescription)")
        }
    }
}
