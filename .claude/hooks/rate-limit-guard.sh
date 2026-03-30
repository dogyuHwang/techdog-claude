#!/bin/bash
# rate-limit-guard.sh — Detect API rate limits and guide auto-recovery
# PostToolUse hook — monitors tool outputs for rate limit signals
# When detected: logs the event, writes retry info, outputs guidance

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
CONTEXT_DIR="$TDC_DIR/context"
RATE_LIMIT_FILE="$CONTEXT_DIR/.rate_limit"

mkdir -p "$CONTEXT_DIR"

# Read hook event from stdin
EVENT=$(cat 2>/dev/null)
TOOL_OUTPUT=$(echo "$EVENT" | jq -r '.tool_result // .tool_output // empty' 2>/dev/null)

# If no output or jq not available, exit silently
if [ -z "$TOOL_OUTPUT" ]; then
    exit 0
fi

# Detect rate limit patterns in tool output
# Common patterns: "rate limit", "429", "too many requests", "retry after", "overloaded"
RATE_LIMITED=false
RETRY_AFTER=""

if echo "$TOOL_OUTPUT" | grep -iqE 'rate.?limit|429|too many requests|overloaded_error|rate_limit_error'; then
    RATE_LIMITED=true
    # Try to extract retry-after value (seconds)
    RETRY_AFTER=$(echo "$TOOL_OUTPUT" | grep -oiE 'retry.?after[: ]*([0-9]+)' | grep -oE '[0-9]+' | head -1)
fi

if [ "$RATE_LIMITED" = "true" ]; then
    TIMESTAMP=$(date +%H:%M:%S)
    NOW_EPOCH=$(date +%s)

    # Check if we recently warned (within 30s) to avoid spam
    if [ -f "$RATE_LIMIT_FILE" ]; then
        LAST_WARN=$(grep '^LAST_WARN=' "$RATE_LIMIT_FILE" 2>/dev/null | cut -d= -f2)
        if [ -n "$LAST_WARN" ]; then
            DIFF=$(( NOW_EPOCH - LAST_WARN ))
            if [ "$DIFF" -lt 30 ]; then
                exit 0
            fi
        fi
    fi

    # Track rate limit occurrences
    HIT_COUNT=0
    if [ -f "$RATE_LIMIT_FILE" ]; then
        HIT_COUNT=$(grep '^HIT_COUNT=' "$RATE_LIMIT_FILE" 2>/dev/null | cut -d= -f2)
        HIT_COUNT=${HIT_COUNT:-0}
    fi
    HIT_COUNT=$((HIT_COUNT + 1))

    # Default retry wait
    WAIT_SECONDS="${RETRY_AFTER:-60}"

    cat > "$RATE_LIMIT_FILE" << EOF
RATE_LIMITED=true
HIT_COUNT=$HIT_COUNT
LAST_WARN=$NOW_EPOCH
RETRY_AFTER=$WAIT_SECONDS
TIMESTAMP=$TIMESTAMP
EOF

    # Output warning to user
    echo "[TDC-RATE-LIMIT] API rate limit detected at $TIMESTAMP (hit #$HIT_COUNT)"
    if [ -n "$RETRY_AFTER" ]; then
        echo "[TDC-RATE-LIMIT] Server suggests retry after ${RETRY_AFTER}s"
    fi
    echo "[TDC-RATE-LIMIT] Recommendation: Wait ${WAIT_SECONDS}s before next action. Agents should reduce parallelism."

    # If hit 3+ times, suggest session save
    if [ "$HIT_COUNT" -ge 3 ]; then
        echo "[TDC-RATE-LIMIT] WARNING: Rate limited $HIT_COUNT times this session."
        echo "[TDC-RATE-LIMIT] Consider: /tdc-session save, then resume after cooldown."
    fi
fi
