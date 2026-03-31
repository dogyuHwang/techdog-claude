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

# 2. Active agent (with model name)
if [ -f "$STATUS_FILE" ]; then
    AGENT=$(grep '^AGENT=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
    STATE=$(grep '^STATE=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
    MODEL=$(grep '^MODEL=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
    if [ "$STATE" = "working" ] && [ -n "$AGENT" ]; then
        AGENT_LABEL="$AGENT"
        [ -n "$MODEL" ] && AGENT_LABEL="${AGENT}[${MODEL}]"
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | $AGENT_LABEL working"
        else
            PARTS="$AGENT_LABEL working"
        fi
    fi
fi

# 3. Token usage (real-time from .agent-tokens)
AGENT_TOKENS_FILE="$CONTEXT_DIR/.agent-tokens"
if [ -f "$AGENT_TOKENS_FILE" ]; then
    TOTAL_TOKENS=0
    while IFS='=' read -r name val; do
        [[ "$val" =~ ^[0-9]+$ ]] && TOTAL_TOKENS=$(( TOTAL_TOKENS + val ))
    done < "$AGENT_TOKENS_FILE"
    if [ "$TOTAL_TOKENS" -gt 0 ]; then
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
    [[ "$TOOLS" =~ ^[0-9]+$ ]] || TOOLS=0
    if [ "$TOOLS" -gt 0 ]; then
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | ${TOOLS} tools"
        else
            PARTS="${TOOLS} tools"
        fi
    fi
fi

# 5. rtk status
RTK_STATUS_FILE="$CONTEXT_DIR/.rtk_status"
if [ -f "$RTK_STATUS_FILE" ]; then
    RTK_ST=$(cat "$RTK_STATUS_FILE" 2>/dev/null)
    case "$RTK_ST" in
        ok:*)    RTK_PCT="${RTK_ST#ok:}"; RTK_LABEL="rtk:${RTK_PCT}%" ;;
        ok)      RTK_LABEL="rtk:ON" ;;
        broken)  RTK_LABEL="rtk:ERR" ;;
        missing) RTK_LABEL="rtk:OFF" ;;
        *)       RTK_LABEL="" ;;
    esac
    if [ -n "$RTK_LABEL" ]; then
        if [ -n "$PARTS" ]; then
            PARTS="$PARTS | $RTK_LABEL"
        else
            PARTS="$RTK_LABEL"
        fi
    fi
fi

# Output with TDC prefix if there's anything to show
if [ -n "$PARTS" ]; then
    # Check for Deep mode
    DEEP_FILE="$CONTEXT_DIR/.deep"
    if [ -f "$DEEP_FILE" ]; then
        echo "[TDC-DEEP] $PARTS"
    else
        echo "[TDC] $PARTS"
    fi
fi
