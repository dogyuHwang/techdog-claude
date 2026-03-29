#!/bin/bash
# context-guard.sh — Monitor context usage and trigger auto-save
# Called as a Claude Code hook on tool execution events

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
SESSION_DIR="$TDC_DIR/sessions"
CONTEXT_DIR="$TDC_DIR/context"

# Ensure directories exist
mkdir -p "$SESSION_DIR" "$CONTEXT_DIR"

# --- rtk health check (once per session) ---
RTK_STATUS_FILE="$CONTEXT_DIR/.rtk_status"
if [ ! -f "$RTK_STATUS_FILE" ]; then
    if command -v rtk >/dev/null 2>&1; then
        # Verify rtk actually works (not just installed)
        if rtk --version >/dev/null 2>&1; then
            echo "ok" > "$RTK_STATUS_FILE"
        else
            echo "broken" > "$RTK_STATUS_FILE"
            echo "[TDC] WARNING: rtk is installed but not working. Token compression disabled. Run 'rtk --version' to diagnose."
        fi
    else
        echo "missing" > "$RTK_STATUS_FILE"
        echo "[TDC] WARNING: rtk not installed. Token compression disabled (60-90% savings lost). Install: brew install rtk-ai/tap/rtk"
    fi
fi

# --- Tool call counter ---
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
    printf '{"warning": "context_overflow", "tool_calls": %d, "timestamp": "%s"}\n' "$COUNT" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CONTEXT_DIR/.overflow_flag"
elif [ "$COUNT" -ge 80 ]; then
    echo "[TDC] WARNING: High context usage ($COUNT tool calls). Consider saving session with /tdc-session save"
fi
