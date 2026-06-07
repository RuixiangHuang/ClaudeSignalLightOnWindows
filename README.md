# Code Agent Light

[English](README.md) | [简体中文](README.zh-CN.md)

Cross-platform status light for Claude Code CLI and Cursor's official
`anthropic.claude-code` extension, with native Windows and macOS interfaces.

## Platforms

| Platform | Interface | Documentation |
| --- | --- | --- |
| Windows | WPF desktop widget and system tray | This README |
| macOS 13+ | Native SwiftUI menu bar app | [macOS guide](macos/README.md) |

Both platforms use the same Claude lifecycle states and multi-session
priority: waiting, running, then done.

## Windows Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Node.js available as `node.exe`
- Claude Code CLI or Cursor's official Claude Code extension

## Light states
<img width="1521" height="1053" alt="eb7be9e8996450ddf45c36559892e2c3" src="https://github.com/user-attachments/assets/6e03387b-982f-49be-8805-42fdb6a31c87" />
- Green: the agent is working
- Yellow: the agent needs permission or user input
- Red: the response is complete

Yellow stays active until Claude emits another execution event. It does not
guess based on keyboard input or a timer.

When the state changes to yellow, the light breathes and Windows plays one
notification chime. The sound is not repeated while the state remains yellow.

## Quick start

1. Double-click `install-claude-hooks.cmd` once.
2. Restart Cursor or Claude Code.
3. Double-click `start-widget.cmd`.

The installer creates a timestamped backup of `~/.claude/settings.json` and
preserves Hooks installed by other tools.

Drag the widget with the left mouse button. Hover to see the project and
session ID. Right-click the widget to hide it in the Windows notification
area. Double-click the tray icon to restore it. Use the tray icon's `Exit`
menu item to stop the app completely.

Use the tray icon's `Language` submenu to switch between English and
Simplified Chinese. The selection is remembered for the next launch.

The tray icon is a compact traffic light and follows the current red, yellow,
or green agent state.

Use the `Notification Sound` submenu to choose Ding, Chord, Chimes, Notify,
or None. These use distinct files from `Windows\Media` rather than Windows
sound-scheme event mappings. Selecting a sound plays a preview, and the choice
is remembered for the next launch.

## Project structure

```text
codeagent-light/
|-- start-widget.cmd          Start the desktop widget
|-- start-widget-debug.cmd    Start with a visible error console
|-- install-claude-hooks.cmd  Connect Claude Code to the widget
|-- uninstall-claude-hooks.cmd Remove only this project's hooks
|-- demo.cmd                  Optional traffic-light demo
|-- set-status.cmd            Optional manual status command
|-- app/
|   |-- CodeAgentLight.ps1    WPF desktop widget
|   `-- translations.json     Tray menu and status translations
|-- hooks/
|   `-- claude-hook.js        Receives UTF-8 Claude hook events
|-- tools/
|   |-- configure-claude-hooks.js
|   |-- remove-claude-hooks.js
|   |-- demo.ps1
|   `-- set-status.ps1
|-- runtime/                  Generated state and logs
`-- macos/                    Native macOS menu bar implementation
```

## Required files

For normal Claude detection, these files are required:

- `start-widget.cmd`
- `app/CodeAgentLight.ps1`
- `app/translations.json`
- `hooks/claude-hook.js`
- `install-claude-hooks.cmd`
- `tools/configure-claude-hooks.js`

The `demo` and `set-status` files are optional utilities.

Files under `runtime/` are generated automatically and can be deleted while
the widget and Claude Code are closed.

## Uninstall

1. Right-click the tray icon and select `Exit`.
2. Double-click `uninstall-claude-hooks.cmd`.
3. Delete the project folder if it is no longer needed.

## Privacy

The Hook reads Claude lifecycle event JSON locally to determine session,
project, and status. It does not send data over the network. Runtime state and
logs remain in the ignored `runtime/` directory.

## Manual status

```bat
set-status.cmd running "Agent is working"
set-status.cmd waiting "Approval required"
set-status.cmd done "Task completed"
```

## Troubleshooting

Run `start-widget-debug.cmd` if the widget does not appear.

Generated diagnostics:

```text
runtime/widget.log
runtime/claude-hook.log
runtime/claude-sessions.json
runtime/status.json
```

## License

MIT
