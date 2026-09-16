import AppKit

enum AppActivation {
    /// Brings this accessory app forward so panels and the settings window open above other apps.
    static func bringToFront() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
