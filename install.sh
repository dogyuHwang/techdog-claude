#!/bin/bash
# TechDog Claude (tdc) — Remote Installer
# Usage: curl -sSL https://raw.githubusercontent.com/<user>/techdog-claude/main/install.sh | bash
# Or:    bash install.sh [--global|--local]

set -e

TDC_VERSION="1.0.0"
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
         Claude Code Orchestrator v1.0.0
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
        echo -e "${GREEN}[tdc]${NC} rtk installed via install script"
    else
        echo -e "${YELLOW}[tdc]${NC} rtk auto-install failed. Install manually:"
        echo "  brew install rtk"
        echo "  or: curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh | sh"
    fi
}

setup_rtk() {
    if command -v rtk &> /dev/null; then
        echo -e "${BLUE}[tdc]${NC} Configuring rtk for Claude Code..."
        rtk init -g 2>/dev/null && echo -e "${GREEN}[tdc]${NC} rtk configured for Claude Code" || true
    fi
}

# Install mode
MODE="${1:---global}"

install_global() {
    echo -e "${BLUE}[tdc]${NC} Installing globally to $TDC_HOME..."

    # Create TDC home
    mkdir -p "$TDC_HOME"/{agents,skills,hooks,scripts,state/sessions,state/context}

    # Clone or update repo
    if [ -d "$TDC_HOME/.repo" ]; then
        echo -e "${BLUE}[tdc]${NC} Updating existing installation..."
        cd "$TDC_HOME/.repo" && git pull --quiet 2>/dev/null || true
        cd - > /dev/null
    else
        echo -e "${BLUE}[tdc]${NC} Downloading TechDog Claude..."
        # If repo exists, clone it; otherwise copy from local
        if git ls-remote "$TDC_REPO_URL" &>/dev/null; then
            git clone --quiet "$TDC_REPO_URL" "$TDC_HOME/.repo"
        else
            echo -e "${YELLOW}[tdc]${NC} Repo not accessible. Using local install mode."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            mkdir -p "$TDC_HOME/.repo"
            cp -r "$SCRIPT_DIR"/* "$TDC_HOME/.repo/" 2>/dev/null || true
            cp -r "$SCRIPT_DIR"/.claude "$TDC_HOME/.repo/" 2>/dev/null || true
            cp -r "$SCRIPT_DIR"/.gitignore "$TDC_HOME/.repo/" 2>/dev/null || true
        fi
    fi

    # Copy files to TDC home
    cp -r "$TDC_HOME/.repo/.claude/agents/"* "$TDC_HOME/agents/" 2>/dev/null || true
    cp -r "$TDC_HOME/.repo/.claude/skills/"* "$TDC_HOME/skills/" 2>/dev/null || true
    cp -r "$TDC_HOME/.repo/.claude/hooks/"* "$TDC_HOME/hooks/" 2>/dev/null || true
    cp -r "$TDC_HOME/.repo/scripts/"* "$TDC_HOME/scripts/" 2>/dev/null || true

    # Make scripts executable
    chmod +x "$TDC_HOME/scripts/"* 2>/dev/null || true
    chmod +x "$TDC_HOME/hooks/"* 2>/dev/null || true

    # Install tdc CLI to PATH
    TDC_BIN="$TDC_HOME/scripts/tdc"
    chmod +x "$TDC_BIN"

    # Add to PATH
    LOCAL_BIN="$HOME/.local/bin"
    mkdir -p "$LOCAL_BIN"
    ln -sf "$TDC_BIN" "$LOCAL_BIN/tdc"

    # Check if PATH includes local bin
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        SHELL_RC=""
        if [ -f "$HOME/.zshrc" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_RC="$HOME/.bashrc"
        fi

        if [ -n "$SHELL_RC" ]; then
            if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
                echo '' >> "$SHELL_RC"
                echo '# TechDog Claude' >> "$SHELL_RC"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
                echo 'export TDC_HOME="$HOME/.tdc"' >> "$SHELL_RC"
                echo -e "${YELLOW}[tdc]${NC} Added PATH to $SHELL_RC — run 'source $SHELL_RC' or restart terminal"
            fi
        fi
    fi

    # Configure Claude Code settings
    setup_claude_settings

    # Install and configure rtk
    install_rtk
    setup_rtk

    echo -e "${GREEN}[tdc]${NC} Global installation complete!"
}

install_local() {
    echo -e "${BLUE}[tdc]${NC} Installing to current project..."

    PROJECT_DIR="$(pwd)"

    # Copy .claude directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    mkdir -p "$PROJECT_DIR/.claude"/{agents,skills,hooks}
    mkdir -p "$PROJECT_DIR/.tdc"/{sessions,context,plans}

    cp -r "$SCRIPT_DIR/.claude/agents/"* "$PROJECT_DIR/.claude/agents/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/.claude/skills/"* "$PROJECT_DIR/.claude/skills/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/.claude/hooks/"* "$PROJECT_DIR/.claude/hooks/" 2>/dev/null || true

    chmod +x "$PROJECT_DIR/.claude/hooks/"* 2>/dev/null || true

    echo -e "${GREEN}[tdc]${NC} Local installation complete in $PROJECT_DIR"
}

setup_claude_settings() {
    CLAUDE_SETTINGS="$HOME/.claude/settings.json"

    # Create settings if not exists
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
        echo '{}' > "$CLAUDE_SETTINGS"
    fi

    # Add TDC configuration using python3 (available on both mac & linux)
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

# Add hooks for context monitoring
hooks = settings.get("hooks", {})

# Add tool execution hook for context guard
if "postToolExecution" not in hooks:
    hooks["postToolExecution"] = []

tdc_hook = {
    "type": "command",
    "command": f"bash {tdc_home}/hooks/context-guard.sh",
    "description": "TDC context monitor"
}

# Check if hook already exists
existing = [h for h in hooks.get("postToolExecution", []) if "context-guard" in h.get("command", "")]
if not existing:
    hooks["postToolExecution"].append(tdc_hook)

settings["hooks"] = hooks

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("[tdc] Claude Code settings updated")
PYEOF
}

# Main
case "$MODE" in
    --local|-l)  install_local ;;
    --global|-g|*) install_global ;;
esac

echo ""
echo -e "${BOLD}${GREEN}=== TechDog Claude installed successfully! ===${NC}"
echo ""
echo -e "  ${BOLD}Quick Start:${NC}"
echo -e "    1. 프로젝트 폴더에서: tdc init"
echo -e "    2. 만들고 싶은 것을 spec.md로 작성"
echo -e "    3. 터미널에서 'claude' 입력하여 Claude Code 실행"
echo -e "    4. Claude Code 안에서: /tdc spec.md"
echo -e ""
echo -e "  ${BOLD}Token Optimization:${NC}"
if command -v rtk &> /dev/null; then
    echo -e "    rtk: ${GREEN}installed${NC} — 토큰 60-90% 절감 활성화"
    echo -e "    rtk gain    절감량 확인"
else
    echo -e "    rtk: ${YELLOW}not installed${NC} — 설치하면 토큰 추가 절감 가능"
fi
echo ""
