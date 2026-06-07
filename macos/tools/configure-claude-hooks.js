const fs = require("fs");
const os = require("os");
const path = require("path");

const projectRoot = path.join(__dirname, "..");
const hookScript = path.join(projectRoot, "hooks", "claude-hook.js");
const settingsPath =
  process.argv[2] || path.join(os.homedir(), ".claude", "settings.json");
const timestamp = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
const backupPath = `${settingsPath}.claude-signal-light-backup-${timestamp}`;
const events = [
  "SessionStart",
  "UserPromptSubmit",
  "PreToolUse",
  "PostToolUse",
  "PermissionRequest",
  "Elicitation",
  "Notification",
  "Stop",
  "SessionEnd",
  "StopFailure",
];

fs.mkdirSync(path.dirname(settingsPath), { recursive: true });

let settings = {};
if (fs.existsSync(settingsPath)) {
  fs.copyFileSync(settingsPath, backupPath);
  settings = JSON.parse(fs.readFileSync(settingsPath, "utf8").replace(/^\uFEFF/, ""));
}

settings.hooks = settings.hooks || {};

function isSignalLightHook(hook) {
  if (!hook || hook.type !== "command") {
    return false;
  }
  const args = Array.isArray(hook.args) ? hook.args : [];
  return args.some((argument) =>
    String(argument).replaceAll("\\", "/").endsWith("/macos/hooks/claude-hook.js"),
  );
}

for (const eventName of events) {
  const existingGroups = Array.isArray(settings.hooks[eventName])
    ? settings.hooks[eventName]
    : [];
  const preservedGroups = existingGroups
    .map((group) => ({
      ...group,
      hooks: Array.isArray(group.hooks)
        ? group.hooks.filter((hook) => !isSignalLightHook(hook))
        : [],
    }))
    .filter((group) => group.hooks.length > 0);

  const group = {
    hooks: [
      {
        type: "command",
        command: process.execPath,
        args: [hookScript],
        timeout: 10,
      },
    ],
  };

  if (eventName === "Notification") {
    group.matcher = "";
  }

  settings.hooks[eventName] = [...preservedGroups, group];
}

fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, "utf8");
console.log(`Claude hooks configured: ${settingsPath}`);
if (fs.existsSync(backupPath)) {
  console.log(`Backup created: ${backupPath}`);
}
