#!/bin/zsh
set -euo pipefail

SCRIPT_DIR=${0:A:h}
/usr/bin/env node "$SCRIPT_DIR/tools/remove-claude-hooks.js"
