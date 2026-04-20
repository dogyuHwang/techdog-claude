---
name: tdc-upgrade
description: "TechDog Claude - 최신 버전으로 업그레이드 (스킬·에이전트·훅 갱신, 프로젝트 데이터 보존)"
user-invocable: true
argument-hint: ""
---

**입력:** $ARGUMENTS

# /tdc-upgrade — Upgrade tdc

`~/.tdc/.repo`를 최신 main으로 갱신하고 Claude Code에 설치된 스킬/에이전트/훅을 전부 교체합니다.

## 실행 흐름

### 1단계: 설치 여부 확인

1. `~/.tdc/.repo`가 있는지 확인
2. 없으면 → `"tdc가 설치되어 있지 않습니다. install.sh를 먼저 실행하세요."` 안내 후 종료

### 2단계: 현재 버전 확인

```bash
OLD_VERSION=$(jq -r .version ~/.tdc/.repo/package.json)
```

### 3단계: 최신 소스 가져오기

```bash
cd ~/.tdc/.repo && git fetch origin main && git reset --hard origin/main
```

### 4단계: 새 버전 확인 및 동일 버전 처리

```bash
NEW_VERSION=$(jq -r .version ~/.tdc/.repo/package.json)
```

`OLD_VERSION == NEW_VERSION`이면 `[TDC] Already up to date (vX.Y.Z)` 출력 후 종료.

### 5단계: 파일 복사

```bash
# 코어 스킬 복사
for s in tdc tdc-plan tdc-dev tdc-debug tdc-review tdc-deep tdc-learn \
         tdc-save tdc-resume tdc-clean tdc-upgrade tdc-version; do
    cp -r ~/.tdc/.repo/.claude/skills/$s ~/.claude/skills/ 2>/dev/null || true
done

# 구버전 잔재 제거
rm -rf ~/.claude/skills/tdc-onboard ~/.claude/skills/tdc-session 2>/dev/null || true

# 에이전트 & 훅
cp -r ~/.tdc/.repo/.claude/agents/*.md ~/.claude/agents/
cp -r ~/.tdc/.repo/.claude/hooks/* ~/.tdc/hooks/
chmod +x ~/.tdc/hooks/*
```

### 6단계: settings.json 패치

`install.sh`의 `setup_claude_settings()` Python 블록을 실행하여 hooks/permissions 최신화.

### 7단계: 결과 표시

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] UPGRADE COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  버전:  vOLD → vNEW
  스킬·에이전트·훅이 모든 프로젝트에 적용되었습니다.
  프로젝트별 .tdc/ 데이터는 보존됩니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 주의사항

- **스킬팩**(`tdc-stack-*`)은 업그레이드하지 않음 (사용자가 선택 설치한 것, install.sh 재실행 시 갱신)
- **rtk**는 건드리지 않음 (별도 업그레이드 필요)
- **프로젝트별 `.tdc/`** 는 건드리지 않음 (세션/플랜/학습 스킬 보존)
