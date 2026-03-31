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
[Phase 3] Reviewer Agent 호출 → 자동 코드 리뷰 (이슈 심각도 분류)
    ↓ 이슈 발견 시? (심각도에 따라 회귀)
    ├→ code-level → Developer 수정
    ├→ design-level → Planner 재기획 → Developer 재구현 (최대 2회)
    └→ critical → Planner 재기획 + Developer 긴급 수정
    ↓
[Phase 4] agent-log.md 기록 + 최종 결과를 사용자에게 Live Dashboard로 보고
```

### 에이전트 간 통신 구조

```
User → Master (유일한 사용자 접점)
         ├→ Planner → Master (플랜 수신)
         │   ↑ (design-level 회귀 시 재기획 요청)
         ├→ Developer → Master (코드 수신)
         │   ↑ (Reviewer 이슈/Planner 재기획 시 재구현)
         │   └→ [에러] → Debugger → Master → Developer (자동 루프)
         ├→ Reviewer → Master (리뷰 수신, 심각도 분류)
         │   ├→ [code-level] → Developer → Master (직접 수정)
         │   └→ [design-level] → Planner → Master → Developer (재기획 후 재구현)
         └→ Master → User (Live Dashboard + 최종 보고)
```

**핵심 규칙:**
- 에이전트끼리 직접 통신하지 않음. 반드시 Master를 경유.
- Master는 에이전트 간에 **필요한 컨텍스트만** 전달 (전체 대화 X).
- Planner 결과 → 요약된 태스크 목록만 Developer에게 전달.
- Developer 에러 → 에러 메시지 + 해당 파일만 Debugger에게 전달.
- Reviewer code-level 이슈 → 구체적 이슈 + 해당 파일만 Developer에게 전달.
- Reviewer design-level 이슈 → 이슈 + 원본 스펙 발췌를 Planner에게 전달 → 수정 플랜을 Developer에게 전달.

### Pre-Development Clarification (사전 질문) (v1.7.0~)

Master Agent가 파이프라인 시작 **전에** 스펙의 명확성을 평가하고, 필요한 경우에만 질문한다.

**질문하는 경우 (개발 전 한 번만):**
- 기술 스택 미지정 (언어/프레임워크 없음)
- 플랫폼/형태 모호 (웹/CLI/모바일 미지정)
- 핵심 비즈니스 로직에 선택지 존재 (인증 방식, DB 종류 등)
- 스펙 간 모순
- 범위가 극단적으로 넓어 우선순위 확인 필요

**질문하지 않는 경우:**
- 기술 스택, 형태, 기능이 모두 명확하면 바로 시작

**핵심 규칙:**
- 질문은 **개발 전 딱 한 번**, 모든 질문을 종합적으로 묻는다
- 답변 수신 후 파이프라인 시작 → Phase 1~4까지 중간에 질문 없음
- 관련 파일: `.claude/agents/master.md` (Pre-Development Clarification 섹션)

### Master가 파이프라인 중 질문하는 경우 (예외)

파이프라인이 시작된 후에는 다음 경우에만 질문한다:
- Debugger로도 해결할 수 없는 에러가 발생했을 때
- 컨텍스트 오버플로로 세션 저장이 필요할 때

**질문하지 않는 것들:** 플랜 승인, 버그 수정 허락, 테스트 실행 허락, 단계 간 확인, 기술적 판단

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
│   │   ├── reviewer.md            # 리뷰어 — haiku — 자동 코드 리뷰 (구현 후 자동 실행)
│   │   ├── security-reviewer.md   # 보안 리뷰어 — haiku — OWASP 보안 리뷰
│   │   ├── test-engineer.md       # 테스트 엔지니어 — sonnet — 테스트 생성
│   │   └── architect.md           # 아키텍트 — opus — 설계 판단 (필요시만 호출)
│   ├── skills/           # 슬래시 커맨드 정의 (7개, 각각 폴더/SKILL.md 형식)
│   │   ├── tdc/SKILL.md        # /tdc — 메인 진입점. 자동 파이프라인 실행
│   │   ├── tdc-plan/SKILL.md   # /tdc-plan — 기획만 따로 (수동 모드)
│   │   ├── tdc-dev/SKILL.md    # /tdc-dev — 개발만 따로 (수동 모드)
│   │   ├── tdc-debug/SKILL.md  # /tdc-debug — 디버깅만 따로 (수동 모드)
│   │   ├── tdc-review/SKILL.md # /tdc-review — 리뷰만 따로 (수동 모드)
│   │   ├── tdc-session/SKILL.md# /tdc-session — 세션 관리
│   │   └── tdc-learn/SKILL.md  # /tdc-learn — 스킬 학습 (세션에서 패턴 추출)
│   └── hooks/
│       ├── context-guard.sh     # 도구 호출 횟수 추적 (80: 경고, 120: 자동 저장)
│       ├── session-save.sh      # 대화 종료 시 오버플로 감지 → 자동 세션 저장
│       ├── agent-tracker.sh     # SubagentStart/Stop 훅 — 에이전트 시작/완료 추적, 상태 파일 기록
│       ├── tdc-status.sh        # Status Line 스크립트 — .phase + .agent-status 읽어서 한 줄 출력
│       ├── smart-read.sh        # Read 훅 — 대용량 파일 읽기 감지 + 경고
│       └── rate-limit-guard.sh  # PostToolUse 훅 — API rate limit 감지 + 자동 대기 안내
├── scripts/
│   └── setup.sh          # npm install 후처리
├── state/
│   ├── sessions/         # 로컬 세션 저장 (.gitkeep)
│   └── context/          # 컨텍스트 모니터링 데이터 (.gitkeep)
├── templates/
│   ├── examples/
│   │   └── flask-api-spec.md  # 예제 스펙 (참고용)
│   ├── project-init/
│   │   └── .tdc/README.md     # 프로젝트 .tdc/ 설명
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

### 0.1. 3중 에이전트 가시성 (v1.6.0~, 기존 v1.3.0 확장)
- **Status Line**: 터미널 하단에 현재 Phase/Agent/도구 사용량 상시 표시.
  - `.tdc/context/.phase` + `.tdc/context/.agent-status` 파일 기반.
  - `tdc-status.sh` 스크립트가 읽어서 한 줄 출력.
- **Console Messages**: SubagentStart/SubagentStop 훅으로 에이전트 시작/완료 자동 알림.
  - `agent-tracker.sh`가 `.tdc/context/.agent-status`에 상태 기록 + 콘솔 메시지 출력.
  - `.tdc/context/.agent-events`에 전체 이벤트 타임라인 기록.
- **Dashboard Banners**: Master Agent가 Phase 배너 + 타임스탬프 포함 에이전트 간 통신 로그 출력.
- 관련 파일: `.claude/agents/master.md`, `.claude/hooks/agent-tracker.sh`, `.claude/hooks/tdc-status.sh`

### 0.2. 회귀 루프 — Reviewer → Planner (v1.3.0~)
- Reviewer가 이슈 심각도를 `code-level` / `design-level` / `critical` 로 분류.
- **code-level**: Developer가 직접 수정 (기존과 동일).
- **design-level**: Master가 Planner에게 재기획 요청 → 수정된 플랜으로 Developer 재구현.
- **critical**: Planner 재기획 + Developer 수정.
- **무제한 회귀** — Reviewer가 APPROVE할 때까지 계속. 컨텍스트 오버플로 시 세션 저장/재개로 이어서 진행.
- 관련 파일: `.claude/agents/master.md` (Regression Loop, Regression Policy), `.claude/agents/reviewer.md` (Issue Severity Classification)

### 0.3. Preemptive Context Compaction (v2.0.0~)
- `PreCompact` 훅으로 컨텍스트 압축 전에 핵심 상태를 `.tdc/context/notepad.md`에 자동 저장.
- 저장 내용: 현재 Phase, 활성 에이전트, 도구 호출 수, 태스크 진행률, 수정 파일, 에이전트 토큰.
- 압축 후 Master가 notepad.md를 읽어 상태를 복원하고 pending 태스크부터 재개.
- 관련 파일: `.claude/hooks/pre-compact.sh`, `.claude/agents/master.md` (Preemptive Context Compaction)

### 0.4. Project Memory — 교차 세션 지식 (v2.0.0~)
- `.tdc/project-memory.md`에 프로젝트 규칙, 기술 결정, 코딩 컨벤션 저장.
- Master가 Phase 0에서 자동 로드 → 매 세션마다 "다시 설명" 불필요.
- Phase 4에서 새로 발견된 규칙 자동 추가 (중복 방지).
- 코드에서 직접 알 수 있는 정보(파일 경로 등)는 저장하지 않음.
- 관련 파일: `.claude/agents/master.md` (Phase 0, Phase 4)

### 0.5. 도메인 특화 에이전트 (v2.0.0~)
- **Security Reviewer** (haiku): OWASP top 10 기반 보안 전문 리뷰.
  - Phase 3에서 Reviewer와 병렬 실행.
  - critical/high 이슈 → regression loop의 critical로 처리.
  - 관련 파일: `.claude/agents/security-reviewer.md`
- **Test Engineer** (sonnet): 테스트 커버리지 분석 + 테스트 자동 생성.
  - Phase 3에서 Reviewer 후 실행. 프레임워크 자동 감지.
  - 관련 파일: `.claude/agents/test-engineer.md`

### 0.6. Git Worktree 병렬 개발 (v2.0.0~)
- 독립 태스크를 `isolation: "worktree"`로 병렬 구현.
- Planner의 Dependencies 분석 결과를 기반으로 독립/의존 분류.
- 완료 후 자동 merge. 충돌 시 Debugger가 해결.
- 관련 파일: `.claude/agents/master.md` (Phase 2, Worktree Parallel Strategy)

### 0.7. 에이전트별 토큰 대시보드 (v2.0.0~)
- `agent-tracker.sh`가 에이전트 실행 시간 기반으로 토큰 사용량 추정.
- `.tdc/context/.agent-tokens`에 에이전트별 누적 토큰 기록.
- Phase 4 리포트에 시각적 게이지 바 (█/░) + 비율 + 비용 추정 표시.
- rtk 절감량 표시 (실제 rtk gain 또는 60% 기본 추정).
- 관련 파일: `.claude/hooks/agent-tracker.sh`, `.claude/agents/master.md` (Response Format)

### 0.8. Deep Mode — 끈질긴 검증 (v1.9.0~, v2.2.0에서 ralph→deep 리네임)
- `/tdc deep spec.md` 서브커맨드로 활성화. (ralph: 매직 키워드 제거됨)
- 일반 regression loop보다 훨씬 엄격한 검증 루프 실행.
- 테스트 → 빌드 → Reviewer → 최종검증 4단계 순환. 모두 통과해야 완료.
- Developer 동일 이슈 3회 실패 시 Architect 에스컬레이션.
- `.tdc/context/.deep` 상태 파일로 Deep 모드 추적.
- Status line에 `[TDC-DEEP]` 접두사 표시.
- 관련 파일: `.claude/agents/master.md` (Deep Mode 섹션), `.claude/hooks/tdc-status.sh`, `.claude/skills/tdc/SKILL.md`

### 0.4. Deep Interview — 가중치 기반 사전 질문 (v1.9.0~)
- 기존 단순 모호성 체크를 5차원 가중치 명확도 측정으로 업그레이드.
- 차원: 기술스택(25%), 플랫폼(20%), 기능명세(25%), 비즈니스로직(20%), 범위(10%).
- 가중 합산 점수 3.5 이상: 질문 없이 시작. 2.0~3.4: 부분 질문. 2.0 미만: 소크라틱 인터뷰. (v2.6.0에서 임계값 하향)
- 명확도 점수를 시각적 바 그래프로 사용자에게 표시.
- 기존 프로젝트 수정 요청은 높은 명확도로 간주 (코드에서 추론).
- 관련 파일: `.claude/agents/master.md` (Deep Interview 섹션)

### 0.5. Skill Learning — 패턴 자동 학습 (v1.9.0~)
- `/tdc-learn extract`로 세션에서 문제 해결 패턴 추출.
- `.tdc/learned-skills/<name>.md`에 마크다운 스킬 파일로 저장.
- frontmatter에 `triggers` 키워드 정의 → Master가 Phase 시작 시 자동 매칭/주입.
- 품질 게이트: 재사용 가능성, 구체성, 검증됨 3개 기준 충족 필요.
- confidence: high만 자동 주입. medium은 수동 apply.
- 관련 파일: `.claude/skills/tdc-learn/SKILL.md`, `.claude/agents/master.md` (Phase 0.5: Skill Injection)

### 0.6. Rate Limit Guard (v1.9.0~)
- PostToolUse 훅으로 API rate limit 패턴 자동 감지.
- rate limit 감지 시 대기 시간 안내 + 에이전트 병렬 실행 감속.
- 3회 이상 발생 시 세션 저장 제안.
- Master Agent에 Rate Limit Protocol 추가 (자동 감속 → 재시도 → 에스컬레이션).
- 관련 파일: `.claude/hooks/rate-limit-guard.sh`, `.claude/agents/master.md` (Rate Limit Protocol)

### 0.7. 4중 토큰 최적화 (v1.8.0~)

**Smart Read Hook** (`smart-read.sh`):
- PostToolUse(Read) 훅으로 대용량 파일 읽기(>200줄) 감지 + 경고 메시지 출력.
- 누적 Read 토큰을 `.tdc/context/.read_tokens`에 추적.
- 에이전트 프롬프트(developer.md, debugger.md)에 Smart Read Protocol 추가.
- 관련 파일: `.claude/hooks/smart-read.sh`, `.claude/agents/developer.md`, `.claude/agents/debugger.md`

**Diff-Only Review**:
- master.md Phase 3에서 `git diff --unified=5` 결과만 Reviewer에게 전달.
- reviewer.md에 "Input Format: Diff-Only Review" 섹션 추가.
- 전체 파일 전달 대비 50-70% 토큰 절감.
- 관련 파일: `.claude/agents/master.md`, `.claude/agents/reviewer.md`

**Conversation Compaction**:
- context-guard.sh에 60 tool calls 컴팩션 트리거 추가.
- `.tdc/context/.compaction_done` 플래그로 중복 트리거 방지.
- Master Agent가 중간 결과를 요약하여 유효 컨텍스트 확장.
- 관련 파일: `.claude/hooks/context-guard.sh`, `.claude/agents/master.md`

**Response Budget Enforcement**:
- context-guard.sh에 누적 토큰 추정 로직 추가 (tool calls * 500 + read tokens).
- ~150k 토큰 추정 초과 시 경고 메시지 출력.
- `.tdc/context/.budget_warned` 플래그로 중복 경고 방지.
- 관련 파일: `.claude/hooks/context-guard.sh`

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
- `context-guard.sh`: 매 도구 호출마다 `.tdc/context/.tool_count`에 카운트 증가. 80에서 경고, 120에서 `.overflow_flag` 생성. 세션 시작 시 rtk 상태도 검증 (`.rtk_status` 파일).
- `session-save.sh`: 대화 종료 시 오버플로 플래그가 있으면 자동 세션 저장. 최신 플랜에서 completed/pending 태스크를 추출하고, git diff로 변경 파일 목록도 캡처.
- Master agent의 `Context Overflow Protocol`: JSON 형태로 진행 상황 저장 후 resume 안내.
- `/tdc-session resume`: rich 세션 (태스크 상태 있음)과 minimal 세션 (메타데이터만)을 구분하여 처리.
- 임계값 변경: `context-guard.sh`의 80/120 값과 `team-config.json`의 `token_optimization` 섹션.

### 4. Skill 라우팅
- `/tdc`가 메인 진입점. `.md` 파일이면 자동 파이프라인, 서브커맨드면 개별 워크플로우.
- `/tdc-plan`, `/tdc-dev` 등은 수동 모드 (특정 단계만 따로 실행할 때).
- 파일 없이 텍스트만 넘기면 인라인 모드로 동작.
- CLI는 제거됨 (v1.3.0). 모든 사용은 Claude Code 안에서 `/tdc` 슬래시 커맨드로.

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
3. CLAUDE.md에 커맨드 목록 업데이트
5. README에 "개별 명령어" 테이블에 추가 (메인 명령어가 아님을 명시)

### Hook 수정
1. `.claude/hooks/` 에서 스크립트 수정
2. `templates/settings.json`의 hooks 섹션도 동기화
3. `install.sh`의 `setup_claude_settings()` 함수도 확인

### install.sh 수정
- `install_tdc()`: 메인 설치 로직 (레포 클론, 스킬/에이전트 복사, 설정)
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
| `master.md` | 전체 파이프라인 흐름, Live Dashboard, 회귀 루프 변경 | tdc.md, reviewer.md, README.md |
| `tdc.md` | 메인 진입점 라우팅 변경 | master.md |
| `install.sh` | 설치 과정 변경 | setup.sh, settings.json 템플릿 |
| `README.md` | 사용자 문서만 (기능 변경 없음) | 없음 |
| `context-guard.sh` | 컨텍스트 임계값 변경 | team-config.json |
| `agent-tracker.sh` | 에이전트 가시성 변경 | settings.json, master.md |
| `tdc-status.sh` | Status Line 표시 형식 변경 | agent-tracker.sh |
| `rate-limit-guard.sh` | Rate limit 감지/대응 변경 | master.md (Rate Limit Protocol) |
| `reviewer.md` | 리뷰 출력 형식, 심각도 분류 변경 | master.md (Regression Loop) |
| `tdc-learn/SKILL.md` | 스킬 학습 워크플로우 변경 | master.md (Phase 0.5: Skill Injection) |
| 개별 에이전트 | 해당 에이전트 동작만 | master.md (Available Agents 테이블) |
| 개별 스킬 | 해당 수동 모드만 | tdc.md (라우팅) |

---

## Testing Checklist

수정 후 확인할 항목:

- [ ] `bash install.sh` — 설치 + rtk 설치 확인
- [ ] `~/.claude/skills/tdc/SKILL.md` 존재 확인
- [ ] `~/.claude/agents/master.md` 존재 확인
- [ ] Claude Code에서 `/tdc spec.md` — 자동 파이프라인 전체 동작 확인
- [ ] Claude Code에서 `/tdc-plan spec.md` — 기획만 따로 동작 확인
- [ ] Claude Code에서 `/tdc-session list` — 세션 목록 확인
- [ ] Hook 동작: 도구 호출 시 context-guard.sh 실행 확인
- [ ] Hook 동작: 에이전트 시작/완료 시 agent-tracker.sh 실행 확인 (SubagentStart/Stop)
- [ ] Status Line: `bash ~/.tdc/hooks/tdc-status.sh`로 상태 출력 확인
- [ ] rtk 동작: `rtk gain` 으로 토큰 절감량 확인

---

## Version History

- **v2.7.0** (2026-03-31): 업그레이드 스킬팩 스킵 + 토큰 대시보드 수정 + 권한 자동 허용
  - **install.sh 업그레이드 개선**: 기존 스킬팩이 있으면 선택 UI 스킵, 기존 팩만 업데이트
  - **agent-tracker.sh 정규화 확장**: Explore/general-purpose/Plan/python-developer 등 누락된 에이전트 타입 추가
  - **settings.local.json 권한 추가**: .tdc/context/ 디렉토리 접근 자동 허용 (bypassPermissions 보완)
  - rtk v0.34.2 동작 확인 (99.6% 절감률)

- **v2.6.0** (2026-03-31): 사전 질문 임계값 하향 + 에이전트 자율 모드
  - **Deep Interview 임계값 하향**: 4.0→3.5 (질문 생략), 2.5→2.0 (소크라틱 인터뷰). 경계값에서 적극적으로 질문하도록 변경
  - **Agent bypassPermissions 모드**: 모든 서브 에이전트에 `mode: "bypassPermissions"` 적용. 파이프라인 중 사용자 승인 요청 완전 제거
  - 안전장치: git 복구 + Reviewer/Security Reviewer 사후 검증
  - master.md, CLAUDE.md, MAINTENANCE.md, README.md, README_EN.md 업데이트

- **v2.2.0** (2026-03-30): Deep 모드 + 자동 스킬 학습
  - Ralph → Deep 리네임: `/tdc deep spec.md` 서브커맨드로 통일. `ralph:` 매직 키워드 제거
  - Auto Skill Extract: Phase 4 완료 시 재사용 가능한 패턴 자동 추출
  - 전체 파일 ralph→deep 전환 (master.md, SKILL.md, CLAUDE.md, README.md, tdc-status.sh)

- **v2.1.0** (2026-03-30): 실시간 토큰 게이지 + 스킬팩 8종 + 선택적 설치
  - 실시간 토큰 게이지: Status Line + 에이전트 완료 시 게이지 바 출력
  - 8 프레임워크 스킬팩: Python/Django, TS/Next.js, Go, Rust, Java, Flutter, Kotlin, React
  - 선택적 설치: install.sh에서 전체/선택/코어 3가지 모드

- **v2.0.0** (2026-03-30): 경쟁력 강화 5종 + 에이전트 확장
  - **Preemptive Context Compaction**: PreCompact 훅으로 압축 전 상태 자동 저장. notepad.md로 복구
  - **Project Memory**: `.tdc/project-memory.md`에 교차 세션 프로젝트 지식 저장/자동 로드
  - **Security Reviewer Agent**: OWASP top 10 보안 전문 리뷰어 (haiku). Phase 3에서 자동 실행
  - **Test Engineer Agent**: 테스트 커버리지 분석 + 테스트 자동 생성 (sonnet). Phase 3에서 자동 실행
  - **Git Worktree 병렬 개발**: 독립 태스크를 worktree로 병렬 구현 → 자동 merge
  - **Token Usage Dashboard**: Phase 4에 에이전트별 토큰 게이지 바 + rtk 절감 + 비용 추정
  - agent-tracker.sh에 토큰 추적 기능 추가 (.agent-tokens)
  - pre-compact.sh 신규 훅 + settings.json/install.sh에 등록
  - security-reviewer.md, test-engineer.md 신규 에이전트 추가
  - master.md에 Phase 0 (Project Memory + Skill Injection), Phase 2 (worktree), Phase 3 (security + test) 확장

- **v1.9.0** (2026-03-30): OMC 영감 기능 4종 추가
  - **Deep Mode** (구 Ralph): `/tdc deep`으로 끈질긴 검증 루프 활성화. 테스트+빌드+리뷰+최종검증 4단계 순환, 3회 실패 시 Architect 에스컬레이션
  - **Skill Learning** (`/tdc-learn`): 세션에서 문제 해결 패턴 자동 추출. `.tdc/learned-skills/`에 저장, trigger 키워드 매칭으로 미래 세션에 자동 주입
  - **Deep Interview**: 사전 질문을 5차원 가중치 명확도 측정으로 업그레이드. 점수별 차등 대응 (소크라틱 인터뷰 / 부분 질문 / 즉시 시작)
  - **Rate Limit Guard**: PostToolUse 훅으로 API rate limit 자동 감지. 대기 시간 안내 + 에이전트 감속 + 3회 초과 시 세션 저장 제안
  - `rate-limit-guard.sh` 신규 훅 + settings.json/install.sh에 등록
  - `tdc-learn/SKILL.md` 신규 스킬 추가
  - master.md에 Deep Mode, Deep Interview, Skill Injection, Rate Limit Protocol 섹션 추가
  - tdc-status.sh에 Deep 모드 표시 (`[TDC-DEEP]`) 추가

- **v1.8.0** (2026-03-30): 4중 토큰 최적화 시스템
  - **Smart Read Hook**: PostToolUse(Read) 훅으로 대용량 파일 읽기 감지 + 경고. 에이전트 프롬프트에 Smart Read Protocol 추가 (Grep/Glob 선행, offset/limit 필수)
  - **Diff-Only Review**: Reviewer에게 전체 파일 대신 `git diff --unified=5` 전달 (50-70% 절감). master.md Phase 3 + reviewer.md 수정
  - **Conversation Compaction**: context-guard.sh에 60 tool calls 컴팩션 트리거 추가. 중간 결과 요약으로 유효 컨텍스트 확장
  - **Response Budget Enforcement**: 누적 토큰 추정 (~150k) 초과 시 에이전트 출력 간결화 경고. context-guard.sh에 통합
  - `smart-read.sh` 신규 훅 + settings.json/install.sh에 등록
  - developer.md, debugger.md에 Smart Read Protocol 추가

- **v1.7.0** (2026-03-30): 사전 질문 + 다국어 README
  - **Pre-Development Clarification**: 스펙이 모호할 때 개발 전 한 번에 종합 질문, 개발 시작 후에는 질문 없이 자동 진행
  - master.md에 사전 질문 판단 기준, 질문 형식, 핵심 규칙 추가
  - tdc SKILL.md에 사전 질문 단계 반영
  - **다국어 README**: README_EN.md 영문 버전 추가
  - README.md 상단에 언어 전환 버튼 (한국어 | English) 추가
  - README.md 상단에 빠른 탐색 링크 (시작하기/설치/사용법/명령어/아키텍처/FAQ) 추가

- **v1.6.0** (2026-03-29): 3중 에이전트 가시성 시스템
  - **Status Line**: 터미널 하단에 현재 Phase/Agent/진행률 상시 표시 (`tdc-status.sh`)
  - **Console Messages**: SubagentStart/SubagentStop 훅으로 에이전트 시작/완료 자동 알림 (`agent-tracker.sh`)
  - **Dashboard Timestamps**: 에이전트 간 통신 로그에 타임스탬프 + 경과 시간 추가
  - `.tdc/context/.phase`, `.agent-status`, `.agent-events` 상태 파일 프로토콜 추가
  - settings.json에 SubagentStart/SubagentStop 훅 등록
  - install.sh에 새 훅 자동 설치 + 설정

- **v1.5.0** (2026-03-29): /tdc version 커맨드 추가

- **v1.4.0** (2026-03-29): 삭제 스크립트 추가
  - `uninstall.sh` 추가 — 스킬, 에이전트, ~/.tdc/, settings.json 훅까지 자동 정리
  - `curl | bash` 원격 삭제 지원
  - README.md 삭제 섹션을 한 줄 명령어로 간소화

- **v1.3.1** (2026-03-29): 토큰 최적화/시각화/컨텍스트 감사 및 개선
  - context-guard.sh에 rtk 상태 검증 추가 (미설치/오작동 시 경고)
  - 에이전트 프롬프트에 토큰 예산 명시 (planner 4k, developer 8k, debugger 6k, reviewer 3k)
  - SKILL.md Phase 수를 master.md와 통일 (5→4 phase)
  - master.md에 태스크별 진행률 바 (Progress: ████░░░░░░) 추가
  - session-save.sh 자동 저장에 태스크 상태 포함 (completed/pending/files_modified/plan_file)
  - tdc-session resume에 rich/minimal 세션 분기 처리 추가

- **v1.3.0** (2026-03-29): Live Dashboard + 에이전트 회귀 루프
  - Master Agent가 모든 에이전트 활동을 실시간 Live Dashboard로 표시
  - Phase 배너, 에이전트 간 통신 로그를 사용자에게 실시간 출력
  - `.tdc/context/agent-log.md`에 전체 상호작용 로그 기록
  - Reviewer → Planner 회귀 루프 추가 (design-level 이슈 시 재기획)
  - Reviewer에 이슈 심각도 분류 추가 (code-level / design-level / critical)
  - Reviewer APPROVE까지 무제한 회귀 (컨텍스트 오버플로 시 세션 저장/재개)
  - README에 tdc.png 메인 이미지 추가
  - README에 Live Dashboard 예시 추가
  - tdc CLI 제거 (scripts/tdc, link.sh, context-monitor.sh) — `/tdc` 슬래시 커맨드만 사용
  - install.sh에서 PATH/symlink/ensure_path 로직 제거
  - `tdc init` 제거 — `.tdc/` 디렉토리는 `/tdc` 첫 실행 시 자동 생성

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
