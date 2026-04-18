#!/bin/bash
# session-save.sh — Auto-save session state on conversation stop or overflow
# Called as a Claude Code hook on Stop/conversation end events

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
SESSION_DIR="$TDC_DIR/sessions"
CONTEXT_DIR="$TDC_DIR/context"
PLANS_DIR="$TDC_DIR/plans"

mkdir -p "$SESSION_DIR" "$CONTEXT_DIR"

OVERFLOW_FLAG="$CONTEXT_DIR/.overflow_flag"
PHASE_FILE="$CONTEXT_DIR/.phase"
DEEP_FILE="$CONTEXT_DIR/.deep"

SHOULD_SAVE=false
SAVE_REASON="manual"

if [ -f "$OVERFLOW_FLAG" ]; then
    SHOULD_SAVE=true
    SAVE_REASON="context_overflow"
elif [ -f "$PHASE_FILE" ]; then
    SHOULD_SAVE=true
    SAVE_REASON="pipeline_interrupted"
fi

[ "$SHOULD_SAVE" = "false" ] && exit 0

TIMESTAMP=$(date -u +%Y%m%dT%H%M%S)
SESSION_FILE="$SESSION_DIR/${TIMESTAMP}.json"

# ── Phase state ──────────────────────────────────────────────
PHASE=""
[ -f "$PHASE_FILE" ] && PHASE=$(cat "$PHASE_FILE" 2>/dev/null | head -1)

# ── Agent state ──────────────────────────────────────────────
AGENT=""
AGENT_STATE=""
if [ -f "$CONTEXT_DIR/.agent-status" ]; then
    AGENT=$(grep '^AGENT=' "$CONTEXT_DIR/.agent-status" 2>/dev/null | cut -d= -f2)
    AGENT_STATE=$(grep '^STATE=' "$CONTEXT_DIR/.agent-status" 2>/dev/null | cut -d= -f2)
fi

# ── Tool call count ──────────────────────────────────────────
TOOL_CALLS=0
if [ -f "$CONTEXT_DIR/.tool_count" ]; then
    TOOL_CALLS=$(cat "$CONTEXT_DIR/.tool_count" 2>/dev/null)
    [[ "$TOOL_CALLS" =~ ^[0-9]+$ ]] || TOOL_CALLS=0
fi

# ── Latest plan tasks ────────────────────────────────────────
LATEST_PLAN=""
[ -d "$PLANS_DIR" ] && LATEST_PLAN=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
PLAN_NAME=""
[ -n "$LATEST_PLAN" ] && PLAN_NAME=$(basename "$LATEST_PLAN")

COMPLETED="[]"
PENDING="[]"
if [ -n "$LATEST_PLAN" ] && [ -f "$LATEST_PLAN" ]; then
    COMPLETED=$(grep -E '^\s*-\s*\[x\]' "$LATEST_PLAN" 2>/dev/null | \
        sed 's/.*\[x\]\s*//' | head -20 | \
        awk 'BEGIN{printf "["} NR>1{printf ","} {gsub(/"/, "\\\""); printf "\"%s\"", $0} END{printf "]"}')
    PENDING=$(grep -E '^\s*-\s*\[ \]' "$LATEST_PLAN" 2>/dev/null | \
        sed 's/.*\[ \]\s*//' | head -20 | \
        awk 'BEGIN{printf "["} NR>1{printf ","} {gsub(/"/, "\\\""); printf "\"%s\"", $0} END{printf "]"}')
fi

# ── Modified files + git state ───────────────────────────────
FILES_MODIFIED="[]"
GIT_SHA=""
GIT_BRANCH=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    GIT_SHA=$(git rev-parse HEAD 2>/dev/null | cut -c1-8)
    GIT_BRANCH=$(git branch --show-current 2>/dev/null)
    _FILES=$(git diff --name-only HEAD 2>/dev/null | head -20)
    [ -z "$_FILES" ] && _FILES=$(git diff --name-only 2>/dev/null | head -20)
    if [ -n "$_FILES" ]; then
        FILES_MODIFIED=$(echo "$_FILES" | \
            awk 'BEGIN{printf "["} NR>1{printf ","} {gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "\"%s\"", $0} END{printf "]"}')
    fi
fi

# ── Deep mode state ──────────────────────────────────────────
DEEP_ACTIVE="false"
DEEP_RETRY=0
DEEP_VERIFY=0
DEEP_REGRESSIONS=0
if [ -f "$DEEP_FILE" ]; then
    DEEP_ACTIVE="true"
    DEEP_RETRY=$(grep '^RETRY_COUNT=' "$DEEP_FILE" 2>/dev/null | cut -d= -f2)
    DEEP_VERIFY=$(grep '^VERIFY_PASS=' "$DEEP_FILE" 2>/dev/null | cut -d= -f2)
    DEEP_REGRESSIONS=$(grep '^TOTAL_REGRESSIONS=' "$DEEP_FILE" 2>/dev/null | cut -d= -f2)
    [[ "$DEEP_RETRY" =~ ^[0-9]+$ ]] || DEEP_RETRY=0
    [[ "$DEEP_VERIFY" =~ ^[0-9]+$ ]] || DEEP_VERIFY=0
    [[ "$DEEP_REGRESSIONS" =~ ^[0-9]+$ ]] || DEEP_REGRESSIONS=0
fi

# ── Regression history (last 3 entries) ─────────────────────
REGRESSION_HISTORY=""
if [ -f "$CONTEXT_DIR/.regression-history" ]; then
    REGRESSION_HISTORY=$(tail -3 "$CONTEXT_DIR/.regression-history" 2>/dev/null | \
        awk '{gsub(/"/, "\\\""); gsub(/\\n/, "\\\\n")} 1' | paste -sd '|' -)
fi

# ── Token usage ──────────────────────────────────────────────
TOKEN_TOTAL=0
TOKEN_BY_AGENT="{}"
if [ -f "$CONTEXT_DIR/.agent-tokens" ]; then
    BY={}
    while IFS= read -r line; do
        _A=$(echo "$line" | grep -oE 'AGENT=[^:]+' | cut -d= -f2)
        _T=$(echo "$line" | grep -oE 'TOKENS=[0-9]+' | cut -d= -f2)
        [ -n "$_A" ] && [ -n "$_T" ] && TOKEN_TOTAL=$((TOKEN_TOTAL + _T))
    done < "$CONTEXT_DIR/.agent-tokens"
fi

# ── Notepad snapshot (first 20 lines) ───────────────────────
NOTEPAD_SNAPSHOT=""
if [ -f "$CONTEXT_DIR/notepad.md" ]; then
    NOTEPAD_SNAPSHOT=$(head -20 "$CONTEXT_DIR/notepad.md" 2>/dev/null | \
        awk '{gsub(/"/, "\\\""); gsub(/\\/, "\\\\")} 1' | tr '\n' '|')
fi

# ── Write JSON ───────────────────────────────────────────────
SAFE_PROJ=$(echo "$TDC_PROJECT_DIR" | sed 's/\\/\\\\/g; s/"/\\"/g')
SAFE_NOTEPAD=$(echo "$NOTEPAD_SNAPSHOT" | sed 's/\\/\\\\/g; s/"/\\"/g')
SAFE_REGHIST=$(echo "$REGRESSION_HISTORY" | sed 's/\\/\\\\/g; s/"/\\"/g')

cat > "$SESSION_FILE" << SESSIONEOF
{
  "session_id": "${TIMESTAMP}",
  "saved_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "save_reason": "${SAVE_REASON}",
  "project": "${SAFE_PROJ}",
  "git_branch": "${GIT_BRANCH}",
  "git_head_sha": "${GIT_SHA}",
  "task": "(auto-saved — add description with /tdc-save [memo])",
  "phase": "${PHASE}",
  "active_agent": "${AGENT}",
  "active_agent_state": "${AGENT_STATE}",
  "plan_file": "${PLAN_NAME}",
  "tool_calls_at_save": ${TOOL_CALLS},
  "completed": ${COMPLETED},
  "in_progress": [],
  "pending": ${PENDING},
  "decisions": [],
  "files_modified": ${FILES_MODIFIED},
  "deep_mode": {
    "active": ${DEEP_ACTIVE},
    "retry_count": ${DEEP_RETRY},
    "verify_pass": ${DEEP_VERIFY},
    "total_regressions": ${DEEP_REGRESSIONS}
  },
  "regression_history": "${SAFE_REGHIST}",
  "token_usage": { "total_estimated": ${TOKEN_TOTAL} },
  "notepad_snapshot": "${SAFE_NOTEPAD}",
  "context_summary": "(auto-saved — no summary available)",
  "resume_hint": "/tdc-resume to continue from ${PHASE}"
}
SESSIONEOF

# ── Write .pending pointer ───────────────────────────────────
echo "$TIMESTAMP" > "$SESSION_DIR/.pending"

echo "[TDC] Session saved → $SESSION_FILE (${SAVE_REASON})"
echo "[TDC] Resume: /tdc-resume  |  Phase: ${PHASE:-unknown}  |  Tools: $TOOL_CALLS"

# ── Cleanup runtime flags ────────────────────────────────────
rm -f "$OVERFLOW_FLAG" "$CONTEXT_DIR/.rtk_status" "$CONTEXT_DIR/.version_checked" \
      "$CONTEXT_DIR/.compaction_done" "$CONTEXT_DIR/.budget_warned"
# Note: .phase, .deep, .agent-status are cleaned by master.md Phase 4 on normal completion
