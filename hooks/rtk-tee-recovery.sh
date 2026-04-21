#!/usr/bin/env bash
# rtk-tee-recovery.sh — Surface rtk tee (full output) when Bash tool exits non-zero
# PostToolUse hook, matcher: "Bash"
# rtk compresses stdout by default; full output is saved to ~/.local/share/rtk/tee/

RTK_TEE_DIR="$HOME/.local/share/rtk/tee"

# Early exit if rtk tee directory doesn't exist
[ -d "$RTK_TEE_DIR" ] || { echo '{}'; exit 0; }

# Read hook JSON from stdin
INPUT=""
[ ! -t 0 ] && INPUT=$(cat 2>/dev/null)
[ -z "$INPUT" ] && { echo '{}'; exit 0; }

# Extract exit code from tool response
EXIT_CODE=""
if command -v jq >/dev/null 2>&1; then
    EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // ""' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    EXIT_CODE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_response', {}).get('exit_code', ''))
except: print('')
" 2>/dev/null)
fi

# Only proceed on non-zero exit codes
[[ "$EXIT_CODE" =~ ^[0-9]+$ ]] || { echo '{}'; exit 0; }
[ "$EXIT_CODE" -eq 0 ]         && { echo '{}'; exit 0; }

# Find tee file created within the last 10 seconds
NOW=$(date +%s)
NEWEST_TEE=""
NEWEST_TIME=0
while IFS= read -r -d '' f; do
    FTIME=$(date -r "$f" +%s 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
    [[ "$FTIME" =~ ^[0-9]+$ ]] || continue
    if [ "$FTIME" -gt "$NEWEST_TIME" ] && [ $(( NOW - FTIME )) -le 30 ]; then
        NEWEST_TIME=$FTIME
        NEWEST_TEE=$f
    fi
done < <(find "$RTK_TEE_DIR" -maxdepth 1 -type f -print0 2>/dev/null)

if [ -n "$NEWEST_TEE" ]; then
    echo "[TDC] rtk full output (exit $EXIT_CODE): $NEWEST_TEE"
    echo "[TDC] Read full output: cat '$NEWEST_TEE'"
fi

echo '{}'
