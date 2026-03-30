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

# Confirm
read -p "tdc를 삭제하시겠습니까? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}[tdc]${NC} 삭제를 취소했습니다."
    exit 0
fi

# 1. Remove skills
SKILLS=(tdc tdc-plan tdc-dev tdc-debug tdc-review tdc-session)
for skill in "${SKILLS[@]}"; do
    if [ -d "$HOME/.claude/skills/$skill" ]; then
        rm -rf "$HOME/.claude/skills/$skill"
        echo -e "${GREEN}[tdc]${NC} Removed skill: $skill"
    fi
done

# 2. Remove agents
AGENTS=(master planner developer debugger reviewer architect)
for agent in "${AGENTS[@]}"; do
    if [ -f "$HOME/.claude/agents/$agent.md" ]; then
        rm -f "$HOME/.claude/agents/$agent.md"
        echo -e "${GREEN}[tdc]${NC} Removed agent: $agent"
    fi
done

# 3. Remove global tdc directory
if [ -d "$HOME/.tdc" ]; then
    rm -rf "$HOME/.tdc"
    echo -e "${GREEN}[tdc]${NC} Removed ~/.tdc/"
fi

# 4. Clean settings.json (env + hooks)
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
tdc_hook_markers = ["context-guard", "session-save", "agent-tracker", "smart-read", "tdc-status"]
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

echo ""
echo -e "${BOLD}${GREEN}tdc가 완전히 삭제되었습니다.${NC}"
echo -e "  rtk는 별도 도구이므로 삭제하지 않았습니다."
echo -e "  rtk도 삭제하려면: ${BOLD}brew uninstall rtk${NC}"
