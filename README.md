# TechDog Claude (tdc)

> Claude Code를 위한 멀티 에이전트 개발 오케스트레이션 시스템

개발 워크플로우에 최적화된 Claude Code 멀티 에이전트 아키텍처입니다.
Master Agent가 팀 리더로서 기획, 개발, 디버깅, 리뷰, 아키텍처 에이전트를 조율하며,
토큰을 최적화하고 세션을 자동 관리합니다.

## Features

- **Multi-Agent Team** — Master 오케스트레이터 + 5개 전문 에이전트 (planner, developer, debugger, reviewer, architect)
- **Token Optimization** — 3티어 모델 라우팅 (haiku/sonnet/opus), 컨텍스트 압축, 지연 로딩
- **Session Management** — 컨텍스트 오버플로 시 자동 저장, 세션 간 원활한 재개
- **Team Mode** — Claude Code Team 모드 + 병렬 에이전트 실행
- **Cross-Platform** — macOS & Linux 지원
- **`tdc` CLI** — 터미널 명령어 + Claude Code 슬래시 커맨드

## Quick Install

```bash
# 원격 설치 (글로벌)
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

# 로컬 설치 (현재 프로젝트만)
bash install.sh --local

# 클론 후 설치
git clone https://github.com/dogyuHwang/techdog-claude.git
cd techdog-claude && bash install.sh
```

## Usage

### Terminal CLI

```bash
tdc plan "OAuth2 인증 추가"           # 기획 워크플로우
tdc dev "로그인 API 엔드포인트 구현"    # 개발 워크플로우
tdc debug "user service line 42 TypeError"  # 디버깅 워크플로우
tdc review                             # 코드 리뷰
tdc session list                       # 세션 목록
tdc session resume                     # 마지막 세션 재개
tdc status                             # 컨텍스트 상태 확인
tdc init                               # 프로젝트에 .tdc/ 초기화
```

### Claude Code Slash Commands

Claude Code 안에서 직접 사용:

```
/tdc <task>           메인 오케스트레이터 — 태스크 분석 후 적절한 에이전트에 위임
/tdc-plan <desc>      기획 워크플로우 — 요구사항 분석, 태스크 분해, PRD
/tdc-dev <desc>       개발 워크플로우 — 코드 구현, 테스트
/tdc-debug <desc>     디버깅 워크플로우 — 버그 진단, 근본 원인 분석, 수정
/tdc-review [files]   코드 리뷰 — 보안, 품질, 스타일 체크
/tdc-session <cmd>    세션 관리 — save / resume / list / clean
```

## Example: Flask 서버 만들기

"간단한 Flask REST API 서버를 만들고 싶다"는 상황을 예시로 전체 워크플로우를 보여줍니다.

### Step 1. 기획 — `/tdc-plan`

Claude Code에서 다음과 같이 입력합니다:

```
/tdc-plan 간단한 Flask REST API 서버. 유저 CRUD + 헬스체크 엔드포인트. SQLite 사용.
```

**Planner Agent (sonnet)** 가 요구사항을 분석하고 태스크를 분해합니다:

```markdown
## Plan: Flask User CRUD API

### Goal
SQLite 기반 Flask REST API 서버 구축 (User CRUD + 헬스체크)

### Tasks
1. [ ] 프로젝트 초기화 (requirements.txt, app.py) — complexity: low — agent: developer
2. [ ] SQLite DB 모델 정의 (User 테이블) — complexity: low — agent: developer
3. [ ] CRUD 엔드포인트 구현 (GET/POST/PUT/DELETE /users) — complexity: mid — agent: developer
4. [ ] 헬스체크 엔드포인트 (GET /health) — complexity: low — agent: developer
5. [ ] 에러 핸들링 및 입력 검증 — complexity: mid — agent: developer
6. [ ] 테스트 작성 — complexity: mid — agent: developer

### Acceptance Criteria
- [ ] GET /health 200 응답
- [ ] User CRUD 전체 동작
- [ ] 잘못된 입력 시 적절한 에러 응답
```

플랜이 `.tdc/plans/flask-user-crud.md`에 저장됩니다.

### Step 2. 개발 — `/tdc-dev`

플랜을 승인하면 개발 워크플로우를 시작합니다:

```
/tdc-dev flask-user-crud 플랜대로 구현해줘
```

**Developer Agent (sonnet)** 가 플랜을 읽고 순서대로 구현합니다:

```
app.py           ← Flask 앱 + 라우트 정의
models.py        ← SQLAlchemy User 모델
requirements.txt ← flask, flask-sqlalchemy
tests/test_app.py ← pytest 기반 API 테스트
```

### Step 3. 디버깅 (필요시) — `/tdc-debug`

만약 서버 실행 중 에러가 발생하면:

```
/tdc-debug flask run 하면 "sqlalchemy.exc.OperationalError: no such table: user" 에러 발생
```

**Debugger Agent (sonnet)** 가 근본 원인을 추적합니다:

```markdown
### Bug Report
**Symptom:** 서버 시작 시 user 테이블 없음 에러
**Root Cause:** db.create_all()이 app context 밖에서 호출됨
**Location:** app.py:15

### Fix Applied
- app.py — with app.app_context(): db.create_all() 추가
```

### Step 4. 리뷰 — `/tdc-review`

구현이 끝나면 코드 리뷰를 요청합니다:

```
/tdc-review
```

**Reviewer Agent (haiku)** 가 빠르게 체크합니다:

```markdown
### Review: APPROVE

**Warnings:**
- app.py:8 — SECRET_KEY가 하드코딩됨 → 환경변수로 분리 권장
- models.py:12 — email 필드에 unique 제약 없음 → unique=True 추가 권장

**Summary:** CRUD 로직 정상. 보안/데이터 무결성 개선 권장.
```

### Step 5. 세션 관리 (대규모 작업 시)

작업이 길어지면 Master Agent가 자동으로 컨텍스트를 관리합니다:

```
[TDC] WARNING: High context usage (80 tool calls). Consider saving session.
```

```
/tdc-session save    ← 현재 진행 상황 저장
```

새 Claude Code 세션을 열고:

```
/tdc-session resume  ← 이전 세션에서 이어서 작업
```

### 전체 흐름 요약

```
/tdc-plan "Flask REST API 서버"     ← Planner가 태스크 분해
         ↓ 승인
/tdc-dev "플랜대로 구현"              ← Developer가 코드 작성
         ↓ 에러 발생 시
/tdc-debug "에러 메시지"              ← Debugger가 진단 & 수정
         ↓ 구현 완료
/tdc-review                          ← Reviewer가 코드 리뷰
         ↓ 컨텍스트 초과 시
/tdc-session save → resume           ← 세션 저장 & 재개
```

## Architecture

```
Master Agent (opus) ─── orchestrates ──┐
    ├── Planner   (sonnet)             │
    ├── Developer (sonnet)             ├── Token-optimized routing
    ├── Debugger  (sonnet)             │
    ├── Reviewer  (haiku)              │
    └── Architect (opus)  ─────────────┘
```

### Agent Roles

| Agent | Model | Role | Description |
|-------|-------|------|-------------|
| **Master** | opus | Team Leader | 오케스트레이션, 에이전트 위임, 컨텍스트 관리, 세션 전환 |
| **Planner** | sonnet | Planner | 요구사항 분석, 태스크 분해, PRD 생성 |
| **Developer** | sonnet | Executor | 코드 구현, 기능 개발, 테스트 작성 |
| **Debugger** | sonnet | Executor | 버그 진단, 근본 원인 분석, 수정 |
| **Reviewer** | haiku | Reviewer | 코드 리뷰, 보안 체크, 품질 검증 |
| **Architect** | opus | Advisor | 시스템 설계, 기술 스택 결정, 아키텍처 리뷰 |

### Token Optimization

비용을 30-50% 절감하는 전략:

1. **Model Tiering** — 간단한 작업은 haiku (최저 비용), 일반 작업은 sonnet, 복잡한 판단만 opus
2. **Context Compression** — 컨텍스트가 차면 자동 요약 후 새 세션에서 계속
3. **Session Persistence** — 저장 & 재개로 중복 처리 방지
4. **Lazy Loading** — 필요한 에이전트 컨텍스트만 로드
5. **Focused Delegation** — 각 에이전트에 최소한의 필요 컨텍스트만 전달

### Context Overflow & Session Management

Master Agent가 컨텍스트 한계에 접근하면:

1. 진행 상황을 구조화된 JSON으로 자동 요약
2. `.tdc/sessions/<session_id>.json`에 저장
3. 사용자에게 `/tdc-session resume` 안내
4. 새 세션에서 압축된 컨텍스트로 이어서 작업

Hook 기반 자동 감지:
- **80 tool calls** → 경고 메시지
- **120 tool calls** → 자동 세션 저장 트리거

## Directory Structure

```
techdog-claude/                 # Repository
├── .claude/
│   ├── agents/                 # 에이전트 정의 (6개 .md 파일)
│   ├── skills/                 # 슬래시 커맨드 정의 (6개 .md 파일)
│   └── hooks/                  # 자동화 훅 스크립트
├── scripts/
│   ├── tdc                     # CLI 메인 진입점
│   ├── context-monitor.sh      # 컨텍스트 상태 확인
│   ├── setup.sh                # npm 후처리
│   └── link.sh                 # PATH 심볼릭 링크
├── templates/                  # 설정 템플릿
│   ├── settings.json           # Claude Code 설정
│   └── team-config.json        # 팀 모드 설정
├── install.sh                  # 원격 설치 스크립트
├── CLAUDE.md                   # Claude Code 프로젝트 지침
└── MAINTENANCE.md              # 유지보수 가이드

~/.tdc/                         # 글로벌 설치 위치
  agents/ skills/ hooks/ scripts/

.tdc/                           # 프로젝트별 상태 (gitignored)
  sessions/ context/ plans/
```

## Requirements

- [Claude Code CLI](https://claude.ai/code) (`npm install -g @anthropic-ai/claude-code`)
- macOS or Linux
- bash 4+
- python3
- git

## Configuration

설치 시 자동으로 `~/.claude/settings.json`에 추가되는 설정:

```json
{
  "env": {
    "TDC_HOME": "$HOME/.tdc",
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Maintenance

아키텍처 수정, 에이전트 추가, 스킬 변경 등은 [`MAINTENANCE.md`](MAINTENANCE.md)를 참고하세요.

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) — Claude Code 멀티 에이전트 오케스트레이션 프레임워크

## License

MIT
