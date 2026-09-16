# Contextclip

Menu bar app for macOS: press a hotkey, drag a rectangle over anything on screen, and the text
in it lands on your clipboard. Recognition runs on device through Apple's Vision framework, so
nothing leaves your Mac.

## Features

- Global hotkey (default `⇧⌘X`), changeable from Settings by pressing the new combination
- Uses the native region selector, so it feels like the built-in screenshot tool
- On-device OCR with automatic language detection
- Keeps the last 50 captures in the menu; click one to copy it again
- Saves every screenshot to a folder of your choice (default `~/Pictures/Screenshots`)
- Optional launch at login
- No Accessibility permission needed for the hotkey

## Requirements

- macOS 13 or later
- Xcode 15 or later and [xcodegen](https://github.com/yonaskolb/XcodeGen) to build

## Install

```bash
brew install xcodegen
make install
```

`make install` generates the Xcode project, builds a Release app, copies it to `/Applications`
and launches it. Other targets: `make build`, `make test`, `make run`, `make clean`.

## Permissions

On first capture macOS asks for Screen Recording permission. Grant it under
System Settings > Privacy & Security > Screen Recording, then capture again. Without it the
selector still works but the image comes out blank.

Launch at login is registered through `SMAppService`, which ties the login item to the app's
location. Keep the app in `/Applications` if you enable it.

## Where things go

| What | Where |
| --- | --- |
| Screenshots | The folder chosen in Settings > Storage |
| Capture history | `~/Library/Application Support/Contextclip/history.json` |
| Preferences | `~/Library/Preferences/com.kohjakob.contextclip.plist` |

## Development

```bash
make test
```

Sources live in `Sources/Contextclip`, tests in `Tests/ContextclipTests`. The Xcode project is
generated from `project.yml` and is not checked in.

The app icon is the menu bar symbol on a white rounded square. `make icon` re-renders every size
into `Resources/Assets.xcassets` from `Scripts/make-icon.swift`.
