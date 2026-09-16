import Foundation

/// Launch-at-login as seen by settings, so it can be faked in tests.
protocol LoginItemService {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

@MainActor
final class AppSettings: ObservableObject {
    enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyCharacter = "hotkeyCharacter"
        static let screenshotFolder = "screenshotFolder"
    }

    nonisolated static let defaultScreenshotFolder = FileManager.default
        .homeDirectoryForCurrentUser
        .appendingPathComponent("Pictures/Screenshots", isDirectory: true)

    @Published var hotkey: Hotkey {
        didSet {
            defaults.set(Int(hotkey.keyCode), forKey: Keys.hotkeyKeyCode)
            defaults.set(Int(hotkey.modifiers), forKey: Keys.hotkeyModifiers)
            defaults.set(hotkey.character, forKey: Keys.hotkeyCharacter)
        }
    }

    @Published var screenshotFolder: URL {
        didSet {
            defaults.set(screenshotFolder.path, forKey: Keys.screenshotFolder)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard !isRevertingLaunchAtLogin, launchAtLogin != oldValue else { return }
            do {
                try loginItems.setEnabled(launchAtLogin)
                launchAtLoginError = nil
            } catch {
                launchAtLoginError = error.localizedDescription
                isRevertingLaunchAtLogin = true
                launchAtLogin = oldValue
                isRevertingLaunchAtLogin = false
            }
        }
    }

    /// True while the hotkey recorder is listening. The coordinator releases the global hotkey meanwhile.
    @Published var isRecordingHotkey = false

    @Published private(set) var launchAtLoginError: String?

    private let defaults: UserDefaults
    private let loginItems: LoginItemService
    private var isRevertingLaunchAtLogin = false

    init(defaults: UserDefaults = .standard, loginItems: LoginItemService = AutostartManager()) {
        self.defaults = defaults
        self.loginItems = loginItems

        if let keyCode = defaults.object(forKey: Keys.hotkeyKeyCode) as? Int,
           let modifiers = defaults.object(forKey: Keys.hotkeyModifiers) as? Int {
            hotkey = Hotkey(
                keyCode: UInt32(keyCode),
                modifiers: UInt32(modifiers),
                character: defaults.string(forKey: Keys.hotkeyCharacter)
            )
        } else {
            hotkey = .default
        }

        if let path = defaults.string(forKey: Keys.screenshotFolder) {
            screenshotFolder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            screenshotFolder = Self.defaultScreenshotFolder
        }

        launchAtLogin = loginItems.isEnabled
    }
}
