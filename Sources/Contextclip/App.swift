import SwiftUI

@main
struct ContextclipApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Contextclip", systemImage: "text.viewfinder") {
            MenuBarMenuView()
                .environmentObject(AppCoordinator.shared.settings)
                .environmentObject(AppCoordinator.shared.history)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(AppCoordinator.shared.settings)
                .environmentObject(AppCoordinator.shared.history)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppCoordinator.shared.start()
    }
}
