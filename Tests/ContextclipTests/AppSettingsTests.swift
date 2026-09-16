import Carbon.HIToolbox
import XCTest
@testable import Contextclip

private final class FakeLoginItems: LoginItemService {
    var isEnabled = false
    var shouldFail = false

    struct Failure: LocalizedError {
        var errorDescription: String? { "login item refused" }
    }

    func setEnabled(_ enabled: Bool) throws {
        if shouldFail { throw Failure() }
        isEnabled = enabled
    }
}

@MainActor
final class AppSettingsTests: XCTestCase {
    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "contextclip-tests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    func testFreshDefaultsUseBuiltInValues() throws {
        let settings = AppSettings(defaults: try makeDefaults(), loginItems: FakeLoginItems())

        XCTAssertEqual(settings.hotkey, .default)
        XCTAssertEqual(settings.screenshotFolder, AppSettings.defaultScreenshotFolder)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.isRecordingHotkey)
    }

    func testHotkeyAndFolderPersistAcrossInstances() throws {
        let defaults = try makeDefaults()
        let folder = URL(fileURLWithPath: "/tmp/contextclip-shots", isDirectory: true)
        let hotkey = Hotkey(keyCode: UInt32(kVK_ANSI_O), modifiers: UInt32(cmdKey | optionKey), character: "O")

        let first = AppSettings(defaults: defaults, loginItems: FakeLoginItems())
        first.hotkey = hotkey
        first.screenshotFolder = folder

        let second = AppSettings(defaults: defaults, loginItems: FakeLoginItems())
        XCTAssertEqual(second.hotkey, hotkey)
        XCTAssertEqual(second.screenshotFolder.path, folder.path)
    }

    func testLaunchAtLoginReflectsAndDrivesTheService() throws {
        let loginItems = FakeLoginItems()
        loginItems.isEnabled = true
        let settings = AppSettings(defaults: try makeDefaults(), loginItems: loginItems)

        XCTAssertTrue(settings.launchAtLogin)

        settings.launchAtLogin = false
        XCTAssertFalse(loginItems.isEnabled)
        XCTAssertNil(settings.launchAtLoginError)
    }

    func testLaunchAtLoginRevertsWhenServiceFails() throws {
        let loginItems = FakeLoginItems()
        loginItems.shouldFail = true
        let settings = AppSettings(defaults: try makeDefaults(), loginItems: loginItems)

        settings.launchAtLogin = true

        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(loginItems.isEnabled)
        XCTAssertEqual(settings.launchAtLoginError, "login item refused")
    }
}
