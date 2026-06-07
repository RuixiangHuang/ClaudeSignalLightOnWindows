# Claude Signal Light for macOS

A native SwiftUI menu bar app for Claude Code CLI and Cursor's official
Claude Code extension.

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools with Swift 5.9 or later
- Node.js available through `node`
- Claude Code CLI or Cursor's official `anthropic.claude-code` extension

## Status

- Green: Claude is working
- Yellow, pulsing: Claude needs permission or user input
- Red: Claude finished the current response

The menu shows the selected project, Session ID, status message, language,
notification sound, manual refresh, and Quit.

## Build

```bash
cd macos
chmod +x build-app.sh run-debug.sh install-claude-hooks.sh \
  uninstall-claude-hooks.sh
./build-app.sh
```

The app is created at:

```text
macos/dist/Claude Signal Light.app
```

Move it to `/Applications` if desired, then launch it normally.

For development:

```bash
./run-debug.sh
```

## Install Claude Hooks

Keep this repository at a stable path, then run:

```bash
./install-claude-hooks.sh
```

Restart Claude Code or Cursor after installation.

The installer:

- backs up `~/.claude/settings.json`
- preserves Hooks installed by other tools
- records the absolute Node.js executable path used during installation

Runtime data is stored locally in:

```text
~/Library/Application Support/ClaudeSignalLight/
```

## Uninstall Hooks

```bash
./uninstall-claude-hooks.sh
```

This removes only Claude Signal Light's Hook entries.

## Preferences

The menu supports English and Simplified Chinese. Notification sounds include
Glass, Ping, Pop, Submarine, and None. Selecting a sound plays a preview.

Preferences are stored by macOS `UserDefaults`.

## Privacy

Claude lifecycle events are processed locally. The app and Hook do not send
data over the network.
