#!/bin/bash
# pre-compact.sh — Save critical state BEFORE context compaction
# PreCompact hook — ensures important information survives compression
# Writes to .tdc/context/notepad.md which agents load after compaction

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
CONTEXT_DIR="$TDC_DIR/context"
NOTEPAD="$CONTEXT_DIR/notepad.md"
PLANS_DIR="$TDC_DIR/plans"

mkdir -p "$CONTEXT_DIR"

TIMESTAMP=$(date +%H:%M:%S)

# --- Gather survival data ---

# 1. Current phase
PHASE=""
if [ -f "$CONTEXT_DIR/.phase" ]; then
    PHASE=$(cat "$CONTEXT_DIR/.phase")
fi

# 2. Active agent
AGENT=""
AGENT_STATE=""
if [ -f "$CONTEXT_DIR/.agent-status" ]; then
    AGENT=$(grep '^AGENT=' "$CONTEXT_DIR/.agent-status" 2>/dev/null | cut -d= -f2)
    AGENT_STATE=$(grep '^STATE=' "$CONTEXT_DIR/.agent-status" 2>/dev/null | cut -d= -f2)
fi

# 3. Tool call count
TOOL_COUNT=0
if [ -f "$CONTEXT_DIR/.tool_count" ]; then
    TOOL_COUNT=$(cat "$CONTEXT_DIR/.tool_count" 2>/dev/null)
    [[ "$TOOL_COUNT" =~ ^[0-9]+$ ]] || TOOL_COUNT=0
fi

# 4. Latest plan tasks (completed / pending)
COMPLETED=""
PENDING=""
LATEST_PLAN=""
if [ -d "$PLANS_DIR" ]; then
    LATEST_PLAN=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
fi
if [ -n "$LATEST_PLAN" ] && [ -f "$LATEST_PLAN" ]; then
    COMPLETED=$(grep -c '\[x\]' "$LATEST_PLAN" 2>/dev/null || echo "0")
    PENDING=$(grep -c '\[ \]' "$LATEST_PLAN" 2>/dev/null || echo "0")
fi

# 5. Modified files
FILES_MODIFIED=""
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    FILES_MODIFIED=$(git diff --name-only 2>/dev/null | head -10 | paste -sd ', ' -)
    [ -z "$FILES_MODIFIED" ] && FILES_MODIFIED=$(git diff --name-only HEAD 2>/dev/null | head -10 | paste -sd ', ' -)
fi

# 6. Deep mode?
DEEP_MODE=""
if [ -f "$CONTEXT_DIR/.deep" ]; then
    DEEP_MODE="ACTIVE"
fi

# 7. Agent token stats (if tracked)
AGENT_STATS=""
if [ -f "$CONTEXT_DIR/.agent-tokens" ]; then
    AGENT_STATS=$(cat "$CONTEXT_DIR/.agent-tokens")
fi

# --- Write notepad (survives compaction) ---
cat > "$NOTEPAD" << EOF
# TDC Notepad — Compaction Survival Data
> Auto-saved at $TIMESTAMP before context compaction. Load this after compaction.

## Current State
- **Phase**: ${PHASE:-"unknown"}
- **Active Agent**: ${AGENT:-"none"} (${AGENT_STATE:-"idle"})
- **Tool Calls**: $TOOL_COUNT
- **Deep Mode**: ${DEEP_MODE:-"inactive"}

## Task Progress
- **Completed**: ${COMPLETED:-0} tasks
- **Pending**: ${PENDING:-0} tasks
- **Plan File**: ${LATEST_PLAN:-"none"}

## Modified Files
${FILES_MODIFIED:-"none"}

## Agent Token Usage
${AGENT_STATS:-"no data yet"}

## Instructions
After compaction, read this file and resume from the current phase.
Do NOT re-read files already processed. Continue from pending tasks.
EOF

echo "[TDC-COMPACT] Pre-compaction state saved to $NOTEPAD ($TIMESTAMP)"
echo "[TDC-COMPACT] Phase: ${PHASE:-unknown} | Tasks: ${COMPLETED:-0} done, ${PENDING:-0} pending | Tools: $TOOL_COUNT"
