import AppKit
import Carbon.HIToolbox

/// A global shortcut in Carbon terms: a virtual key code plus a Carbon modifier mask.
struct Hotkey: Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
    /// What the key prints on its own, captured when the shortcut was recorded. Only used for display.
    var character: String?

    static let `default` = Hotkey(keyCode: UInt32(kVK_ANSI_X), modifiers: UInt32(cmdKey | shiftKey), character: "X")

    var displayString: String {
        HotkeyFormatter.string(for: self)
    }
}

extension Hotkey {
    /// Builds a hotkey from a key-down event. Returns nil unless Command, Option or Control is held,
    /// because a bare or shift-only key would hijack normal typing system wide.
    init?(event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }

        guard modifiers & ~UInt32(shiftKey) != 0 else { return nil }
        self.init(
            keyCode: UInt32(event.keyCode),
            modifiers: modifiers,
            character: Self.printableCharacter(from: event.charactersIgnoringModifiers)
        )
    }

    /// Keeps only characters worth showing in a label; arrows and function keys arrive as
    /// private-use code points and are named by key code instead.
    private static func printableCharacter(from characters: String?) -> String? {
        guard let characters, let scalar = characters.unicodeScalars.first else { return nil }
        let isControl = scalar.value < 0x20 || scalar.value == 0x7F
        let isPrivateUse = (0xE000...0xF8FF).contains(scalar.value)
        guard !isControl, !isPrivateUse else { return nil }
        return characters.uppercased()
    }
}
