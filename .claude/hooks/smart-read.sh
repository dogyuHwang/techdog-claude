#!/bin/bash
# smart-read.sh — Token optimization for Read tool
# PostToolUse hook (matcher: "Read") — detects large file reads and warns
# Encourages agents to use targeted reads (offset/limit, Grep first)

TDC_PROJECT_DIR="${TDC_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
CONTEXT_DIR="$TDC_PROJECT_DIR/.tdc/context"
mkdir -p "$CONTEXT_DIR"

# Read hook event from stdin (JSON with tool_name, tool_input)
EVENT=$(cat 2>/dev/null)
FILE_PATH=$(echo "$EVENT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
HAS_OFFSET=$(echo "$EVENT" | jq -r '.tool_input.offset // empty' 2>/dev/null)
HAS_LIMIT=$(echo "$EVENT" | jq -r '.tool_input.limit // empty' 2>/dev/null)

# If no file path detected, try to extract from simple format
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Check if file exists and get line count
if [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null || echo 0)
# Approximate tokens: ~10 tokens per line average for code
APPROX_TOKENS=$((LINE_COUNT * 10))

# Track cumulative read tokens for this session
READ_TOKEN_FILE="$CONTEXT_DIR/.read_tokens"
if [ -f "$READ_TOKEN_FILE" ]; then
    CUMULATIVE=$(cat "$READ_TOKEN_FILE")
else
    CUMULATIVE=0
fi

# Only count if full file read (no offset/limit specified)
if [ -z "$HAS_OFFSET" ] && [ -z "$HAS_LIMIT" ]; then
    CUMULATIVE=$((CUMULATIVE + APPROX_TOKENS))
    echo "$CUMULATIVE" > "$READ_TOKEN_FILE"

    # Warn for large file reads (>200 lines without targeting)
    if [ "$LINE_COUNT" -gt 200 ]; then
        echo "[TDC-TOKEN] Large file read: $FILE_PATH ($LINE_COUNT lines, ~${APPROX_TOKENS} tokens)"
        echo "[TDC-TOKEN] Tip: Use Read with offset/limit params, or Grep/Glob first to target specific sections."
    fi
fi

# Warn if cumulative read tokens are getting high
if [ "$CUMULATIVE" -gt 50000 ]; then
    echo "[TDC-TOKEN] High cumulative read usage: ~${CUMULATIVE} tokens from file reads this session."
fi
