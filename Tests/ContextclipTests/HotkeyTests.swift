import Carbon.HIToolbox
import XCTest
@testable import Contextclip

final class HotkeyTests: XCTestCase {
    func testModifierSymbolsFollowMenuOrder() {
        let all = UInt32(cmdKey | shiftKey | optionKey | controlKey)
        XCTAssertEqual(HotkeyFormatter.modifierSymbols(for: all), "⌃⌥⇧⌘")
        XCTAssertEqual(HotkeyFormatter.modifierSymbols(for: UInt32(cmdKey)), "⌘")
        XCTAssertEqual(HotkeyFormatter.modifierSymbols(for: 0), "")
    }

    func testSpecialKeysAreNamedByKeyCode() {
        XCTAssertEqual(HotkeyFormatter.keyName(for: hotkey(kVK_Space, character: " ")), "Space")
        XCTAssertEqual(HotkeyFormatter.keyName(for: hotkey(kVK_F5, character: nil)), "F5")
        XCTAssertEqual(HotkeyFormatter.keyName(for: hotkey(kVK_Escape, character: nil)), "⎋")
    }

    func testOtherKeysUseRecordedCharacterOrFallBack() {
        XCTAssertEqual(HotkeyFormatter.keyName(for: hotkey(kVK_ANSI_O, character: "O")), "O")
        XCTAssertEqual(HotkeyFormatter.keyName(for: hotkey(kVK_ANSI_O, character: nil)), "Key 31")
    }

    func testDefaultHotkeyRendersAsShiftCommandX() {
        XCTAssertEqual(Hotkey.default.displayString, "⇧⌘X")
    }

    func testHotkeyFromEventKeepsKeyCodeAndModifiers() throws {
        let event = try XCTUnwrap(makeKeyDown(keyCode: UInt16(kVK_ANSI_X), modifiers: [.command, .shift]))

        let hotkey = try XCTUnwrap(Hotkey(event: event))

        XCTAssertEqual(hotkey.keyCode, UInt32(kVK_ANSI_X))
        XCTAssertEqual(hotkey.modifiers, UInt32(cmdKey | shiftKey))
        XCTAssertEqual(hotkey.character, "X")
    }

    func testHotkeyFromEventDropsNonPrintableCharacters() throws {
        let arrow = try XCTUnwrap(makeKeyDown(keyCode: UInt16(kVK_LeftArrow), modifiers: [.command], characters: "\u{F702}"))

        let hotkey = try XCTUnwrap(Hotkey(event: arrow))

        XCTAssertNil(hotkey.character)
        XCTAssertEqual(hotkey.displayString, "⌘←")
    }

    func testHotkeyFromEventRejectsBareAndShiftOnlyKeys() throws {
        let bare = try XCTUnwrap(makeKeyDown(keyCode: UInt16(kVK_ANSI_X), modifiers: []))
        let shiftOnly = try XCTUnwrap(makeKeyDown(keyCode: UInt16(kVK_ANSI_X), modifiers: [.shift]))

        XCTAssertNil(Hotkey(event: bare))
        XCTAssertNil(Hotkey(event: shiftOnly))
    }

    private func hotkey(_ keyCode: Int, character: String?) -> Hotkey {
        Hotkey(keyCode: UInt32(keyCode), modifiers: UInt32(cmdKey), character: character)
    }

    private func makeKeyDown(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, characters: String = "x") -> NSEvent? {
        NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: modifiers,
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode
        )
    }
}
