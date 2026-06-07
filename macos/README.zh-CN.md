# Claude Signal Light macOS 版

这是一个原生 SwiftUI 菜单栏应用，支持 Claude Code CLI 和 Cursor 官方
Claude Code 扩展。

## 环境要求

- macOS 13 Ventura 或更高版本
- 包含 Swift 5.9 或更高版本的 Xcode Command Line Tools
- 可以通过 `node` 运行 Node.js
- Claude Code CLI 或 Cursor 官方 `anthropic.claude-code` 扩展

## 状态显示

- 绿灯：Claude 正在工作
- 呼吸黄灯：Claude 等待授权或用户输入
- 红灯：Claude 已完成当前回复

菜单中会显示项目、Session ID、状态信息、语言、提示音、手动刷新和退出。

## 构建

```bash
cd macos
chmod +x build-app.sh run-debug.sh install-claude-hooks.sh \
  uninstall-claude-hooks.sh
./build-app.sh
```

构建结果：

```text
macos/dist/Claude Signal Light.app
```

可以将应用移动到 `/Applications` 后正常启动。

开发运行：

```bash
./run-debug.sh
```

## 安装 Claude Hooks

请将仓库保存在稳定路径，然后运行：

```bash
./install-claude-hooks.sh
```

安装后完全重启 Claude Code 或 Cursor。

安装程序会：

- 备份 `~/.claude/settings.json`
- 保留其他工具已经安装的 Hooks
- 记录安装时使用的 Node.js 绝对路径，避免 Cursor GUI 的 PATH 问题

运行数据保存在：

```text
~/Library/Application Support/ClaudeSignalLight/
```

## 卸载 Hooks

```bash
./uninstall-claude-hooks.sh
```

卸载程序只会删除 Claude Signal Light 的 Hook。

## 偏好设置

菜单支持 English 和简体中文。提示音包括 Glass、Ping、Pop、Submarine
和静音，选择提示音时会立即试听。

偏好设置由 macOS `UserDefaults` 保存。

## 隐私

Claude 生命周期事件只在本地处理，应用和 Hook 不会向网络发送数据。
