import Carbon.HIToolbox
import SwiftUI

/// Shows the current shortcut and, on request, listens for the next key combination to replace it.
struct HotkeyRecorderView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var monitor: Any?
    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(isRecording ? "Press shortcut…" : settings.hotkey.displayString)
                .font(.body.monospaced())
                .frame(minWidth: 120, alignment: .leading)
            Button(isRecording ? "Cancel" : "Change…") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        settings.isRecordingHotkey = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stopRecording()
                return nil
            }
            guard let hotkey = Hotkey(event: event) else {
                NSSound.beep()
                return nil
            }
            settings.hotkey = hotkey
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
        isRecording = false
        settings.isRecordingHotkey = false
    }
}
