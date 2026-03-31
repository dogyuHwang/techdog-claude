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
    COUNT=$(cat "$TOOL_COUNT_FILE" 2>/dev/null)
    [[ "$COUNT" =~ ^[0-9]+$ ]] || COUNT=0
else
    COUNT=0
fi

COUNT=$((COUNT + 1))
echo "$COUNT" > "$TOOL_COUNT_FILE"

# --- Conversation Compaction at 60 tool calls ---
COMPACTION_FLAG="$CONTEXT_DIR/.compaction_done"
if [ "$COUNT" -eq 60 ] && [ ! -f "$COMPACTION_FLAG" ]; then
    touch "$COMPACTION_FLAG"
    echo "[TDC-COMPACT] 60 tool calls reached. Context compaction recommended."
    echo "[TDC-COMPACT] Summarize completed work so far and drop verbose intermediate results from memory."
    echo "[TDC-COMPACT] Focus remaining context on: current task, pending tasks, key decisions made."
fi

# --- Response Budget Tracking ---
# Estimate cumulative token usage from read operations
READ_TOKEN_FILE="$CONTEXT_DIR/.read_tokens"
READ_TOKENS=0
if [ -f "$READ_TOKEN_FILE" ]; then
    READ_TOKENS=$(cat "$READ_TOKEN_FILE" 2>/dev/null)
    [[ "$READ_TOKENS" =~ ^[0-9]+$ ]] || READ_TOKENS=0
fi
# Estimate total context: ~500 tokens per tool call (avg) + read tokens
ESTIMATED_TOTAL=$(( (COUNT * 500) + READ_TOKENS ))
BUDGET_WARN_FILE="$CONTEXT_DIR/.budget_warned"

if [ "$ESTIMATED_TOTAL" -gt 150000 ] && [ ! -f "$BUDGET_WARN_FILE" ]; then
    touch "$BUDGET_WARN_FILE"
    echo "[TDC-BUDGET] Estimated context usage: ~${ESTIMATED_TOTAL} tokens (${COUNT} calls + ${READ_TOKENS} read tokens)"
    echo "[TDC-BUDGET] Token budget is high. Agents should minimize output verbosity."
fi

# Threshold: warn at 80 tool calls, critical at 120
if [ "$COUNT" -ge 120 ]; then
    echo "[TDC] CRITICAL: Context limit approaching ($COUNT tool calls, ~${ESTIMATED_TOTAL} est. tokens). Auto-saving session..."
    printf '{"warning": "context_overflow", "tool_calls": %d, "estimated_tokens": %d, "timestamp": "%s"}\n' "$COUNT" "$ESTIMATED_TOTAL" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CONTEXT_DIR/.overflow_flag"
elif [ "$COUNT" -ge 80 ]; then
    echo "[TDC] WARNING: High context usage ($COUNT tool calls, ~${ESTIMATED_TOTAL} est. tokens). Consider saving session with /tdc-session save"
fi
