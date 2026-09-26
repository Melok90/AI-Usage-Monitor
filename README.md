# AI Usage Monitor

A native macOS menu bar application to monitor your AI agents' usage and rate limits at a glance.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## Features

- **Menu Bar Status Indicator**: Displays a clean `[AI] 16%` badge showing the lowest remaining percentage quota among your active AI agents.
- **Claude Code Integration**:
  - **5-Hour Session Quota**: Real-time remaining percentage, countdown timer, and high-contrast segmented progress bar.
  - **7-Day Usage Quota**: Weekly remaining quota with countdown to reset.
- **In-Popover Agent Settings**:
  - Quick toggle support for multiple AI agents: **Claude Code**, **Antigravity**, **Gemini**, and **Codex**.
  - Persistent state saved via `UserDefaults`.
  - Seamless navigation within the popover.
- **Native macOS Design**:
  - Ultra-compact dark popover aesthetic.
  - Native SF Symbols and authentic brand icons.
  - Smooth 60fps animations and zero cruft.

## Requirements

- macOS 15.0 or later
- Xcode 16.0 or later

## Building & Running

Open `AI Usage Monitor.xcodeproj` in Xcode and press `Cmd + R`, or build via command line:

```bash
xcodebuild -scheme "AI Usage Monitor" -destination "platform=macOS" clean build
```

## License

MIT License.
