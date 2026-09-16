import Carbon.HIToolbox
import Foundation
import os

enum HotkeyError: LocalizedError {
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            return "RegisterEventHotKey failed with status \(status). Another app may already own this shortcut."
        }
    }
}

private let hotkeySignature: OSType = 0x4343_4C50 // "CCLP"
private let hotkeyIdentifier: UInt32 = 1

/// Registers one system wide hotkey through the Carbon hotkey API. Unlike an NSEvent global
/// monitor this needs no Accessibility permission and fires while any app has focus.
@MainActor
final class HotkeyManager {
    var onHotkeyPressed: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Contextclip", category: "HotkeyManager")

    init() {
        installEventHandler()
    }

    func register(_ hotkey: Hotkey) throws {
        unregister()
        var ref: EventHotKeyRef?
        let id = EventHotKeyID(signature: hotkeySignature, id: hotkeyIdentifier)
        let status = RegisterEventHotKey(hotkey.keyCode, hotkey.modifiers, id, GetApplicationEventTarget(), 0, &ref)
        guard status == noErr, let ref else {
            throw HotkeyError.registrationFailed(status)
        }
        hotKeyRef = ref
    }

    func unregister() {
        guard let hotKeyRef else { return }
        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }

    fileprivate func handleHotkeyPressed() {
        onHotkeyPressed?()
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
        if status != noErr {
            logger.error("InstallEventHandler failed with status \(status)")
        }
    }
}

/// Carbon calls this on the main thread for every hotkey event addressed to this process.
private func hotkeyEventHandler(
    _ callRef: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hotKeyID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotKeyID
    )
    guard status == noErr, hotKeyID.signature == hotkeySignature, hotKeyID.id == hotkeyIdentifier else {
        return OSStatus(eventNotHandledErr)
    }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    Task { @MainActor in
        manager.handleHotkeyPressed()
    }
    return noErr
}
