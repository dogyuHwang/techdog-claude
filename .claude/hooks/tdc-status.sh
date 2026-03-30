#!/bin/bash
# tdc-status.sh — Status line script for Claude Code
# Reads .tdc/context/ files and outputs a one-line status
# Configured as statusLine command in Claude Code settings

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
CONTEXT_DIR="$TDC_DIR/context"
STATUS_FILE="$CONTEXT_DIR/.agent-status"
PHASE_FILE="$CONTEXT_DIR/.phase"
TOOL_COUNT_FILE="$CONTEXT_DIR/.tool_count"

# If .tdc doesn't exist, TDC is not active — output nothing
if [ ! -d "$TDC_DIR" ]; then
    exit 0
fi

# --- Build status parts ---
PARTS=""

# 1. Phase indicator
if [ -f "$PHASE_FILE" ]; then
    PHASE=$(cat "$PHASE_FILE" 2>/dev/null)
    if [ -n "$PHASE" ]; then
        PARTS="$PHASE"
    fi
fi

# 2. Active agent
if [ -f "$STATUS_FILE" ]; then
    AGENT=$(grep '^AGENT=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
    STATE=$(grep '^STATE=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
    if [ "$STATE" = "working" ] && [ -n "$AGENT" ]; then
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | $AGENT working"
        else
            PARTS="$AGENT working"
        fi
    fi
fi

# 3. Token usage (real-time from .agent-tokens)
AGENT_TOKENS_FILE="$CONTEXT_DIR/.agent-tokens"
if [ -f "$AGENT_TOKENS_FILE" ]; then
    TOTAL_TOKENS=0
    while IFS='=' read -r name val; do
        [ -n "$val" ] && TOTAL_TOKENS=$(( TOTAL_TOKENS + val )) 2>/dev/null
    done < "$AGENT_TOKENS_FILE"
    if [ "$TOTAL_TOKENS" -gt 0 ] 2>/dev/null; then
        if [ "$TOTAL_TOKENS" -ge 1000 ]; then
            TOKEN_DISPLAY="$(( TOTAL_TOKENS / 1000 )).$(( (TOTAL_TOKENS % 1000) / 100 ))k"
        else
            TOKEN_DISPLAY="${TOTAL_TOKENS}"
        fi
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | ~${TOKEN_DISPLAY} tokens"
        else
            PARTS="~${TOKEN_DISPLAY} tokens"
        fi
    fi
fi

# 4. Tool count
if [ -f "$TOOL_COUNT_FILE" ]; then
    TOOLS=$(cat "$TOOL_COUNT_FILE" 2>/dev/null)
    if [ -n "$TOOLS" ] && [ "$TOOLS" -gt 0 ] 2>/dev/null; then
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | ${TOOLS} tools"
        else
            PARTS="${TOOLS} tools"
        fi
    fi
fi

# Output with TDC prefix if there's anything to show
if [ -n "$PARTS" ]; then
    # Check for Ralph mode
    RALPH_FILE="$CONTEXT_DIR/.ralph"
    if [ -f "$RALPH_FILE" ]; then
        echo "[TDC-RALPH] $PARTS"
    else
        echo "[TDC] $PARTS"
    fi
fi
