#!/bin/bash
# TechDog Claude (tdc) — Uninstaller
# Usage: bash uninstall.sh
#   or:  curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/uninstall.sh | bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}TechDog Claude — Uninstaller${NC}"
echo ""

# Determine input source: use /dev/tty if available (works with curl | bash)
TTY_INPUT=""
if [ -t 0 ]; then
    TTY_INPUT="/dev/stdin"
elif [ -e /dev/tty ]; then
    TTY_INPUT="/dev/tty"
fi

# Confirm (skip when no terminal available)
if [ -n "$TTY_INPUT" ]; then
    read -p "tdc를 삭제하시겠습니까? (y/N) " -n 1 -r < "$TTY_INPUT"
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}[tdc]${NC} 삭제를 취소했습니다."
        exit 0
    fi
else
    echo -e "${YELLOW}[tdc]${NC} 파이프 실행 감지 — 확인 없이 진행합니다."
fi

# 1. Remove core skills
SKILLS=(tdc tdc-plan tdc-dev tdc-debug tdc-review tdc-session tdc-learn)
for skill in "${SKILLS[@]}"; do
    if [ -d "$HOME/.claude/skills/$skill" ]; then
        rm -rf "$HOME/.claude/skills/$skill"
        echo -e "${GREEN}[tdc]${NC} Removed skill: $skill"
    fi
done

# 2. Remove skill packs
SKILL_PACKS=(tdc-stack-python-django tdc-stack-ts-nextjs tdc-stack-go tdc-stack-rust tdc-stack-java tdc-stack-flutter tdc-stack-kotlin tdc-stack-react)
for pack in "${SKILL_PACKS[@]}"; do
    if [ -d "$HOME/.claude/skills/$pack" ]; then
        rm -rf "$HOME/.claude/skills/$pack"
        echo -e "${GREEN}[tdc]${NC} Removed skill pack: $pack"
    fi
done

# 3. Remove agents
AGENTS=(master planner developer debugger reviewer security-reviewer test-engineer architect)
for agent in "${AGENTS[@]}"; do
    if [ -f "$HOME/.claude/agents/$agent.md" ]; then
        rm -f "$HOME/.claude/agents/$agent.md"
        echo -e "${GREEN}[tdc]${NC} Removed agent: $agent"
    fi
done

# 4. Remove global tdc directory
if [ -d "$HOME/.tdc" ]; then
    rm -rf "$HOME/.tdc"
    echo -e "${GREEN}[tdc]${NC} Removed ~/.tdc/"
fi

# 5. Clean settings.json (env + hooks)
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$CLAUDE_SETTINGS" ] && command -v python3 &> /dev/null; then
    python3 << 'PYEOF'
import json, os

settings_path = os.path.expanduser("~/.claude/settings.json")
try:
    with open(settings_path) as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    exit(0)

changed = False

# Remove statusLine
if "statusLine" in settings:
    sl = settings.get("statusLine", {})
    if "tdc-status" in sl.get("command", ""):
        del settings["statusLine"]
        changed = True

# Remove env vars
env = settings.get("env", {})
for key in ["TDC_HOME", "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS"]:
    if key in env:
        del env[key]
        changed = True
if env:
    settings["env"] = env
elif "env" in settings:
    del settings["env"]
    changed = True

# Remove all tdc hooks from all hook types
tdc_hook_markers = [
    "context-guard", "session-save", "agent-tracker", "smart-read",
    "tdc-status", "rate-limit-guard", "pre-compact", "rtk-rewrite"
]
hooks = settings.get("hooks", {})
for hook_type in list(hooks.keys()):
    if hook_type in hooks and isinstance(hooks[hook_type], list):
        original_len = len(hooks[hook_type])
        hooks[hook_type] = [
            h for h in hooks[hook_type]
            if not any(
                any(marker in hk.get("command", "") for marker in tdc_hook_markers)
                for hk in h.get("hooks", [])
            )
        ]
        if len(hooks[hook_type]) != original_len:
            changed = True
        if not hooks[hook_type]:
            del hooks[hook_type]

if hooks:
    settings["hooks"] = hooks
elif "hooks" in settings:
    del settings["hooks"]
    changed = True

if changed:
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    print("[tdc] Claude Code settings cleaned")
else:
    print("[tdc] No settings to clean")
PYEOF
else
    echo -e "${YELLOW}[tdc]${NC} settings.json 정리를 건너뜁니다 (python3 필요)"
fi

# 6. Uninstall rtk
REMOVE_RTK="n"
if command -v rtk &> /dev/null; then
    echo ""
    if [ -n "$TTY_INPUT" ]; then
        read -p "rtk(토큰 절감 도구)도 함께 삭제하시겠습니까? (y/N) " -n 1 -r REMOVE_RTK < "$TTY_INPUT"
        echo ""
    else
        REMOVE_RTK="y"
        echo -e "${YELLOW}[tdc]${NC} 파이프 실행 — rtk도 함께 삭제합니다."
    fi

    if [[ "$REMOVE_RTK" =~ ^[Yy]$ ]]; then
        RTK_REMOVED=false

        # Try brew uninstall first
        if command -v brew &> /dev/null && brew list rtk &> /dev/null; then
            brew uninstall rtk 2>/dev/null && RTK_REMOVED=true
        fi

        # Try removing binary directly
        if [ "$RTK_REMOVED" = false ]; then
            RTK_PATH=$(command -v rtk 2>/dev/null)
            if [ -n "$RTK_PATH" ]; then
                rm -f "$RTK_PATH" 2>/dev/null && RTK_REMOVED=true
            fi
        fi

        # Clean up rtk config
        rm -rf "$HOME/.config/rtk" 2>/dev/null || true
        rm -f "$HOME/.rtk.yml" 2>/dev/null || true

        if [ "$RTK_REMOVED" = true ]; then
            echo -e "${GREEN}[tdc]${NC} rtk 삭제 완료"
        else
            echo -e "${YELLOW}[tdc]${NC} rtk 자동 삭제 실패. 수동으로 삭제하세요:"
            echo -e "  brew uninstall rtk"
            echo -e "  또는: rm $(command -v rtk 2>/dev/null)"
        fi
    else
        echo -e "${YELLOW}[tdc]${NC} rtk는 유지합니다. 나중에 삭제하려면: brew uninstall rtk"
    fi
else
    echo -e "${YELLOW}[tdc]${NC} rtk가 설치되어 있지 않습니다."
fi

echo ""
echo -e "${BOLD}${GREEN}tdc가 완전히 삭제되었습니다.${NC}"
