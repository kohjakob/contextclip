PROJECT := Contextclip.xcodeproj
SCHEME := Contextclip
BUILD_DIR := build
APP := $(BUILD_DIR)/Build/Products/Release/Contextclip.app

.PHONY: generate build test run install icon clean

generate:
	xcodegen generate

build: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -configuration Release -derivedDataPath $(BUILD_DIR) build

test: generate
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination 'platform=macOS' -derivedDataPath $(BUILD_DIR) test

run: build
	open "$(APP)"

install: build
	rm -rf /Applications/Contextclip.app
	cp -R "$(APP)" /Applications/Contextclip.app
	open /Applications/Contextclip.app

icon:
	swift Scripts/make-icon.swift

clean:
	rm -rf $(BUILD_DIR) $(PROJECT)
