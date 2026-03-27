#!/bin/bash
# session-save.sh — Auto-save session state on conversation stop
# Called as a Claude Code hook on conversation end events

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
SESSION_DIR="$TDC_DIR/sessions"
CONTEXT_DIR="$TDC_DIR/context"

mkdir -p "$SESSION_DIR" "$CONTEXT_DIR"

# Check if there's an overflow flag
if [ -f "$CONTEXT_DIR/.overflow_flag" ]; then
    TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
    SESSION_FILE="$SESSION_DIR/auto_${TIMESTAMP}.json"

    cat > "$SESSION_FILE" << SESSIONEOF
{
  "session_id": "$TIMESTAMP",
  "type": "auto_save",
  "reason": "context_overflow",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project": "$TDC_PROJECT_DIR",
  "note": "Session auto-saved due to context overflow. Resume with /tdc-session resume"
}
SESSIONEOF

    echo "[TDC] Session auto-saved to $SESSION_FILE"

    # Clean up flags
    rm -f "$CONTEXT_DIR/.overflow_flag" "$CONTEXT_DIR/.tool_count"
fi
