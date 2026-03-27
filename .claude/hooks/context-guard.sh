#!/bin/bash
# context-guard.sh — Monitor context usage and trigger auto-save
# Called as a Claude Code hook on tool execution events

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
SESSION_DIR="$TDC_DIR/sessions"
CONTEXT_DIR="$TDC_DIR/context"

# Ensure directories exist
mkdir -p "$SESSION_DIR" "$CONTEXT_DIR"

# Count tool calls in current session (approximation via session files)
TOOL_COUNT_FILE="$CONTEXT_DIR/.tool_count"
if [ -f "$TOOL_COUNT_FILE" ]; then
    COUNT=$(cat "$TOOL_COUNT_FILE")
else
    COUNT=0
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$TOOL_COUNT_FILE"

# Threshold: warn at 80 tool calls, critical at 120
if [ "$COUNT" -ge 120 ]; then
    echo "[TDC] CRITICAL: Context limit approaching ($COUNT tool calls). Auto-saving session..."
    COUNT=$((COUNT + 0))
    printf '{"warning": "context_overflow", "tool_calls": %d, "timestamp": "%s"}\n' "$COUNT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CONTEXT_DIR/.overflow_flag"
elif [ "$COUNT" -ge 80 ]; then
    echo "[TDC] WARNING: High context usage ($COUNT tool calls). Consider saving session with /tdc-session save"
fi
