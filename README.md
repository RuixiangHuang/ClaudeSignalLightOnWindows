# Code Agent Light

[English](README.md) | [简体中文](README.zh-CN.md)

Windows desktop traffic light for Claude Code CLI and Cursor's official
`anthropic.claude-code` extension.

## Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1
- Node.js available as `node.exe`
- Claude Code CLI or Cursor's official Claude Code extension

## Light states

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
session ID. Right-click to close it.

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
|   `-- CodeAgentLight.ps1    WPF desktop widget
|-- hooks/
|   `-- claude-hook.js        Receives UTF-8 Claude hook events
|-- tools/
|   |-- configure-claude-hooks.js
|   |-- remove-claude-hooks.js
|   |-- demo.ps1
|   `-- set-status.ps1
`-- runtime/                  Generated state and logs
```

## Required files

For normal Claude detection, these files are required:

- `start-widget.cmd`
- `app/CodeAgentLight.ps1`
- `hooks/claude-hook.js`
- `install-claude-hooks.cmd`
- `tools/configure-claude-hooks.js`

The `demo` and `set-status` files are optional utilities.

Files under `runtime/` are generated automatically and can be deleted while
the widget and Claude Code are closed.

## Uninstall

1. Right-click the widget to close it.
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
