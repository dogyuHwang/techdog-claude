#!/bin/bash
# context-monitor.sh — Utility to check current context usage
# Usage: tdc context-status

TDC_DIR="${1:-.}/.tdc"
TOOL_COUNT_FILE="$TDC_DIR/context/.tool_count"

if [ ! -f "$TOOL_COUNT_FILE" ]; then
    echo "No active session tracked."
    exit 0
fi

COUNT=$(cat "$TOOL_COUNT_FILE" 2>/dev/null | tr -dc '0-9')
COUNT=${COUNT:-0}
echo "=== TDC Context Monitor ==="
echo "Tool calls this session: $COUNT"

if [ "$COUNT" -ge 120 ]; then
    echo "Status: CRITICAL — save session immediately"
elif [ "$COUNT" -ge 80 ]; then
    echo "Status: WARNING — consider saving soon"
elif [ "$COUNT" -ge 40 ]; then
    echo "Status: MODERATE — progressing normally"
else
    echo "Status: HEALTHY — plenty of context remaining"
fi

# Show active sessions
SESSION_DIR="$TDC_DIR/sessions"
if [ -d "$SESSION_DIR" ]; then
    SESSION_COUNT=$(find "$SESSION_DIR" -name "*.json" 2>/dev/null | wc -l)
    echo "Saved sessions: $SESSION_COUNT"
fi
