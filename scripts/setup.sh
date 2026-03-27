#!/bin/bash
# setup.sh — Post-install setup for npm install
set -e

TDC_HOME="$HOME/.tdc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p "$TDC_HOME"/{agents,skills,hooks,scripts}

cp -r "$REPO_DIR/.claude/agents/"* "$TDC_HOME/agents/" 2>/dev/null || true
cp -r "$REPO_DIR/.claude/skills/"* "$TDC_HOME/skills/" 2>/dev/null || true
cp -r "$REPO_DIR/.claude/hooks/"* "$TDC_HOME/hooks/" 2>/dev/null || true
cp -r "$REPO_DIR/scripts/"* "$TDC_HOME/scripts/" 2>/dev/null || true

chmod +x "$TDC_HOME/scripts/"* 2>/dev/null || true
chmod +x "$TDC_HOME/hooks/"* 2>/dev/null || true

echo "[tdc] Setup complete. TDC_HOME=$TDC_HOME"
