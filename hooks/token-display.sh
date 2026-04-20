#!/usr/bin/env bash
# token-display.sh — Show token usage summary at the end of every response
# Called on Stop hook event (fires after each Claude response turn)

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CONTEXT_DIR="$TDC_PROJECT_DIR/.tdc/context"
TOKENS_FILE="$CONTEXT_DIR/.agent-tokens"
TOOL_COUNT_FILE="$CONTEXT_DIR/.tool_count"

# Read tool count
TOOL_COUNT=0
if [ -f "$TOOL_COUNT_FILE" ]; then
    TOOL_COUNT=$(cat "$TOOL_COUNT_FILE" 2>/dev/null)
    [[ "$TOOL_COUNT" =~ ^[0-9]+$ ]] || TOOL_COUNT=0
fi

# Try to extract actual session token usage from Stop event JSON (Claude Code provides this)
INPUT=""
[ ! -t 0 ] && INPUT=$(cat)

SESSION_IN=0
SESSION_OUT=0
if [ -n "$INPUT" ]; then
    if command -v jq >/dev/null 2>&1; then
        SESSION_IN=$(echo "$INPUT"  | jq -r '.usage.input_tokens  // 0' 2>/dev/null || echo 0)
        SESSION_OUT=$(echo "$INPUT" | jq -r '.usage.output_tokens // 0' 2>/dev/null || echo 0)
    elif command -v python3 >/dev/null 2>&1; then
        SESSION_IN=$(echo "$INPUT"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('input_tokens',0))"  2>/dev/null || echo 0)
        SESSION_OUT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('usage',{}).get('output_tokens',0))" 2>/dev/null || echo 0)
    fi
    [[ "$SESSION_IN"  =~ ^[0-9]+$ ]] || SESSION_IN=0
    [[ "$SESSION_OUT" =~ ^[0-9]+$ ]] || SESSION_OUT=0
fi
SESSION_TOTAL=$(( SESSION_IN + SESSION_OUT ))

# Read sub-agent token estimates from .agent-tokens (format: agentname=VALUE)
GRAND_TOTAL=0
MAX_VAL=1
AGENT_LIST=""
if [ -f "$TOKENS_FILE" ]; then
    while IFS='=' read -r aname aval; do
        [[ "$aname" =~ ^[a-z] ]] || continue
        [[ "$aval" =~ ^[0-9]+$ ]] || continue
        [ "$aval" -eq 0 ] && continue
        GRAND_TOTAL=$(( GRAND_TOTAL + aval ))
        [ "$aval" -gt "$MAX_VAL" ] && MAX_VAL=$aval
        AGENT_LIST="${AGENT_LIST}${aname}=${aval}\n"
    done < "$TOKENS_FILE"
fi

# ─── Build display ────────────────────────────────────────────────────

fmt_k() {
    local n=$1
    if [ "$n" -ge 1000 ]; then
        echo "$(( n / 1000 )).$(( (n % 1000) / 100 ))k"
    else
        echo "${n}"
    fi
}

get_model() {
    case "$1" in
        master|architect)                         echo "opus"   ;;
        reviewer|security-reviewer|meta-reviewer) echo "haiku"  ;;
        *)                                        echo "sonnet" ;;
    esac
}

echo "─────────────────────────────────────────────────────────"
echo "  [TDC] 📊 Token Usage"

# Session-level actual counts (from Stop event JSON)
if [ "$SESSION_TOTAL" -gt 0 ]; then
    IN_DISP=$(fmt_k "$SESSION_IN")
    OUT_DISP=$(fmt_k "$SESSION_OUT")
    TOT_DISP=$(fmt_k "$SESSION_TOTAL")
    echo "  Session:  ${IN_DISP} in + ${OUT_DISP} out  =  ~${TOT_DISP} tokens (actual)"
fi

# Sub-agent breakdown (estimated from elapsed time)
if [ "$GRAND_TOTAL" -gt 0 ]; then
    echo "  ─────────────────────────────────────────────────────"
    echo "  Sub-agents (estimated):"
    GT_DISP=$(fmt_k "$GRAND_TOTAL")
    printf '%b' "$AGENT_LIST" | while IFS='=' read -r aname aval; do
        [[ "$aval" =~ ^[0-9]+$ ]] || continue
        MODEL=$(get_model "$aname")
        FILLED=$(( aval * 16 / MAX_VAL ))
        [ "$FILLED" -gt 16 ] && FILLED=16
        EMPTY=$(( 16 - FILLED ))
        BAR=""
        i=0; while [ $i -lt $FILLED ]; do BAR="${BAR}█"; i=$(( i + 1 )); done
        i=0; while [ $i -lt $EMPTY ];  do BAR="${BAR}░"; i=$(( i + 1 )); done
        PCT=$(( aval * 100 / GRAND_TOTAL ))
        ADISP=$(fmt_k "$aval")
        LABEL=$(printf "%-20s" "${aname}(${MODEL})")
        echo "  ${LABEL} ${BAR}  ~${ADISP} (${PCT}%)"
    done
    echo "  ─────────────────────────────────────────────────────"
    GT_DISP=$(fmt_k "$GRAND_TOTAL")
    echo "  Sub-total: ~${GT_DISP} est. | tools used: ${TOOL_COUNT}"
elif [ "$TOOL_COUNT" -gt 0 ]; then
    echo "  tools used: ${TOOL_COUNT}"
fi

echo "─────────────────────────────────────────────────────────"

echo '{"decision": "continue"}'
