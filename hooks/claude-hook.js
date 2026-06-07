const fs = require("fs");
const path = require("path");

const runtimePath = path.join(__dirname, "..", "runtime");
fs.mkdirSync(runtimePath, { recursive: true });
const sessionsPath = path.join(runtimePath, "claude-sessions.json");
const statusPath = path.join(runtimePath, "status.json");
const hookLogPath = path.join(runtimePath, "claude-hook.log");
const lockPath = path.join(runtimePath, ".claude-hook-lock");

function log(message) {
  fs.appendFileSync(hookLogPath, `${new Date().toISOString()} ${message}\n`, "utf8");
}

function sleep(milliseconds) {
  Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, milliseconds);
}

function acquireLock() {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    try {
      fs.mkdirSync(lockPath);
      return true;
    } catch (error) {
      if (error.code !== "EEXIST") {
        throw error;
      }
      sleep(25);
    }
  }
  return false;
}

function writeJsonAtomic(filePath, value) {
  const temporaryPath = `${filePath}.tmp.${process.pid}`;
  fs.writeFileSync(temporaryPath, `${JSON.stringify(value, null, 2)}\n`, "utf8");
  fs.renameSync(temporaryPath, filePath);
}

function readSessions() {
  try {
    return JSON.parse(fs.readFileSync(sessionsPath, "utf8"));
  } catch {
    return {};
  }
}

function eventState(event) {
  switch (event.hook_event_name) {
    case "SessionStart":
      return ["done", "Claude session ready"];
    case "UserPromptSubmit":
      return ["running", "Claude is processing a prompt"];
    case "PreToolUse":
      return ["running", `Claude is using ${event.tool_name || "a tool"}`];
    case "PostToolUse":
      return ["running", `Claude finished ${event.tool_name || "a tool"}`];
    case "PermissionRequest":
      return ["waiting", `Claude needs permission for ${event.tool_name || "a tool"}`];
    case "Elicitation":
      return ["waiting", "Claude needs user input"];
    case "Notification":
      if (["permission_prompt", "elicitation_dialog"].includes(event.notification_type)) {
        return ["waiting", event.message || "Claude needs user input"];
      }
      if (event.notification_type === "idle_prompt") {
        return ["done", "Claude is waiting for the next prompt"];
      }
      return null;
    case "Stop":
    case "StopFailure":
      return ["done", "Claude finished responding"];
    case "SessionEnd":
      return ["done", "Claude session ended"];
    default:
      return null;
  }
}

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => {
  input += chunk;
});

process.stdin.on("end", () => {
  let event;
  try {
    event = JSON.parse(input);
  } catch (error) {
    log(`invalid JSON: ${error.message}`);
    return;
  }

  const sessionId = String(event.session_id || "claude-unknown");
  const state = eventState(event);
  log(`event=${event.hook_event_name || ""} session=${sessionId}`);

  if (!state || !acquireLock()) {
    return;
  }

  try {
    const [status, message] = state;
    const sessions = readSessions();
    const updatedAt = new Date().toISOString();

    sessions[sessionId] = {
      sessionId,
      cwd: String(event.cwd || ""),
      status,
      message,
      event: String(event.hook_event_name || ""),
      updatedAt,
    };

    writeJsonAtomic(sessionsPath, sessions);

    const priority = { waiting: 3, running: 2, done: 1 };
    const selected = Object.values(sessions).sort((left, right) => {
      const priorityDifference = priority[right.status] - priority[left.status];
      return priorityDifference || Date.parse(right.updatedAt) - Date.parse(left.updatedAt);
    })[0];

    const project = selected.cwd ? path.basename(selected.cwd) : "Claude";
    writeJsonAtomic(statusPath, {
      status: selected.status,
      message: `${project} [${selected.sessionId.slice(0, 8)}]: ${selected.message}`,
      sessionId: selected.sessionId,
      cwd: selected.cwd,
      updatedAt,
      source: "claude-code",
    });
  } finally {
    fs.rmSync(lockPath, { recursive: true, force: true });
  }
});
