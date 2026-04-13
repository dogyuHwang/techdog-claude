#!/bin/bash
# setup.sh — Post-install setup for npm install
set -e

TDC_HOME="$HOME/.tdc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p "$TDC_HOME"/{agents,skills,hooks,scripts,state/sessions,state/context}

cp -r "$REPO_DIR/agents/"* "$TDC_HOME/agents/" 2>/dev/null || true
cp -r "$REPO_DIR/skills/"* "$TDC_HOME/skills/" 2>/dev/null || true
cp -r "$REPO_DIR/hooks/"* "$TDC_HOME/hooks/" 2>/dev/null || true
cp -r "$REPO_DIR/scripts/"* "$TDC_HOME/scripts/" 2>/dev/null || true

chmod +x "$TDC_HOME/scripts/"* 2>/dev/null || true
chmod +x "$TDC_HOME/hooks/"* 2>/dev/null || true

# Install skills & agents to Claude Code global path (~/.claude/)
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"
cp -r "$REPO_DIR/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
cp -r "$REPO_DIR/agents/"* "$CLAUDE_DIR/agents/" 2>/dev/null || true

echo "[tdc] Setup complete. TDC_HOME=$TDC_HOME"
