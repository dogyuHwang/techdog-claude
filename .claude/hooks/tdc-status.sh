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

# 3. Tool count
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
