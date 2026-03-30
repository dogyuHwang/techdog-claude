# TechDog Claude (tdc)

Multi-agent development orchestration system for Claude Code.

## Core Workflow

1. 사용자가 spec 파일(.md)을 작성
2. `/tdc spec.md` 로 실행
3. **[사전 질문]** 스펙이 모호하면 개발 전 한 번에 종합 질문 (명확하면 생략)
4. Planner가 스펙을 분석하여 태스크 분해
5. Developer가 자동 구현 (승인 불필요)
6. Reviewer가 자동 리뷰 → 이슈 심각도에 따라 회귀 루프 실행
7. 모든 진행 상황은 Live Dashboard로 실시간 표시

## Commands

- `/tdc <file.md>` - 스펙 파일을 읽고 기획→개발 진행. 메인 진입점.
- `/tdc <설명>` - 텍스트로 간단히 지시
- `/tdc-plan <file|desc>` - 기획만 진행 (스펙 파일 또는 텍스트)
- `/tdc-dev <file|desc>` - 개발만 진행 (플랜 파일 또는 텍스트)
- `/tdc-debug <desc>` - 디버깅 워크플로우
- `/tdc-review [files]` - 코드 리뷰
- `/tdc-session <save|resume|list|clean>` - 세션 관리

## Agents (model tier)

- **Master** (opus): 오케스트레이션, Live Dashboard, 회귀 루프 관리
- **Planner** (sonnet): 요구사항 분석, 태스크 분해, 재기획 (회귀 시)
- **Developer** (sonnet): 코드 구현
- **Debugger** (sonnet): 버그 진단/수정
- **Reviewer** (haiku): 코드 리뷰, 이슈 심각도 분류 (code/design/critical)
- **Architect** (opus): 시스템 설계 (필요시만)

## Regression Loop (회귀 루프)

Reviewer 이슈 심각도에 따라 자동 회귀:
- `code-level` → Developer가 직접 수정
- `design-level` → Planner 재기획 → Developer 재구현
- `critical` → Planner 재기획 + Developer 수정
- Reviewer가 APPROVE할 때까지 무제한 회귀 (컨텍스트 오버플로 시 세션 저장/재개)

## Live Dashboard & Agent Visibility

에이전트 활동을 **3중 가시성**으로 실시간 표시:

1. **Status Line** (터미널 하단 상시): `[TDC] Phase 2/4 — IMPLEMENTATION | developer working | 45 tools`
   - `.tdc/context/.phase` + `.tdc/context/.agent-status` 파일 기반
   - `tdc-status.sh` 스크립트가 읽어서 표시
2. **Console Messages** (대화 흐름 중): `[TDC] developer agent started (14:03:23)`
   - SubagentStart/SubagentStop 훅 (`agent-tracker.sh`)이 자동 출력
3. **Dashboard Banners** (Phase 전환 시): 타임스탬프 포함 상세 로그
   - Master Agent가 Phase 배너 + 에이전트 간 통신 로그 출력
   - 완료 후 `.tdc/context/agent-log.md`에 전체 로그 기록

## Token Optimization

- 스펙 원문은 planner에게만. 다른 에이전트에는 플랜/태스크만 전달.
- haiku → sonnet → opus 순으로 비용 효율적 라우팅.
- 각 에이전트 프롬프트에 토큰 예산 명시 (planner: 4k, developer: 8k, debugger: 6k, reviewer: 3k).
- rtk (https://github.com/rtk-ai/rtk) 로 명령어 출력 자동 압축 (60-90% 절감).
  - context-guard.sh가 세션 시작 시 rtk 상태를 검증 (미설치/오작동 시 경고).
- 컨텍스트 오버플로 시 자동 세션 저장 (.tdc/sessions/) — 태스크 상태 포함.
- **Smart Read**: 에이전트가 Grep/Glob 후 타겟 Read (>200줄 파일은 offset/limit 필수). `smart-read.sh` 훅이 모니터링.
- **Diff-Only Review**: Reviewer에게 전체 파일 대신 `git diff --unified=5` 전달 (50-70% 절감).
- **Conversation Compaction**: 60 tool calls에서 컨텍스트 압축 트리거 (중간 결과 요약).
- **Response Budget**: 누적 토큰 ~150k 초과 시 에이전트 출력 간결화 경고.

## State Directory

```
.tdc/
  sessions/     # Session persistence
  context/      # Context monitoring + agent-log.md
    .phase      # Current phase (status line reads this)
    .agent-status  # Active agent state (status line reads this)
    .agent-events  # Agent start/stop event log
  plans/        # Generated plans
```
