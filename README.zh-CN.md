# Code Agent Light

[English](README.md) | [简体中文](README.zh-CN.md)

一款适用于 Windows 的桌面红绿灯组件，用于显示 Claude Code CLI
以及 Cursor 官方 `anthropic.claude-code` 扩展的当前状态。

## 环境要求

- Windows 10 或 Windows 11
- Windows PowerShell 5.1
- 已安装 Node.js，并可通过 `node.exe` 运行
- Claude Code CLI 或 Cursor 官方 Claude Code 扩展

## 灯光状态

- 绿灯：Agent 正在执行任务
- 黄灯：Agent 等待用户授权或输入
- 红灯：Agent 已完成当前回复

黄灯会持续显示，直到 Claude 发出下一个执行事件。组件不会通过键盘事件
或计时器猜测用户是否已经完成操作。

状态切换为黄灯时，灯光会进行呼吸闪烁，并播放一次 Windows 提示音。
保持黄灯期间不会重复播放提示音。

## 快速开始

1. 双击 `install-claude-hooks.cmd` 安装 Hooks。
2. 完全重启 Cursor 或 Claude Code。
3. 双击 `start-widget.cmd` 启动桌面组件。

安装程序会为 `~/.claude/settings.json` 创建带时间戳的备份，并保留其他
工具已经安装的 Hooks。

组件默认显示在屏幕右下角：

- 按住鼠标左键拖动组件
- 鼠标悬停查看项目名称、Session ID 和状态
- 单击鼠标右键关闭组件

## Cursor 支持

本项目支持 Cursor 中的官方 Claude Code 扩展：

```text
anthropic.claude-code
```

Cursor 自带的 Agent 或 Chat 即使选择了 Claude 模型，也不使用 Claude Code
Hooks，因此不在支持范围内。

## 项目结构

```text
codeagent-light/
|-- start-widget.cmd           启动桌面组件
|-- start-widget-debug.cmd     显示错误窗口并启动组件
|-- install-claude-hooks.cmd   安装 Claude Code Hooks
|-- uninstall-claude-hooks.cmd 仅卸载本项目的 Hooks
|-- demo.cmd                   可选的红绿灯演示
|-- set-status.cmd             可选的手动状态命令
|-- app/
|   `-- CodeAgentLight.ps1     WPF 桌面组件
|-- hooks/
|   `-- claude-hook.js         接收 UTF-8 Claude Hook 事件
|-- tools/
|   |-- configure-claude-hooks.js
|   |-- remove-claude-hooks.js
|   |-- demo.ps1
|   `-- set-status.ps1
`-- runtime/                   自动生成的状态和日志
```

## 必要文件

正常检测 Claude 状态需要保留：

- `start-widget.cmd`
- `app/CodeAgentLight.ps1`
- `hooks/claude-hook.js`
- `install-claude-hooks.cmd`
- `tools/configure-claude-hooks.js`

`demo` 和 `set-status` 文件仅用于演示或手动测试，可以不使用。

`runtime/` 中的文件均为运行时自动生成。在关闭组件和 Claude Code 后，
可以安全删除这些文件。

## 多 Session 处理

每个 Claude Session 都会按照 `session_id` 单独记录。当多个 Session
同时存在时，组件按以下优先级显示：

1. 等待用户操作的 Session：黄灯
2. 正在运行的 Session：绿灯
3. 已完成的 Session：红灯

鼠标悬停在组件上，可以查看当前显示的项目名称和 Session ID。

## 手动设置状态

```bat
set-status.cmd running "Agent 正在工作"
set-status.cmd waiting "需要用户授权"
set-status.cmd done "任务已完成"
```

双击 `demo.cmd` 可以依次演示绿灯、黄灯和红灯。

## 卸载

1. 右键单击组件将其关闭。
2. 双击 `uninstall-claude-hooks.cmd`。
3. 如果不再需要，可以删除整个项目目录。

卸载程序只会删除本项目安装的 Hooks，不会删除其他工具的 Hooks。

## 隐私说明

Hook 只在本地读取 Claude 的生命周期事件 JSON，用于判断 Session、项目和
运行状态。项目不会将任何数据发送到网络。

运行状态和日志存放在已被 Git 忽略的 `runtime/` 目录中。

## 问题排查

如果组件无法显示，请运行：

```text
start-widget-debug.cmd
```

诊断文件位于：

```text
runtime/widget.log
runtime/claude-hook.log
runtime/claude-sessions.json
runtime/status.json
```

如果 Hooks 没有触发，请确认：

1. 已运行 `install-claude-hooks.cmd`。
2. 安装后已经完全重启 Cursor 或 Claude Code。
3. 使用的是 Claude Code CLI 或 Cursor 官方 Claude Code 扩展。
4. `node.exe` 可以在命令行中正常运行。

## 许可证

MIT
