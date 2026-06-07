const fs = require("fs");
const path = require("path");

const settingsPath = process.argv[2];
const projectRoot = path.join(__dirname, "..");
const hookScript = path.join(projectRoot, "hooks", "claude-hook.js");

if (!settingsPath) {
  throw new Error("Usage: node configure-claude-hooks.js <settings>");
}

const timestamp = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
const backupPath = `${settingsPath}.codeagent-light-backup-${timestamp}`;
fs.mkdirSync(path.dirname(settingsPath), { recursive: true });

let settings = {};
if (fs.existsSync(settingsPath)) {
  fs.copyFileSync(settingsPath, backupPath);
  settings = JSON.parse(fs.readFileSync(settingsPath, "utf8").replace(/^\uFEFF/, ""));
}

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

settings.hooks = settings.hooks || {};

function isCodeAgentLightHook(hook) {
  if (!hook || hook.type !== "command") {
    return false;
  }

  const args = Array.isArray(hook.args) ? hook.args : [];
  return args.some((argument) =>
    String(argument).replaceAll("\\", "/").endsWith("/hooks/claude-hook.js"),
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
        ? group.hooks.filter((hook) => !isCodeAgentLightHook(hook))
        : [],
    }))
    .filter((group) => group.hooks.length > 0);

  const group = {
    hooks: [
      {
        type: "command",
        command: "node.exe",
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
