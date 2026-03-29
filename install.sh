#!/bin/bash
# TechDog Claude (tdc) — Remote Installer
# Usage: curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

set -e

TDC_VERSION="1.6.0"
TDC_HOME="$HOME/.tdc"
TDC_REPO_URL="${TDC_REPO_URL:-https://github.com/dogyuHwang/techdog-claude}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}"
cat << 'BANNER'
  _____ _____ ____ _   _ ____   ___   ____
 |_   _| ____/ ___| | | |  _ \ / _ \ / ___|
   | | |  _|| |   | |_| | | | | | | | |  _
   | | | |__| |___|  _  | |_| | |_| | |_| |
   |_| |_____\____|_| |_|____/ \___/ \____|
         Claude Code Orchestrator v1.6.0
BANNER
echo -e "${NC}"

# Detect OS
OS="$(uname -s)"
case "$OS" in
    Linux*)  PLATFORM="linux" ;;
    Darwin*) PLATFORM="mac" ;;
    *)       echo -e "${RED}[tdc]${NC} Unsupported OS: $OS"; exit 1 ;;
esac
echo -e "${GREEN}[tdc]${NC} Detected platform: $PLATFORM"

# Ensure ~/.local/bin is in PATH for this session (rtk installs here)
export PATH="$HOME/.local/bin:$PATH"

# Check prerequisites
check_prereq() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}[tdc]${NC} Required: $1 not found. Please install it first."
        return 1
    fi
}

check_prereq "git" || exit 1
check_prereq "claude" || echo -e "${YELLOW}[tdc]${NC} Warning: Claude Code CLI not found. Install with: npm install -g @anthropic-ai/claude-code"

# Install RTK (token optimizer)
install_rtk() {
    if command -v rtk &> /dev/null; then
        echo -e "${GREEN}[tdc]${NC} rtk already installed: $(rtk --version 2>/dev/null)"
        return
    fi

    echo -e "${BLUE}[tdc]${NC} Installing rtk (token optimizer)..."

    if command -v brew &> /dev/null; then
        brew install rtk 2>/dev/null && echo -e "${GREEN}[tdc]${NC} rtk installed via brew" && return
    fi

    # Fallback: install script
    if curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh 2>/dev/null; then
        export PATH="$HOME/.local/bin:$PATH"
        echo -e "${GREEN}[tdc]${NC} rtk installed via install script"
    else
        echo -e "${YELLOW}[tdc]${NC} rtk auto-install failed. Install manually:"
        echo "  brew install rtk"
        echo "  or: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
    fi
}

setup_rtk() {
    export PATH="$HOME/.local/bin:$PATH"

    if command -v rtk &> /dev/null; then
        echo -e "${BLUE}[tdc]${NC} Configuring rtk for Claude Code..."
        rtk init -g 2>/dev/null && echo -e "${GREEN}[tdc]${NC} rtk configured for Claude Code" || true
    fi
}

# Main installation
install_tdc() {
    echo -e "${BLUE}[tdc]${NC} Installing to $TDC_HOME..."

    # Create TDC home
    mkdir -p "$TDC_HOME"/{hooks,state/sessions,state/context}

    # Clone or update repo
    if [ -d "$TDC_HOME/.repo" ]; then
        echo -e "${BLUE}[tdc]${NC} Updating existing installation..."
        cd "$TDC_HOME/.repo" && git pull --quiet 2>/dev/null || true
        cd - > /dev/null
    else
        echo -e "${BLUE}[tdc]${NC} Downloading TechDog Claude..."
        if git ls-remote "$TDC_REPO_URL" &>/dev/null; then
            git clone --quiet "$TDC_REPO_URL" "$TDC_HOME/.repo"
        else
            echo -e "${YELLOW}[tdc]${NC} Repo not accessible. Using local files."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            mkdir -p "$TDC_HOME/.repo"
            cp -r "$SCRIPT_DIR"/* "$TDC_HOME/.repo/" 2>/dev/null || true
            cp -r "$SCRIPT_DIR"/.claude "$TDC_HOME/.repo/" 2>/dev/null || true
            cp -r "$SCRIPT_DIR"/.gitignore "$TDC_HOME/.repo/" 2>/dev/null || true
        fi
    fi

    # Copy hooks to TDC home
    cp -r "$TDC_HOME/.repo/.claude/hooks/"* "$TDC_HOME/hooks/" 2>/dev/null || true
    chmod +x "$TDC_HOME/hooks/"* 2>/dev/null || true

    # Install skills & agents to Claude Code global path (~/.claude/)
    CLAUDE_DIR="$HOME/.claude"
    mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"
    cp -r "$TDC_HOME/.repo/.claude/skills/"* "$CLAUDE_DIR/skills/" 2>/dev/null || true
    cp -r "$TDC_HOME/.repo/.claude/agents/"* "$CLAUDE_DIR/agents/" 2>/dev/null || true
    echo -e "${GREEN}[tdc]${NC} Skills & agents installed to $CLAUDE_DIR/"

    # Configure Claude Code settings
    setup_claude_settings

    # Install and configure rtk
    install_rtk
    setup_rtk

    echo -e "${GREEN}[tdc]${NC} Installation complete!"
}

setup_claude_settings() {
    CLAUDE_SETTINGS="$HOME/.claude/settings.json"

    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        echo '{}' > "$CLAUDE_SETTINGS"
    fi

    python3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
tdc_home = os.path.expanduser("~/.tdc")

try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

# Add environment variables
env = settings.get("env", {})
env["TDC_HOME"] = tdc_home
env["CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"] = "1"
settings["env"] = env

# Remove old invalid hook format if present
hooks = settings.get("hooks", {})
if "postToolExecution" in hooks:
    del hooks["postToolExecution"]

# Add PostToolUse hook (correct Claude Code format)
if "PostToolUse" not in hooks:
    hooks["PostToolUse"] = []

tdc_hook_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/context-guard.sh"
        }
    ]
}

existing = [h for h in hooks.get("PostToolUse", [])
            if any("context-guard" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing:
    hooks["PostToolUse"].append(tdc_hook_entry)

# Add Stop hook for session auto-save
if "Stop" not in hooks:
    hooks["Stop"] = []

session_hook_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/session-save.sh"
        }
    ]
}

existing_session = [h for h in hooks.get("Stop", [])
                    if any("session-save" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_session:
    hooks["Stop"].append(session_hook_entry)

# Add SubagentStart hook for agent tracking
if "SubagentStart" not in hooks:
    hooks["SubagentStart"] = []

agent_start_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/agent-tracker.sh"
        }
    ]
}

existing_agent_start = [h for h in hooks.get("SubagentStart", [])
                        if any("agent-tracker" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_agent_start:
    hooks["SubagentStart"].append(agent_start_entry)

# Add SubagentStop hook for agent tracking
if "SubagentStop" not in hooks:
    hooks["SubagentStop"] = []

agent_stop_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/agent-tracker.sh"
        }
    ]
}

existing_agent_stop = [h for h in hooks.get("SubagentStop", [])
                       if any("agent-tracker" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_agent_stop:
    hooks["SubagentStop"].append(agent_stop_entry)

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("[tdc] Claude Code settings updated")
PYEOF
}

# Run installation
install_tdc

echo ""
echo -e "${BOLD}${GREEN}=== TechDog Claude v${TDC_VERSION} installed successfully! ===${NC}"
echo ""
echo -e "  ${BOLD}${GREEN}바로 시작하세요!${NC}"
echo -e ""
echo -e "    ${BOLD}claude${NC} 실행 → ${BOLD}/tdc spec.md${NC} 입력  ← 지금 바로 됩니다!"
echo -e ""
echo -e "  ${BOLD}Quick Start:${NC}"
echo -e "    1. 만들고 싶은 것을 spec.md로 작성"
echo -e "    2. 터미널에서 ${BOLD}claude${NC} 입력"
echo -e "    3. Claude Code 안에서 ${BOLD}/tdc spec.md${NC}"
echo -e ""
if command -v rtk &> /dev/null; then
    echo -e "  rtk: ${GREEN}$(rtk --version 2>/dev/null)${NC} — 토큰 60-90% 절감 활성화"
fi
echo ""
