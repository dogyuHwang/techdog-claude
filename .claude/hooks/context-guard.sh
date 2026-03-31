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
            # Also verify the PreToolUse hook is registered in settings.json
            RTK_HOOK_REGISTERED=false
            SETTINGS_FILE="$HOME/.claude/settings.json"
            if [ -f "$SETTINGS_FILE" ] && command -v python3 >/dev/null 2>&1; then
                RTK_HOOK_REGISTERED=$(python3 -c "
import json
try:
    with open('$SETTINGS_FILE') as f:
        s = json.load(f)
    hooks = s.get('hooks', {}).get('PreToolUse', [])
    found = any('rtk-rewrite' in hk.get('command', '') for h in hooks for hk in h.get('hooks', []))
    print('true' if found else 'false')
except: print('false')
" 2>/dev/null)
            fi

            if [ "$RTK_HOOK_REGISTERED" = "true" ]; then
                # Extract actual savings percentage from rtk gain
                RTK_SAVINGS=$(rtk gain 2>/dev/null | sed -n 's/.*Tokens saved:.*(\([0-9.]*\)%.*/\1/p' | head -1)
                RTK_SAVINGS="${RTK_SAVINGS:-N/A}"
                echo "ok:${RTK_SAVINGS}" > "$RTK_STATUS_FILE"
                echo "[TDC] rtk active ($(rtk --version 2>/dev/null)) — token savings: ${RTK_SAVINGS}%"
            else
                echo "broken" > "$RTK_STATUS_FILE"
                echo "[TDC] WARNING: rtk installed but PreToolUse hook NOT registered in settings.json."
                echo "[TDC] Fix: reinstall with 'curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash'"
            fi
        else
            echo "broken" > "$RTK_STATUS_FILE"
            echo "[TDC] WARNING: rtk is installed but not working. Token compression disabled. Run 'rtk --version' to diagnose."
        fi
    else
        echo "missing" > "$RTK_STATUS_FILE"
        echo "[TDC] WARNING: rtk not installed. Token compression disabled (60-90% savings lost). Install: brew install rtk-ai/tap/rtk"
    fi
fi

# --- Version update check (once per session) ---
VERSION_CHECK_FILE="$CONTEXT_DIR/.version_checked"
if [ ! -f "$VERSION_CHECK_FILE" ]; then
    touch "$VERSION_CHECK_FILE"
    TDC_REPO="$HOME/.tdc/.repo"
    if [ -d "$TDC_REPO/.git" ]; then
        CURRENT_VER=$(python3 -c "import json; print(json.load(open('$TDC_REPO/package.json'))['version'])" 2>/dev/null)
        # Quick check: fetch and compare (timeout 5s to avoid blocking)
        if timeout 5 git -C "$TDC_REPO" fetch origin main --quiet 2>/dev/null; then
            REMOTE_VER=$(git -C "$TDC_REPO" show origin/main:package.json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['version'])" 2>/dev/null)
            if [ -n "$REMOTE_VER" ] && [ -n "$CURRENT_VER" ] && [ "$REMOTE_VER" != "$CURRENT_VER" ]; then
                echo "[TDC] New version available: v${CURRENT_VER} → v${REMOTE_VER}. Run /tdc upgrade to update."
            fi
        fi
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
