import SwiftUI

struct MenuBarMenuView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var history: HistoryStore

    private let visibleHistoryCount = 10
    private let labelLimit = 48

    var body: some View {
        Button("Capture Text  \(settings.hotkey.displayString)") {
            AppCoordinator.shared.captureAndRecognize()
        }

        Divider()

        if history.items.isEmpty {
            Text("No history yet")
        } else {
            ForEach(history.items.prefix(visibleHistoryCount)) { item in
                Button(label(for: item)) {
                    Clipboard.copy(item.text)
                }
            }
            Divider()
            Button("Clear History") {
                history.clear()
            }
        }

        Divider()

        settingsButton

        Button("Quit Contextclip") {
            NSApp.terminate(nil)
        }
    }

    @ViewBuilder
    private var settingsButton: some View {
        if #available(macOS 14.0, *) {
            SettingsMenuButton()
        } else {
            Button("Settings…") {
                AppActivation.bringToFront()
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
    }

    private func label(for item: HistoryItem) -> String {
        let firstLine = item.text
            .split(whereSeparator: \.isNewline)
            .first
            .map(String.init) ?? ""
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > labelLimit else { return trimmed }
        return String(trimmed.prefix(labelLimit)) + "…"
    }
}

@available(macOS 14.0, *)
private struct SettingsMenuButton: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Settings…") {
            AppActivation.bringToFront()
            openSettings()
        }
    }
}
