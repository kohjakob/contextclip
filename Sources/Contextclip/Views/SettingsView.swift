import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }
            HotkeySettingsView()
                .tabItem { Label("Hotkey", systemImage: "keyboard") }
            StorageSettingsView()
                .tabItem { Label("Storage", systemImage: "folder") }
        }
        .frame(width: 460, height: 260)
    }
}

private struct GeneralSettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Toggle("Launch at login", isOn: $settings.launchAtLogin)
            if let error = settings.launchAtLoginError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            LabeledContent("Version", value: Bundle.main.versionString)
        }
        .formStyle(.grouped)
    }
}

private struct HotkeySettingsView: View {
    var body: some View {
        Form {
            LabeledContent("Capture shortcut") {
                HotkeyRecorderView()
            }
            Text("Click Change, then press the new combination. Escape cancels. Command, Option or Control is required.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }
}

private struct StorageSettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var history: HistoryStore

    var body: some View {
        Form {
            LabeledContent("Screenshot folder") {
                HStack {
                    Text(settings.screenshotFolder.path)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose…") { chooseFolder() }
                    Button("Reveal") { revealFolder() }
                }
            }
            LabeledContent("History") {
                HStack {
                    Text("\(history.items.count) of \(history.maxItems) entries")
                    Button("Clear") { history.clear() }
                        .disabled(history.items.isEmpty)
                }
            }
            Text("Every capture is saved as a PNG in the folder above. Recognised text is kept in history.json under Application Support.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private func chooseFolder() {
        AppActivation.bringToFront()
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.directoryURL = settings.screenshotFolder
        panel.prompt = "Choose"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        settings.screenshotFolder = url
    }

    private func revealFolder() {
        try? FileManager.default.createDirectory(at: settings.screenshotFolder, withIntermediateDirectories: true)
        NSWorkspace.shared.open(settings.screenshotFolder)
    }
}
