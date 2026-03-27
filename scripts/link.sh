#!/bin/bash
# link.sh — Symlink tdc to PATH after npm install
set -e

TDC_HOME="$HOME/.tdc"
LOCAL_BIN="$HOME/.local/bin"

mkdir -p "$LOCAL_BIN"
ln -sf "$TDC_HOME/scripts/tdc" "$LOCAL_BIN/tdc"

echo "[tdc] Linked tdc to $LOCAL_BIN/tdc"
