#!/bin/bash
# session-save.sh — Auto-save session state on conversation stop
# Called as a Claude Code hook on conversation end events

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
SESSION_DIR="$TDC_DIR/sessions"
CONTEXT_DIR="$TDC_DIR/context"
PLANS_DIR="$TDC_DIR/plans"

mkdir -p "$SESSION_DIR" "$CONTEXT_DIR"

# Check if there's an overflow flag
if [ -f "$CONTEXT_DIR/.overflow_flag" ]; then
    TIMESTAMP=$(date -u +%Y%m%d_%H%M%S)
    SESSION_FILE="$SESSION_DIR/auto_${TIMESTAMP}.json"

    # --- Gather state from project artifacts ---

    # 1. Latest plan file (if any)
    LATEST_PLAN=""
    if [ -d "$PLANS_DIR" ]; then
        LATEST_PLAN=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
    fi
    PLAN_NAME=""
    if [ -n "$LATEST_PLAN" ]; then
        PLAN_NAME=$(basename "$LATEST_PLAN")
    fi

    # 2. Modified files (git tracked)
    FILES_MODIFIED="[]"
    if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null | head -20 | \
            awk 'BEGIN{printf "["} NR>1{printf ","} {gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "\"%s\"", $0} END{printf "]"}')
        [ "$FILES_MODIFIED" = "[]" ] && \
            FILES_MODIFIED=$(git diff --name-only 2>/dev/null | head -20 | \
                awk 'BEGIN{printf "["} NR>1{printf ","} {gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); printf "\"%s\"", $0} END{printf "]"}')
    fi

    # 3. Tool call count at save time
    TOOL_CALLS=0
    if [ -f "$CONTEXT_DIR/.tool_count" ]; then
        TOOL_CALLS=$(cat "$CONTEXT_DIR/.tool_count" 2>/dev/null)
        [[ "$TOOL_CALLS" =~ ^[0-9]+$ ]] || TOOL_CALLS=0
    fi

    # 4. Extract completed/pending tasks from latest plan ([ ] and [x] markers)
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

    # Build JSON safely (escape special characters in paths)
    if command -v jq >/dev/null 2>&1; then
        jq -n \
            --arg sid "$TIMESTAMP" \
            --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --arg proj "$TDC_PROJECT_DIR" \
            --arg plan "$PLAN_NAME" \
            --argjson tc "$TOOL_CALLS" \
            --argjson completed "$COMPLETED" \
            --argjson pending "$PENDING" \
            --argjson files "$FILES_MODIFIED" \
            '{
              session_id: $sid,
              type: "auto_save",
              reason: "context_overflow",
              timestamp: $ts,
              project: $proj,
              plan_file: $plan,
              tool_calls_at_save: $tc,
              completed: $completed,
              pending: $pending,
              files_modified: $files,
              note: "Session auto-saved due to context overflow. Resume with /tdc-session resume"
            }' > "$SESSION_FILE"
    else
        # Fallback: escape project dir for JSON safety
        SAFE_PROJECT=$(echo "$TDC_PROJECT_DIR" | sed 's/\\/\\\\/g; s/"/\\"/g')
        cat > "$SESSION_FILE" << SESSIONEOF
{
  "session_id": "$TIMESTAMP",
  "type": "auto_save",
  "reason": "context_overflow",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "project": "$SAFE_PROJECT",
  "plan_file": "$PLAN_NAME",
  "tool_calls_at_save": $TOOL_CALLS,
  "completed": $COMPLETED,
  "pending": $PENDING,
  "files_modified": $FILES_MODIFIED,
  "note": "Session auto-saved due to context overflow. Resume with /tdc-session resume"
}
SESSIONEOF
    fi

    echo "[TDC] Session auto-saved to $SESSION_FILE (with task state)"

    # Clean up flags and counter
    rm -f "$CONTEXT_DIR/.overflow_flag" "$CONTEXT_DIR/.tool_count" "$CONTEXT_DIR/.rtk_status" "$CONTEXT_DIR/.read_tokens" "$CONTEXT_DIR/.compaction_done" "$CONTEXT_DIR/.budget_warned"
fi
