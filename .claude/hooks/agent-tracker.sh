#!/bin/bash
# agent-tracker.sh — Track agent lifecycle for Live Dashboard visibility
# Called on SubagentStart and SubagentStop hook events
# Writes status to .tdc/context/.agent-status for status line to read

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TDC_DIR="$TDC_PROJECT_DIR/.tdc"
CONTEXT_DIR="$TDC_DIR/context"
STATUS_FILE="$CONTEXT_DIR/.agent-status"
LOG_FILE="$CONTEXT_DIR/.agent-events"

mkdir -p "$CONTEXT_DIR"

# Read hook input from stdin (Claude Code sends JSON)
INPUT=""
if [ ! -t 0 ]; then
    INPUT=$(cat)
fi

# Extract fields from JSON input
HOOK_EVENT=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('hook_event_name',''))" 2>/dev/null)
AGENT_TYPE=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent_type','unknown'))" 2>/dev/null)
AGENT_ID=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('agent_id',''))" 2>/dev/null)

# Normalize agent names (planner, developer, debugger, reviewer, architect)
AGENT_NAME="$AGENT_TYPE"
case "$AGENT_TYPE" in
    *planner*|*Planner*)   AGENT_NAME="planner" ;;
    *developer*|*Developer*) AGENT_NAME="developer" ;;
    *debugger*|*Debugger*)  AGENT_NAME="debugger" ;;
    *reviewer*|*Reviewer*)  AGENT_NAME="reviewer" ;;
    *architect*|*Architect*) AGENT_NAME="architect" ;;
esac

TIMESTAMP=$(date +%s)
TIME_HUMAN=$(date +%H:%M:%S)

if [ "$HOOK_EVENT" = "SubagentStart" ]; then
    # Write current status
    cat > "$STATUS_FILE" << EOF
AGENT=$AGENT_NAME
AGENT_ID=$AGENT_ID
STATE=working
START_TIME=$TIMESTAMP
UPDATED=$TIME_HUMAN
EOF

    # Append to event log
    echo "$TIME_HUMAN START $AGENT_NAME $AGENT_ID" >> "$LOG_FILE"

    # Console output for user visibility
    echo "[TDC] $AGENT_NAME agent started ($TIME_HUMAN)"

elif [ "$HOOK_EVENT" = "SubagentStop" ]; then
    # Calculate elapsed time if we have start time
    ELAPSED=""
    if [ -f "$STATUS_FILE" ]; then
        START_TIME=$(grep '^START_TIME=' "$STATUS_FILE" 2>/dev/null | cut -d= -f2)
        if [ -n "$START_TIME" ]; then
            ELAPSED=$(( TIMESTAMP - START_TIME ))
            ELAPSED="${ELAPSED}s"
        fi
    fi

    # Update status
    cat > "$STATUS_FILE" << EOF
AGENT=$AGENT_NAME
AGENT_ID=$AGENT_ID
STATE=idle
ELAPSED=$ELAPSED
UPDATED=$TIME_HUMAN
EOF

    # Append to event log
    echo "$TIME_HUMAN STOP  $AGENT_NAME $AGENT_ID ${ELAPSED}" >> "$LOG_FILE"

    # Console output
    if [ -n "$ELAPSED" ]; then
        echo "[TDC] $AGENT_NAME agent completed (${ELAPSED})"
    else
        echo "[TDC] $AGENT_NAME agent completed"
    fi
fi

# Output valid JSON for Claude Code hook protocol
echo '{"decision": "continue"}'
