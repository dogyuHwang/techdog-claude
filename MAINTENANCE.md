# TechDog Claude — Maintenance Guide

이 문서는 다른 세션에서도 이 프로젝트를 유지보수할 수 있도록 전체 아키텍처, 설계 원칙, 파일별 역할, 수정 방법을 정리한 것입니다.

---

## 핵심 설계 원칙

1. **사용자는 `/tdc spec.md` 한 번만 입력한다.** 이후 기획→개발→디버깅→리뷰까지 전부 자동.
2. **에이전트끼리 Master를 통해 자동 통신한다.** 사용자가 중간에 개입하지 않는다.
3. **토큰을 항상 최소화한다.** 모델 티어링 + rtk + 최소 컨텍스트 전달.
4. **초보자도 쓸 수 있어야 한다.** README는 Claude Code를 모르는 사람 관점으로 작성.

---

## 자동 파이프라인 (가장 중요)

`/tdc spec.md` 실행 시 Master Agent가 다음을 **사용자 개입 없이** 전부 자동 수행:

```
사용자: /tdc spec.md  (이것만 입력)
              ↓
Master Agent (오케스트레이터)
    ↓
[Phase 1] Planner Agent 호출 → 스펙 분석 → 태스크 분해 → .tdc/plans/에 저장
    ↓ 승인 묻지 않고 자동 진행
[Phase 2] Developer Agent 호출 → 태스크별 코드 구현
    ↓ 에러 발생 시?
    └→ Master가 자동으로 Debugger Agent 호출 → 수정 → Developer 계속
    ↓
[Phase 3] Reviewer Agent 호출 → 자동 코드 리뷰
    ↓ 심각한 이슈 발견 시?
    └→ Master가 자동으로 Developer Agent에 수정 지시
    ↓
[Phase 4] 최종 결과를 사용자에게 한 번에 보고
```

### 에이전트 간 통신 구조

```
User → Master (유일한 사용자 접점)
         ├→ Planner → Master (플랜 수신)
         ├→ Developer → Master (코드 수신)
         │   └→ [에러] → Debugger → Master → Developer (자동 루프)
         ├→ Reviewer → Master (리뷰 수신)
         │   └→ [이슈] → Developer → Master (자동 수정)
         └→ Master → User (최종 보고)
```

**핵심 규칙:**
- 에이전트끼리 직접 통신하지 않음. 반드시 Master를 경유.
- Master는 에이전트 간에 **필요한 컨텍스트만** 전달 (전체 대화 X).
- Planner 결과 → 요약된 태스크 목록만 Developer에게 전달.
- Developer 에러 → 에러 메시지 + 해당 파일만 Debugger에게 전달.
- Reviewer 이슈 → 구체적 이슈 + 해당 파일만 Developer에게 전달.

### Master가 사용자에게 질문하는 경우 (예외)

- 스펙이 너무 모호해서 뭘 만들지 판단할 수 없을 때
- "웹앱인가 CLI인가?" 같은 근본적 결정이 필요할 때
- Debugger로도 해결할 수 없는 에러가 발생했을 때

**질문하지 않는 것들:** 플랜 승인, 버그 수정 허락, 테스트 실행 허락, 단계 간 확인

### `/tdc-plan`, `/tdc-debug` 등 개별 명령어

이것들은 **수동 모드**. 사용자가 특정 단계만 따로 실행하고 싶을 때 사용.
평소에는 `/tdc spec.md`로 전체 자동 파이프라인을 쓰는 것이 표준 흐름.

---

## Architecture Overview

```
techdog-claude/
├── .claude/
│   ├── agents/           # 에이전트 정의 (6개)
│   │   ├── master.md     # 팀 리더 — opus — 자동 파이프라인, 에이전트 간 통신, 세션 관리
│   │   ├── planner.md    # 기획자 — sonnet — 스펙 → 태스크 분해
│   │   ├── developer.md  # 개발자 — sonnet — 코드 구현, 테스트
│   │   ├── debugger.md   # 디버거 — sonnet — 에러 자동 진단/수정 (Master가 자동 호출)
│   │   ├── reviewer.md   # 리뷰어 — haiku — 자동 코드 리뷰 (구현 후 자동 실행)
│   │   └── architect.md  # 아키텍트 — opus — 설계 판단 (필요시만 호출)
│   ├── skills/           # 슬래시 커맨드 정의 (6개, 각각 폴더/SKILL.md 형식)
│   │   ├── tdc/SKILL.md        # /tdc — 메인 진입점. 자동 파이프라인 실행
│   │   ├── tdc-plan/SKILL.md   # /tdc-plan — 기획만 따로 (수동 모드)
│   │   ├── tdc-dev/SKILL.md    # /tdc-dev — 개발만 따로 (수동 모드)
│   │   ├── tdc-debug/SKILL.md  # /tdc-debug — 디버깅만 따로 (수동 모드)
│   │   ├── tdc-review/SKILL.md # /tdc-review — 리뷰만 따로 (수동 모드)
│   │   └── tdc-session/SKILL.md# /tdc-session — 세션 관리
│   └── hooks/
│       ├── context-guard.sh  # 도구 호출 횟수 추적 (80: 경고, 120: 자동 저장)
│       └── session-save.sh   # 대화 종료 시 오버플로 감지 → 자동 세션 저장
├── scripts/
│   ├── tdc               # CLI (bash) — .md 파일 자동 감지, Claude Code 연동
│   ├── context-monitor.sh# 컨텍스트 상태 확인 유틸리티
│   ├── setup.sh          # npm install 후처리
│   └── link.sh           # tdc를 ~/.local/bin/에 심볼릭 링크
├── templates/
│   ├── examples/
│   │   └── flask-api-spec.md  # 예제 스펙 (참고용)
│   ├── settings.json     # Claude Code settings.json 템플릿
│   └── team-config.json  # 팀 모드 설정 (모델 티어, 토큰 예산)
├── install.sh            # 원격 설치 — tdc + rtk + Claude Code 설정 자동 구성
├── package.json          # npm 패키지 설정
├── CLAUDE.md             # Claude Code가 읽는 프로젝트 지침
├── README.md             # GitHub README (초보자 대상, 한국어)
└── MAINTENANCE.md        # 이 파일
```

---

## Key Design Decisions

### 0. 완전 자동 파이프라인 (v1.2.0~)
- Master Agent가 `/tdc spec.md` 한 번으로 전체 파이프라인 자동 실행.
- **사용자 승인 단계 없음** — Planner 결과를 보여주고 묻지 않고 바로 진행.
- **에러 시 자동 복구** — Developer 에러 → Debugger 자동 호출 → 수정 후 계속.
- **리뷰 이슈 자동 수정** — Reviewer가 critical 이슈 발견 → Developer 자동 수정.
- 관련 파일: `.claude/agents/master.md` (Automatic Pipeline, When to Ask the User 섹션)

### 1. rtk 통합 (토큰 60-90% 절감)
- install.sh에서 자동 설치 (`install_rtk` 함수)
- `rtk init -g`로 Claude Code Bash hook에 등록 (`setup_rtk` 함수)
- Bash 명령어 출력을 자동 압축하여 컨텍스트 절약
- rtk 관련 수정: install.sh의 `install_rtk()`, `setup_rtk()` 함수

### 2. Model Tiering (비용 30-50% 절감)
- **haiku**: reviewer만 사용. 비용 최소화. 간단한 체크리스트 기반 작업.
- **sonnet**: planner, developer, debugger. 대부분의 실무 작업.
- **opus**: master, architect만. 복잡한 판단이 필요할 때만 사용.
- 변경 시: 각 에이전트 `.md` 파일 상단의 `## Model Tier` 섹션 수정.

### 3. Context Overflow 관리
- `context-guard.sh`: 매 도구 호출마다 카운트 증가. 80에서 경고, 120에서 자동 저장 플래그.
- `session-save.sh`: 대화 종료 시 오버플로 플래그가 있으면 자동 세션 저장.
- Master agent의 `Context Overflow Protocol`: JSON 형태로 진행 상황 저장 후 resume 안내.
- 임계값 변경: `context-guard.sh`의 80/120 값과 `team-config.json`의 `token_optimization` 섹션.

### 4. Skill 라우팅
- `/tdc`가 메인 진입점. `.md` 파일이면 자동 파이프라인, 서브커맨드면 개별 워크플로우.
- `/tdc-plan`, `/tdc-dev` 등은 수동 모드 (특정 단계만 따로 실행할 때).
- 파일 없이 텍스트만 넘기면 인라인 모드로 동작.
- CLI (`scripts/tdc`)도 `.md` 파일 자동 감지하여 Claude Code에 전달.

### 5. Session Persistence
- 세션 파일 위치: `.tdc/sessions/<id>.json`
- 형식: `{ session_id, project, task, completed, in_progress, pending, decisions, files_modified, context_summary }`
- 7일 이상 된 세션은 `/tdc-session clean`으로 정리.

### 6. 초보자 대상 README
- Claude Code가 뭔지, 어디서 명령어를 치는지부터 설명.
- 특정 언어/프레임워크에 편향되지 않은 다양한 예시 (웹서버, React, CLI 도구).
- 메인 명령어(`/tdc`)와 개별 명령어를 명확히 분리.
- 자동 파이프라인이라는 것을 강조 (수동 입력 필요 없음).

---

## How to Modify

### 새 에이전트 추가
1. `.claude/agents/<name>.md` 생성 (기존 에이전트 형식 참고)
2. `master.md`의 `Available Agents` 테이블에 추가
3. `master.md`의 `Automatic Pipeline`에서 새 에이전트가 언제 호출되는지 정의
4. `master.md`의 `Agent Communication Protocol`에 통신 흐름 추가
5. `tdc.md` 스킬의 라우팅 로직에 추가
6. `templates/team-config.json`에 에이전트 설정 추가
7. 필요시 전용 스킬 `.claude/skills/tdc-<name>.md` 생성

### 에이전트 수정 시 주의사항
- `master.md` 수정 시: **자동 파이프라인 흐름이 깨지지 않는지** 반드시 확인.
  특히 "When to Ask the User" 섹션 — 사용자 개입 최소화 원칙 유지.
- 에이전트 간 전달 컨텍스트를 늘리면 토큰 효율이 떨어짐. 최소 컨텍스트 원칙 유지.

### 새 스킬 추가
1. `.claude/skills/tdc-<name>/SKILL.md` 생성 (폴더/SKILL.md 구조 필수)
   - frontmatter 필수: name, description, user-invocable: true, argument-hint
   - `$ARGUMENTS`로 사용자 입력 참조
2. `tdc/SKILL.md`의 라우팅에 반영
3. `scripts/tdc` CLI의 case문에 추가
4. CLAUDE.md에 커맨드 목록 업데이트
5. README에 "개별 명령어" 테이블에 추가 (메인 명령어가 아님을 명시)

### Hook 수정
1. `.claude/hooks/` 에서 스크립트 수정
2. `templates/settings.json`의 hooks 섹션도 동기화
3. `install.sh`의 `setup_claude_settings()` 함수도 확인

### install.sh 수정
- `install_global()`: 글로벌 설치 로직 (파일 복사, PATH, 설정)
- `install_local()`: 프로젝트 로컬 설치 로직
- `install_rtk()`: rtk 설치 (brew → curl fallback)
- `setup_rtk()`: rtk를 Claude Code에 연동 (`rtk init -g`)
- `setup_claude_settings()`: settings.json에 env, hooks 자동 추가
- GitHub 레포 URL: `TDC_REPO_URL` 변수

### README 수정 시 원칙
- **자동 파이프라인이라는 점을 항상 강조**. 수동 입력이 필요한 것처럼 오해할 여지 제거.
- 특정 언어/프레임워크에 편향되지 않게 다양한 예시 유지.
- Claude Code 입력창이 어디인지, `/tdc`를 어디서 치는지 시각적으로 보여줘야 함.
- 메인 명령어(`/tdc`)와 개별 명령어(`/tdc-plan` 등) 구분을 유지.

---

## 파일별 수정 영향도

| 파일 | 수정 시 영향 | 함께 확인할 파일 |
|------|-------------|----------------|
| `master.md` | 전체 파이프라인 흐름 변경 | tdc.md, README.md |
| `tdc.md` | 메인 진입점 라우팅 변경 | master.md, scripts/tdc |
| `scripts/tdc` | CLI 동작 변경 | tdc.md (스킬과 동기화) |
| `install.sh` | 설치 과정 변경 | setup.sh, link.sh, settings.json 템플릿 |
| `README.md` | 사용자 문서만 (기능 변경 없음) | 없음 |
| `context-guard.sh` | 컨텍스트 임계값 변경 | team-config.json |
| 개별 에이전트 | 해당 에이전트 동작만 | master.md (Available Agents 테이블) |
| 개별 스킬 | 해당 수동 모드만 | tdc.md (라우팅), scripts/tdc (CLI case문) |

---

## Testing Checklist

수정 후 확인할 항목:

- [ ] `bash install.sh --local` — 로컬 설치 정상 동작
- [ ] `bash install.sh --global` — 글로벌 설치 + rtk 설치 확인
- [ ] `tdc help` — CLI 도움말 출력
- [ ] `tdc init` — .tdc/ 디렉토리 생성
- [ ] `tdc spec.md` — .md 파일 자동 감지 확인
- [ ] `tdc status` — 컨텍스트 상태 확인
- [ ] Claude Code에서 `/tdc spec.md` — 자동 파이프라인 전체 동작 확인
- [ ] Claude Code에서 `/tdc-plan spec.md` — 기획만 따로 동작 확인
- [ ] Claude Code에서 `/tdc-session list` — 세션 목록 확인
- [ ] Hook 동작: 도구 호출 시 context-guard.sh 실행 확인
- [ ] rtk 동작: `rtk gain` 으로 토큰 절감량 확인

---

## Version History

- **v1.2.0** (2026-03-27): 완전 자동 파이프라인 + rtk 통합
  - Master Agent가 전체 파이프라인을 사용자 개입 없이 자동 실행
  - 에러 시 Debugger 자동 호출, 리뷰 이슈 시 Developer 자동 수정
  - 사용자 승인 단계 제거 (스펙 모호할 때만 질문)
  - 에이전트 간 통신 프로토콜 정의 (Master 경유, 최소 컨텍스트 전달)
  - rtk 자동 설치 및 Claude Code 연동
  - README 전면 재작성: 초보자 대상, 자동 파이프라인 강조
  - 빈 스펙 템플릿 제거 (불필요)

- **v1.1.0** (2026-03-27): 스펙 파일 기반 워크플로우
  - `/tdc spec.md` 로 스펙 파일 기반 전체 워크플로우 지원
  - `/tdc-plan`, `/tdc-dev`도 파일 인자 지원
  - README 초보자 친화적 재작성

- **v1.0.0** (2026-03-27): 초기 아키텍처 구축
  - 6 agents, 6 skills, 2 hooks
  - tdc CLI, install.sh
  - 토큰 최적화 3티어 모델 라우팅
  - 컨텍스트 오버플로 자동 세션 관리
