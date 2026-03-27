# TechDog Claude — Maintenance Guide

이 문서는 다른 세션에서도 이 프로젝트를 유지보수할 수 있도록 아키텍처, 파일 위치, 수정 규칙을 정리한 것입니다.

## Architecture Overview

```
techdog-claude/
├── .claude/
│   ├── agents/           # 에이전트 정의 (6개)
│   │   ├── master.md     # 팀 리더 — opus — 오케스트레이션, 컨텍스트 관리, 세션 전환
│   │   ├── planner.md    # 기획자 — sonnet — 요구사항 분석, 태스크 분해, PRD
│   │   ├── developer.md  # 개발자 — sonnet — 코드 구현, 테스트
│   │   ├── debugger.md   # 디버거 — sonnet — 버그 진단, 근본 원인 분석, 수정
│   │   ├── reviewer.md   # 리뷰어 — haiku — 코드 리뷰, 보안, 품질 체크
│   │   └── architect.md  # 아키텍트 — opus — 시스템 설계, 기술 결정
│   ├── skills/           # 슬래시 커맨드 정의 (6개)
│   │   ├── tdc.md        # /tdc — 메인 진입점, 라우팅 로직
│   │   ├── tdc-plan.md   # /tdc-plan — 기획 워크플로우
│   │   ├── tdc-dev.md    # /tdc-dev — 개발 워크플로우
│   │   ├── tdc-debug.md  # /tdc-debug — 디버깅 워크플로우
│   │   ├── tdc-review.md # /tdc-review — 코드 리뷰 워크플로우
│   │   └── tdc-session.md# /tdc-session — 세션 관리 (save/resume/list/clean)
│   └── hooks/            # 자동화 훅 스크립트
│       ├── context-guard.sh  # 도구 호출 횟수 추적, 80/120 임계값 경고
│       └── session-save.sh   # 컨텍스트 오버플로 시 자동 세션 저장
├── scripts/
│   ├── tdc               # CLI 메인 (bash) — tdc 명령어 진입점 (.md 파일 자동 감지)
│   ├── context-monitor.sh# 컨텍스트 상태 확인 유틸리티
│   ├── setup.sh          # npm install 후처리
│   └── link.sh           # tdc를 PATH에 심볼릭 링크
├── templates/
│   ├── spec-template.md  # 빈 스펙 템플릿 (tdc init 시 복사됨)
│   ├── examples/
│   │   └── flask-api-spec.md  # Flask API 예제 스펙
│   ├── settings.json     # Claude Code settings.json 템플릿
│   └── team-config.json  # 팀 모드 설정 (모델 티어, 토큰 예산)
├── templates/project-init/ # tdc init 시 복사할 템플릿
├── install.sh            # 원격 설치 스크립트 (curl | bash)
├── package.json          # npm 패키지 설정
├── CLAUDE.md             # Claude Code가 읽는 프로젝트 지침
├── README.md             # GitHub README
└── MAINTENANCE.md        # 이 파일
```

## Core Workflow (핵심 흐름)

```
사용자: spec.md 작성 → /tdc spec.md
                          ↓
/tdc 스킬: 파일 감지 → Read로 읽기 → 스펙인지 플랜인지 판단
                          ↓ 스펙
/tdc-plan: Planner Agent 호출 → 태스크 분해 → .tdc/plans/에 저장 → 사용자 승인
                          ↓ 승인
/tdc-dev: Developer Agent 호출 → 태스크별 구현 → 테스트 → Reviewer 자동 리뷰
```

- `/tdc <file.md>` 가 메인 진입점. 파일을 읽고 내용에 따라 자동 라우팅.
- `/tdc-plan`, `/tdc-dev`도 각각 파일 인자를 받을 수 있음.
- 파일 없이 텍스트만 넘기면 인라인 모드로 동작.

## Key Design Decisions

### 0. rtk 통합 (토큰 60-90% 절감)
- install.sh에서 자동 설치 (`install_rtk` 함수)
- `rtk init -g`로 Claude Code Bash hook에 등록 (`setup_rtk` 함수)
- Bash 명령어 출력을 자동 압축하여 컨텍스트 절약
- rtk 관련 수정: install.sh의 `install_rtk()`, `setup_rtk()` 함수

### 1. Model Tiering (토큰 최적화 핵심)
- **haiku**: reviewer만 사용. 비용 최소화. 간단한 체크리스트 기반 작업.
- **sonnet**: planner, developer, debugger. 대부분의 실무 작업.
- **opus**: master, architect만. 복잡한 판단이 필요할 때만 사용.
- 변경 시: 각 에이전트 `.md` 파일 상단의 `## Model Tier` 섹션 수정.

### 2. Context Overflow 관리
- `context-guard.sh`: 매 도구 호출마다 카운트 증가. 80에서 경고, 120에서 자동 저장 플래그.
- `session-save.sh`: 대화 종료 시 오버플로 플래그가 있으면 자동 세션 저장.
- Master agent의 `Context Overflow Protocol`: JSON 형태로 진행 상황 저장 후 resume 안내.
- 임계값 변경: `context-guard.sh`의 80/120 값과 `team-config.json`의 `token_optimization` 섹션.

### 3. Skill 라우팅
- `/tdc`가 메인 진입점. 서브커맨드(plan/dev/debug/review/session)를 감지하여 라우팅.
- 서브커맨드가 없으면 의도를 분석하여 적절한 에이전트 선택.
- 단순 작업은 에이전트 위임 없이 직접 처리 (토큰 절약).

### 4. Session Persistence
- 세션 파일 위치: `.tdc/sessions/<id>.json`
- 형식: `{ session_id, project, task, completed, in_progress, pending, decisions, files_modified, context_summary }`
- 7일 이상 된 세션은 `/tdc-session clean`으로 정리.

## How to Modify

### 새 에이전트 추가
1. `.claude/agents/<name>.md` 생성 (기존 에이전트 형식 참고)
2. `master.md`의 `Available Agents` 테이블에 추가
3. `tdc.md` 스킬의 라우팅 로직에 추가
4. `templates/team-config.json`에 에이전트 설정 추가
5. 필요시 전용 스킬 `.claude/skills/tdc-<name>.md` 생성

### 새 스킬 추가
1. `.claude/skills/tdc-<name>.md` 생성 (frontmatter 필수: name, description, user-invocable: true)
2. `tdc.md`의 라우팅에 반영
3. `scripts/tdc` CLI의 case문에 추가
4. CLAUDE.md에 커맨드 목록 업데이트

### Hook 수정
1. `.claude/hooks/` 에서 스크립트 수정
2. `templates/settings.json`의 hooks 섹션도 동기화
3. `install.sh`의 `setup_claude_settings()` 함수도 확인

### 설치 스크립트 수정
- `install.sh`: 원격/로컬 설치 로직
- `scripts/setup.sh`: npm install 후처리
- `scripts/link.sh`: PATH 심볼릭 링크
- GitHub 레포 URL은 `install.sh`의 `TDC_REPO_URL` 변수에서 변경

## Testing Checklist

수정 후 확인할 항목:

- [ ] `bash install.sh --local` — 로컬 설치 정상 동작
- [ ] `bash install.sh --global` — 글로벌 설치 정상 동작
- [ ] `tdc help` — CLI 도움말 출력
- [ ] `tdc init` — .tdc/ 디렉토리 생성
- [ ] `tdc status` — 컨텍스트 상태 확인
- [ ] Claude Code에서 `/tdc` — 스킬 인식 확인
- [ ] Claude Code에서 `/tdc-session list` — 세션 목록 확인
- [ ] Hook 동작: 도구 호출 시 context-guard.sh 실행 확인

## Version History

- **v1.1.0** (2026-03-27): 스펙 파일 기반 워크플로우
  - `/tdc spec.md` 로 스펙 파일 기반 전체 워크플로우 지원
  - `/tdc-plan`, `/tdc-dev`도 파일 인자 지원
  - spec-template.md 템플릿 및 Flask API 예제 추가
  - `tdc init` 시 스펙 템플릿 자동 생성
  - `tdc template` 명령어 추가
  - README 초보자 친화적 재작성

- **v1.0.0** (2026-03-27): 초기 아키텍처 구축
  - 6 agents, 6 skills, 2 hooks
  - tdc CLI, install.sh
  - 토큰 최적화 3티어 모델 라우팅
  - 컨텍스트 오버플로 자동 세션 관리
