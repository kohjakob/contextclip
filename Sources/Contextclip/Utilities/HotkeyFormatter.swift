import Carbon.HIToolbox
import Foundation

/// Renders a hotkey the way macOS menus do, for example "⇧⌘X".
enum HotkeyFormatter {
    static func string(for hotkey: Hotkey) -> String {
        modifierSymbols(for: hotkey.modifiers) + keyName(for: hotkey)
    }

    /// Modifier glyphs in the order macOS menus use: Control, Option, Shift, Command.
    static func modifierSymbols(for modifiers: UInt32) -> String {
        var symbols = ""
        if modifiers & UInt32(controlKey) != 0 { symbols += "⌃" }
        if modifiers & UInt32(optionKey) != 0 { symbols += "⌥" }
        if modifiers & UInt32(shiftKey) != 0 { symbols += "⇧" }
        if modifiers & UInt32(cmdKey) != 0 { symbols += "⌘" }
        return symbols
    }

    static func keyName(for hotkey: Hotkey) -> String {
        if let special = specialKeyNames[Int(hotkey.keyCode)] {
            return special
        }
        if let character = hotkey.character, !character.isEmpty {
            return character
        }
        return "Key \(hotkey.keyCode)"
    }

    private static let specialKeyNames: [Int: String] = [
        kVK_Space: "Space",
        kVK_Return: "↩",
        kVK_Tab: "⇥",
        kVK_Delete: "⌫",
        kVK_ForwardDelete: "⌦",
        kVK_Escape: "⎋",
        kVK_LeftArrow: "←",
        kVK_RightArrow: "→",
        kVK_UpArrow: "↑",
        kVK_DownArrow: "↓",
        kVK_Home: "↖",
        kVK_End: "↘",
        kVK_PageUp: "⇞",
        kVK_PageDown: "⇟",
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4",
        kVK_F5: "F5", kVK_F6: "F6", kVK_F7: "F7", kVK_F8: "F8",
        kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]
}
