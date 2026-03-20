# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**StereoCheck** is a macOS menu bar application written in Swift that monitors audio speaker channel configuration. It displays per-speaker settings in the menu bar and visually indicates (via icons) whether left/right channels are normal or swapped — eliminating the need to open Audio MIDI Setup manually.

- **Target platform**: macOS 26 Tahoe and later
- **Language**: Swift
- **Application type**: macOS menu bar extension

## Build & Run

This project uses the native macOS Swift compiler (no external package managers).

Once source files exist, build with:
```bash
swiftc -o StereoCheck *.swift
```

If an Xcode project is created:
```bash
xcodebuild -scheme StereoCheck build
xcodebuild -scheme StereoCheck test
```

If Swift Package Manager is used:
```bash
swift build
swift test
swift run
# Run a single test:
swift test --filter TestSuiteName/testMethodName
```

## Architecture

The app is a macOS menu bar extension. Expected structure:

- **Entry point**: `@main` struct or `AppDelegate` using `NSStatusBar` / `NSStatusItem` for the menu bar icon
- **Audio detection**: Uses Core Audio (`AudioObjectGetPropertyData`) or `AVFoundation` to query audio device channel layout and detect left/right swap
- **UI**: `NSMenu` populated with per-speaker entries; icons reflect channel state (normal vs. swapped)
