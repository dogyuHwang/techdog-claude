#!/bin/bash
# TechDog Claude (tdc) — Remote Installer
# Usage: curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

set -e

# Version is derived from package.json after clone/pull (see resolve_tdc_version).
# This fallback is only used if package.json cannot be read.
TDC_VERSION="unknown"
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
         Claude Code Orchestrator
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

# Install jq (required by rtk hook)
install_jq() {
    if command -v jq &> /dev/null; then
        echo -e "${GREEN}[tdc]${NC} jq already installed: $(jq --version 2>/dev/null)"
        return
    fi

    echo -e "${BLUE}[tdc]${NC} Installing jq (required by rtk hook)..."
    if [ "$PLATFORM" = "mac" ]; then
        if command -v brew &> /dev/null; then
            brew install jq 2>/dev/null && echo -e "${GREEN}[tdc]${NC} jq installed via brew" && return
        fi
    else
        # Linux: try apt, yum, dnf, pacman
        if command -v apt-get &> /dev/null; then
            sudo apt-get install -y jq 2>/dev/null && echo -e "${GREEN}[tdc]${NC} jq installed via apt" && return
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq 2>/dev/null && echo -e "${GREEN}[tdc]${NC} jq installed via yum" && return
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y jq 2>/dev/null && echo -e "${GREEN}[tdc]${NC} jq installed via dnf" && return
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm jq 2>/dev/null && echo -e "${GREEN}[tdc]${NC} jq installed via pacman" && return
        fi
    fi

    echo -e "${YELLOW}[tdc]${NC} Could not auto-install jq. Please install manually:"
    echo -e "  macOS: brew install jq"
    echo -e "  Ubuntu/Debian: sudo apt-get install -y jq"
    echo -e "  Fedora: sudo dnf install -y jq"
    echo -e "  Arch: sudo pacman -S jq"
    echo -e "${YELLOW}[tdc]${NC} Without jq, rtk token compression will not work."
}

install_jq

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

# Skill pack definitions
SKILL_PACKS=(
    "tdc-stack-python-django:Python + Django"
    "tdc-stack-ts-nextjs:TypeScript + Next.js"
    "tdc-stack-go:Go"
    "tdc-stack-rust:Rust"
    "tdc-stack-java:Java + Spring Boot"
    "tdc-stack-flutter:Flutter + Dart"
    "tdc-stack-kotlin:Kotlin (Android/Ktor)"
    "tdc-stack-react:React + TypeScript"
)

# Skill pack selection UI
select_skill_packs() {
    echo ""
    echo -e "${BOLD}${BLUE}=== 개발언어 Skill Pack Installation ===${NC}"
    echo ""
    echo -e "  tdc에는 개발언어별 스킬팩이 포함되어 있습니다."
    echo -e "  에이전트가 해당 언어/프레임워크 프로젝트에서 더 정확하게 작업합니다."
    echo ""
    echo -e "  ${BOLD}1)${NC} 전체 설치 (All skill packs)"
    echo -e "  ${BOLD}2)${NC} 선택 설치 (Choose individually)"
    echo -e "  ${BOLD}3)${NC} 스킬팩 없이 설치 (Core only)"
    echo ""

    # Determine input source: use /dev/tty if available (works with curl | bash)
    TTY_INPUT=""
    if [ -t 0 ]; then
        TTY_INPUT="/dev/stdin"
    elif [ -e /dev/tty ]; then
        TTY_INPUT="/dev/tty"
    fi

    # Non-interactive mode: no terminal available at all
    if [ -z "$TTY_INPUT" ]; then
        echo -e "${BLUE}[tdc]${NC} Non-interactive mode: installing all 개발언어 skill packs"
        SELECTED_PACKS=("${SKILL_PACKS[@]}")
        return
    fi

    read -r -p "  선택 (1/2/3) [1]: " PACK_CHOICE < "$TTY_INPUT"
    PACK_CHOICE="${PACK_CHOICE:-1}"

    case "$PACK_CHOICE" in
        1)
            SELECTED_PACKS=("${SKILL_PACKS[@]}")
            echo -e "${GREEN}[tdc]${NC} All skill packs selected"
            ;;
        2)
            SELECTED_PACKS=()
            echo ""
            echo -e "  각 스킬팩을 선택하세요 (y/n):"
            echo ""
            for i in "${!SKILL_PACKS[@]}"; do
                IFS=':' read -r dir_name display_name <<< "${SKILL_PACKS[$i]}"
                read -r -p "  [y/n] ${display_name}? [y]: " yn < "$TTY_INPUT"
                yn="${yn:-y}"
                if [[ "$yn" =~ ^[yY] ]]; then
                    SELECTED_PACKS+=("${SKILL_PACKS[$i]}")
                    echo -e "    ${GREEN}+${NC} ${display_name}"
                else
                    echo -e "    ${YELLOW}-${NC} ${display_name} (skipped)"
                fi
            done
            echo ""
            echo -e "${GREEN}[tdc]${NC} ${#SELECTED_PACKS[@]} skill packs selected"
            ;;
        3)
            SELECTED_PACKS=()
            echo -e "${YELLOW}[tdc]${NC} Skipping skill packs (core only)"
            ;;
        *)
            SELECTED_PACKS=("${SKILL_PACKS[@]}")
            echo -e "${GREEN}[tdc]${NC} All skill packs selected (default)"
            ;;
    esac
}

# Main installation
install_tdc() {
    echo -e "${BLUE}[tdc]${NC} Installing to $TDC_HOME..."

    # Create TDC home
    mkdir -p "$TDC_HOME"/{hooks,state/sessions,state/context}

    # Clone or update repo
    if [ -d "$TDC_HOME/.repo/.git" ]; then
        echo -e "${BLUE}[tdc]${NC} Updating existing installation..."
        # Force sync to origin/main — discards any local changes in .repo
        # (mirrors /tdc-upgrade behavior for consistency)
        if ! (cd "$TDC_HOME/.repo" && git fetch --quiet origin main && git reset --quiet --hard origin/main); then
            echo -e "${YELLOW}[tdc]${NC} Git sync failed. Retrying with fresh clone..."
            rm -rf "$TDC_HOME/.repo"
            git clone --quiet "$TDC_REPO_URL" "$TDC_HOME/.repo"
        fi
    else
        echo -e "${BLUE}[tdc]${NC} Downloading TechDog Claude..."
        rm -rf "$TDC_HOME/.repo" 2>/dev/null || true
        if git ls-remote "$TDC_REPO_URL" &>/dev/null; then
            git clone --quiet "$TDC_REPO_URL" "$TDC_HOME/.repo"
        else
            echo -e "${YELLOW}[tdc]${NC} Repo not accessible. Using local files."
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            mkdir -p "$TDC_HOME/.repo"
            cp -r "$SCRIPT_DIR"/* "$TDC_HOME/.repo/" 2>/dev/null || true
            cp -r "$SCRIPT_DIR"/.gitignore "$TDC_HOME/.repo/" 2>/dev/null || true
        fi
    fi

    # Resolve actual version from package.json (source of truth)
    if [ -f "$TDC_HOME/.repo/package.json" ]; then
        if command -v jq &>/dev/null; then
            TDC_VERSION=$(jq -r .version "$TDC_HOME/.repo/package.json" 2>/dev/null || echo "unknown")
        else
            TDC_VERSION=$(grep -oE '"version"\s*:\s*"[^"]+"' "$TDC_HOME/.repo/package.json" | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
        fi
    fi

    # Copy hooks to TDC home
    cp -r "$TDC_HOME/.repo/hooks/"* "$TDC_HOME/hooks/" 2>/dev/null || true
    chmod +x "$TDC_HOME/hooks/"* 2>/dev/null || true

    # Install core skills & agents to Claude Code global path (~/.claude/)
    CLAUDE_DIR="$HOME/.claude"
    mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents"

    # Core skills (always installed)
    for core_skill in tdc tdc-plan tdc-dev tdc-debug tdc-review tdc-deep tdc-learn \
                      tdc-save tdc-resume tdc-clean tdc-upgrade tdc-version; do
        if [ -d "$TDC_HOME/.repo/skills/$core_skill" ]; then
            cp -r "$TDC_HOME/.repo/skills/$core_skill" "$CLAUDE_DIR/skills/" 2>/dev/null || true
        fi
    done

    # Remove deprecated skills (tdc-onboard merged into tdc-learn; tdc-session split)
    rm -rf "$CLAUDE_DIR/skills/tdc-onboard" "$CLAUDE_DIR/skills/tdc-session" 2>/dev/null || true

    # Agents (always installed)
    cp -r "$TDC_HOME/.repo/agents/"* "$CLAUDE_DIR/agents/" 2>/dev/null || true
    echo -e "${GREEN}[tdc]${NC} Core skills & agents installed to $CLAUDE_DIR/"

    # Skill pack selection — skip on upgrade if packs already exist
    EXISTING_PACKS=$(ls -d "$CLAUDE_DIR/skills/tdc-stack-"* 2>/dev/null | wc -l)
    if [ "$EXISTING_PACKS" -gt 0 ]; then
        echo -e "${BLUE}[tdc]${NC} Existing skill packs detected ($EXISTING_PACKS). Updating in-place..."
        # Update existing packs from repo without re-asking
        UPDATE_COUNT=0
        for pack_dir in "$CLAUDE_DIR/skills/tdc-stack-"*; do
            pack_name=$(basename "$pack_dir")
            if [ -d "$TDC_HOME/.repo/skills/$pack_name" ]; then
                cp -r "$TDC_HOME/.repo/skills/$pack_name" "$CLAUDE_DIR/skills/" 2>/dev/null || true
                UPDATE_COUNT=$((UPDATE_COUNT + 1))
            fi
        done
        echo -e "${GREEN}[tdc]${NC} $UPDATE_COUNT skill packs updated"
    else
        # Fresh install — show skill pack selection
        select_skill_packs

        # Install selected skill packs
        PACK_COUNT=0
        for pack in "${SELECTED_PACKS[@]}"; do
            IFS=':' read -r dir_name display_name <<< "$pack"
            if [ -d "$TDC_HOME/.repo/skills/$dir_name" ]; then
                cp -r "$TDC_HOME/.repo/skills/$dir_name" "$CLAUDE_DIR/skills/" 2>/dev/null || true
                PACK_COUNT=$((PACK_COUNT + 1))
            fi
        done
        if [ "$PACK_COUNT" -gt 0 ]; then
            echo -e "${GREEN}[tdc]${NC} $PACK_COUNT skill packs installed"
        fi
    fi

    # Install and configure rtk (BEFORE settings, so hook registration finds rtk)
    install_rtk
    setup_rtk

    # Configure Claude Code settings (rtk must be installed first for hook registration)
    setup_claude_settings

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

# Add statusLine for tdc-status.sh
settings["statusLine"] = {
    "type": "command",
    "command": f"bash {tdc_home}/hooks/tdc-status.sh",
    "padding": 2
}

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

# Add Smart Read hook (PostToolUse matcher: Read)
smart_read_entry = {
    "matcher": "Read",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/smart-read.sh"
        }
    ]
}

existing_smart_read = [h for h in hooks.get("PostToolUse", [])
                       if any("smart-read" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_smart_read:
    hooks["PostToolUse"].append(smart_read_entry)

# Add Rate Limit Guard hook (PostToolUse)
rate_limit_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/rate-limit-guard.sh"
        }
    ]
}

existing_rate_limit = [h for h in hooks.get("PostToolUse", [])
                       if any("rate-limit-guard" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_rate_limit:
    hooks["PostToolUse"].append(rate_limit_entry)

# Add PostToolUse hook for rtk tee recovery (Bash-only)
rtk_tee_entry = {
    "matcher": "Bash",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/rtk-tee-recovery.sh"
        }
    ]
}
existing_rtk_tee = [h for h in hooks.get("PostToolUse", [])
                    if any("rtk-tee-recovery" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_rtk_tee:
    hooks["PostToolUse"].append(rtk_tee_entry)
    print("[tdc] rtk-tee-recovery PostToolUse hook registered")

# Add PreCompact hook for context compaction survival
if "PreCompact" not in hooks:
    hooks["PreCompact"] = []

pre_compact_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/pre-compact.sh"
        }
    ]
}

existing_pre_compact = [h for h in hooks.get("PreCompact", [])
                        if any("pre-compact" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_pre_compact:
    hooks["PreCompact"].append(pre_compact_entry)

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

# Add Stop hook for token display summary (fires after every response)
token_display_entry = {
    "matcher": "",
    "hooks": [
        {
            "type": "command",
            "command": f"bash {tdc_home}/hooks/token-display.sh"
        }
    ]
}

existing_token_display = [h for h in hooks.get("Stop", [])
                          if any("token-display" in hk.get("command", "") for hk in h.get("hooks", []))]
if not existing_token_display:
    hooks["Stop"].append(token_display_entry)
    print("[tdc] token-display Stop hook registered")

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

# Add PreToolUse hook for rtk
# Register unconditionally — rtk-rewrite.sh handles missing rtk gracefully (exit 0)
rtk_hook_path = os.path.expanduser("~/.claude/hooks/rtk-rewrite.sh")
if os.path.exists(rtk_hook_path):
    if "PreToolUse" not in hooks:
        hooks["PreToolUse"] = []

    rtk_entry = {
        "matcher": "Bash",
        "hooks": [
            {
                "type": "command",
                "command": rtk_hook_path
            }
        ]
    }

    existing_rtk = [h for h in hooks.get("PreToolUse", [])
                    if any("rtk-rewrite" in hk.get("command", "") for hk in h.get("hooks", []))]
    if not existing_rtk:
        hooks["PreToolUse"].append(rtk_entry)
        print("[tdc] rtk PreToolUse hook registered in settings.json")

settings["hooks"] = hooks

# Add .tdc/ auto-allow permission rules
permissions = settings.get("permissions", {})
allow_list = permissions.get("allow", [])

tdc_allow_rules = [
    # Bash: .tdc/ directory operations
    "Bash(mkdir -p .tdc/*)",
    "Bash(echo * > .tdc/**)",
    "Bash(echo * >> .tdc/**)",
    "Bash(cat .tdc/**)",
    "Bash(rm -f .tdc/**)",
    "Bash(ls .tdc*)",
    # Bash: common tdc pipeline commands (syntax check, git diff, etc.)
    "Bash(bash -n *)",
    "Bash(git diff*)",
    "Bash(git status*)",
    "Bash(git log*)",
    "Bash(git add*)",
    "Bash(git checkout -- *)",
    # Read/Write: .tdc/ state files
    "Read(.tdc/**)",
    "Write(.tdc/sessions/**)",
    "Write(.tdc/context/**)",
    "Write(.tdc/plans/**)",
    "Write(.tdc/learned-skills/**)",
    "Write(.tdc/project-memory.md)",
]

for rule in tdc_allow_rules:
    if rule not in allow_list:
        allow_list.append(rule)

permissions["allow"] = allow_list
settings["permissions"] = permissions

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)

print("[tdc] Claude Code settings updated (hooks + permissions)")
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
echo -e "  ${BOLD}Installed:${NC}"
echo -e "    Agents: 9 (master, planner, developer, debugger, reviewer, security-reviewer, test-engineer, architect, meta-reviewer)"
echo -e "    Core skills: 12 (/tdc, /tdc-plan, /tdc-dev, /tdc-debug, /tdc-review, /tdc-deep, /tdc-learn, /tdc-save, /tdc-resume, /tdc-clean, /tdc-upgrade, /tdc-version)"
if [ "${#SELECTED_PACKS[@]}" -gt 0 ]; then
    PACK_NAMES=""
    for pack in "${SELECTED_PACKS[@]}"; do
        IFS=':' read -r _ display_name <<< "$pack"
        [ -n "$PACK_NAMES" ] && PACK_NAMES="$PACK_NAMES, "
        PACK_NAMES="$PACK_NAMES$display_name"
    done
    echo -e "    개발언어 스킬팩: ${#SELECTED_PACKS[@]}개 ($PACK_NAMES)"
fi
if command -v rtk &> /dev/null; then
    echo -e "    rtk: ${GREEN}$(rtk --version 2>/dev/null)${NC} — 토큰 60-90% 절감 활성화"
fi
echo ""
