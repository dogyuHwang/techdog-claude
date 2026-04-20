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

# Read Claude Code context JSON from stdin (provided periodically by the harness)
STDIN_JSON=""
[ ! -t 0 ] && STDIN_JSON=$(cat 2>/dev/null)

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

# 6. Rate limit burn rate (from Claude Code session JSON via stdin)
if [ -n "$STDIN_JSON" ]; then
    RL_PCT="" RL_RESET=""
    if command -v jq >/dev/null 2>&1; then
        RL_PCT=$(echo "$STDIN_JSON"   | jq -r '.rate_limits.five_hour.used_percentage // ""' 2>/dev/null)
        RL_RESET=$(echo "$STDIN_JSON" | jq -r '.rate_limits.five_hour.resets_at       // ""' 2>/dev/null)
    elif command -v python3 >/dev/null 2>&1; then
        RL_PCT=$(echo "$STDIN_JSON"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('rate_limits',{}).get('five_hour',{}).get('used_percentage',''))" 2>/dev/null)
        RL_RESET=$(echo "$STDIN_JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('rate_limits',{}).get('five_hour',{}).get('resets_at',''))" 2>/dev/null)
    fi

    if [ -n "$RL_PCT" ] && [ "$RL_PCT" != "null" ]; then
        RL_INT=$(echo "$RL_PCT" | cut -d. -f1)
        [[ "$RL_INT" =~ ^[0-9]+$ ]] || RL_INT=0

        RESET_DISP=""
        if [ -n "$RL_RESET" ] && [ "$RL_RESET" != "null" ]; then
            # Parse ISO 8601 → epoch (Linux date)
            RESET_EPOCH=$(date -d "$RL_RESET" +%s 2>/dev/null)
            # macOS fallback
            [ -z "$RESET_EPOCH" ] && RESET_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$RL_RESET" +%s 2>/dev/null)
            NOW_EPOCH=$(date +%s)
            if [[ "$RESET_EPOCH" =~ ^[0-9]+$ ]] && [ "$RESET_EPOCH" -gt "$NOW_EPOCH" ]; then
                REM=$(( (RESET_EPOCH - NOW_EPOCH) / 60 ))
                if [ "$REM" -ge 60 ]; then
                    RESET_DISP=" ⏰$(( REM / 60 ))h$(( REM % 60 ))m"
                else
                    RESET_DISP=" ⏰${REM}m"
                fi
            fi
        fi

        [ "$RL_INT" -ge 80 ] && RL_LABEL="⚠5h:${RL_INT}%${RESET_DISP}" || RL_LABEL="5h:${RL_INT}%${RESET_DISP}"

        [ -n "$PARTS" ] && PARTS="$PARTS | $RL_LABEL" || PARTS="$RL_LABEL"
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
