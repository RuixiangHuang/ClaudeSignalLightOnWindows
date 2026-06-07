const fs = require("fs");
const os = require("os");
const path = require("path");

const settingsPath =
  process.argv[2] || path.join(os.homedir(), ".claude", "settings.json");

if (!fs.existsSync(settingsPath)) {
  throw new Error(`Claude settings file was not found: ${settingsPath}`);
}

const settings = JSON.parse(
  fs.readFileSync(settingsPath, "utf8").replace(/^\uFEFF/, ""),
);
const timestamp = new Date().toISOString().replace(/[-:T]/g, "").slice(0, 14);
const backupPath = `${settingsPath}.claude-signal-light-backup-${timestamp}`;
fs.copyFileSync(settingsPath, backupPath);

function isSignalLightHook(hook) {
  const args = Array.isArray(hook?.args) ? hook.args : [];
  return args.some((argument) =>
    String(argument).replaceAll("\\", "/").endsWith("/macos/hooks/claude-hook.js"),
  );
}

for (const [eventName, groups] of Object.entries(settings.hooks || {})) {
  settings.hooks[eventName] = (Array.isArray(groups) ? groups : [])
    .map((group) => ({
      ...group,
      hooks: Array.isArray(group.hooks)
        ? group.hooks.filter((hook) => !isSignalLightHook(hook))
        : [],
    }))
    .filter((group) => group.hooks.length > 0);

  if (settings.hooks[eventName].length === 0) {
    delete settings.hooks[eventName];
  }
}

if (settings.hooks && Object.keys(settings.hooks).length === 0) {
  delete settings.hooks;
}

fs.writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`, "utf8");
console.log(`Claude Signal Light hooks removed: ${settingsPath}`);
console.log(`Backup created: ${backupPath}`);
