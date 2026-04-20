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
- `/tdc-deep <file.md|설명>` - Deep 모드 (끈질긴 검증 + 배너·요약·리뷰 강제)
- `/tdc-plan <file|desc>` - 기획만 진행 (스펙 파일 또는 텍스트)
- `/tdc-dev <file|desc>` - 개발만 진행 (플랜 파일 또는 텍스트)
- `/tdc-debug <desc>` - 디버깅 워크플로우
- `/tdc-review [files]` - 코드 리뷰
- `/tdc-learn [patterns ...]` - 프로젝트 자동 학습(project-memory.md) + 세션 패턴 추출
- `/tdc-save [메모]` / `/tdc-resume [list|ID]` - 세션 저장/재개
- `/tdc-clean [--days N]` - 오래된 세션 정리
- `/tdc-upgrade` / `/tdc-version` - 업그레이드/버전 확인

## Agents (model)

- **Master** (claude-opus-4-6): 오케스트레이션, Live Dashboard, 회귀 루프 관리
- **Planner** (claude-sonnet-4-6): 요구사항 분석, 태스크 분해, 재기획 (회귀 시); 복잡한 의존성 분석 시 Extended Thinking 활성화
- **Developer** (claude-sonnet-4-6): 코드 구현
- **Debugger** (claude-sonnet-4-6): 버그 진단/수정
- **Reviewer** (claude-haiku-4-5-20251001): 2단계 리뷰 — Stage 1 Spec Compliance + Stage 2 Code Quality
- **Security Reviewer** (claude-haiku-4-5-20251001): 보안 전문 리뷰 (OWASP top 10)
- **Test Engineer** (claude-sonnet-4-6): 테스트 커버리지 분석 + 테스트 자동 생성
- **Meta-Reviewer** (claude-haiku-4-5-20251001): tdc 내부 일관성 감사 (tdc 파일 수정 시 자동 호출)
- **Architect** (claude-opus-4-6): 시스템 설계; Extended Thinking (8k budget) 활성화

## Agent Permission Mode

- 모든 서브 에이전트는 `mode: "bypassPermissions"`로 호출.
- 파이프라인 진행 중 사용자에게 승인을 묻지 않음 (완전 자동).
- 안전장치: git 복구 가능 + Reviewer/Security Reviewer 사후 검증.

## Regression Loop (회귀 루프)

Reviewer 2단계 리뷰 후 심각도에 따라 자동 회귀:
- **Stage 1 (Spec Compliance)**: 스펙 미준수 → Developer 즉시 재구현
- **Stage 2 (Code Quality)**:
  - `code-level` → Developer가 직접 수정
  - `design-level` → Planner 재기획 → Developer 재구현 (Reviewer 원문 피드백 그대로 전달)
  - `critical` → Planner 재기획 + Developer 수정
- 같은 이슈 2회 반복 → **Oscillation 감지** → Architect 에스컬레이션 (Extended Thinking)
- Reviewer가 APPROVE할 때까지 무제한 회귀 (컨텍스트 오버플로 시 세션 저장/재개)

### Deep Mode (끈질긴 검증)

`/tdc deep spec.md`로 활성화. 일반 모드보다 엄격:
- 회귀 횟수 제한 없음 (일반: design-level 최대 5회)
- 테스트 + 빌드 + Reviewer 다중 검증
- Developer 3회 재시도 실패 시 Architect 에스컬레이션
- 완료 조건: Reviewer APPROVE + 테스트 전체 통과 + 빌드 성공

## Deep Interview (사전 질문)

가중치 기반 명확도 측정 시스템:
- 5개 차원 (기술스택/플랫폼/기능/비즈니스/범위) × 0~5점 × 가중치
- 3.5 이상: 질문 없이 시작 | 2.0~3.4: 부족한 차원만 질문 | 2.0 미만: 소크라틱 인터뷰
- 경계값(3.5)에서는 적극적으로 질문 (조금이라도 궁금하면 질문하는 쪽 택)
- 기존 프로젝트 수정 요청은 코드에서 기술스택 추론 → 높은 점수

## Skill Learning (스킬 학습)

**자동 추출**: Phase 4 완료 시 Master가 자동으로 재사용 가능한 패턴을 추출.
**수동 추출**: `/tdc-learn extract`로 현재 세션에서 직접 추출도 가능.
- `.tdc/learned-skills/<name>.md`에 저장
- trigger 키워드 매칭으로 미래 세션에 자동 주입
- Master Agent가 Phase 시작 시 매칭 스킬을 에이전트에 전달

## Live Dashboard & Agent Visibility

에이전트 활동을 **3중 가시성**으로 실시간 표시:

1. **Status Line** (터미널 하단 상시): `[TDC] Phase 2/4 — IMPLEMENTATION | developer working | 45 tools | 5h:42% ⏰1h23m`
   - `.tdc/context/.phase` + `.tdc/context/.agent-status` 파일 기반
   - `tdc-status.sh` 스크립트가 읽어서 표시 (stdin으로 rate limit 정보 수신 → 5시간 버킷 소진율 + 리셋 시간 표시)
2. **Console Messages** (대화 흐름 중): `[TDC] developer agent started (14:03:23)`
   - SubagentStart/SubagentStop 훅 (`agent-tracker.sh`)이 자동 출력
3. **Dashboard Banners** (Phase 전환 시): 타임스탬프 포함 상세 로그
   - Master Agent가 Phase 배너 + 에이전트 간 통신 로그 출력
   - 완료 후 `.tdc/context/agent-log.md`에 전체 로그 기록
4. **Token Summary** (매 응답 종료 시): 에이전트별 토큰 사용량 자동 표시
   - Stop 훅 (`token-display.sh`)이 모든 응답 끝에 자동 출력
   - 실제 세션 토큰(Stop 이벤트 JSON) + 서브에이전트 추정치(`agent-tracker.sh`)
   - 항상 출력 (툴 사용 횟수 무관)

## Token Optimization

- 스펙 원문은 planner에게만. 다른 에이전트에는 플랜/태스크만 전달.
- Haiku 4.5 → Sonnet 4.6 → Opus 4.6 순으로 비용 효율적 라우팅.
- 각 에이전트 프롬프트에 토큰 예산 명시 (planner: 4k, developer: 8k, debugger: 6k, reviewer: 3k).
- rtk (https://github.com/rtk-ai/rtk) 로 명령어 출력 자동 압축 (60-90% 절감).
  - context-guard.sh가 세션 시작 시 rtk 상태를 검증 (미설치/오작동 시 경고).
- 컨텍스트 오버플로 시 자동 세션 저장 (.tdc/sessions/) — 태스크 상태 포함.
- **Smart Read**: 에이전트가 Grep/Glob 후 타겟 Read (>200줄 파일은 offset/limit 필수). `smart-read.sh` 훅이 모니터링.
- **Diff-Only Review**: Reviewer에게 전체 파일 대신 `git diff --unified=5` 전달 (50-70% 절감).
- **Conversation Compaction**: 60 tool calls에서 컨텍스트 압축 트리거 (중간 결과 요약).
- **Response Budget**: 누적 토큰 ~150k 초과 시 에이전트 출력 간결화 경고.
- **Rate Limit Guard**: API rate limit 자동 감지 + 대기 시간 안내 + 3회 초과 시 세션 저장 제안.
- **rtk Tee Recovery**: Bash 툴 비정상 종료 시 rtk가 압축한 전체 출력을 자동으로 복원 경로 안내 (`rtk-tee-recovery.sh` PostToolUse/Bash 훅).
- **Preemptive Compaction**: PreCompact 훅으로 압축 전 상태 자동 저장 → notepad.md로 복구.
- **Token Dashboard**: Phase 4에서 에이전트별 토큰 사용량 게이지 바 표시 + rtk 절감 추정.

## Project Memory & Context Packs

`/tdc-learn` 실행 시 3-Pack으로 저장:
- `.tdc/project-memory.md` — 기술 결정, 컨벤션, 비즈니스 규칙 (전 에이전트 공통)
- `.tdc/context-packs/developer-context.md` — 실제 코드 패턴, import 스타일, 네이밍 컨벤션
- `.tdc/context-packs/planner-context.md` — 아키텍처 패턴, 태스크 분해 가이드
- `.tdc/context-packs/reviewer-context.md` — 품질 기준, 린터 규칙, anti-pattern 목록
- Master Agent가 Phase 0에서 각 에이전트에 맞는 팩을 자동 주입

## Parallel Development (git worktree)

독립 태스크를 git worktree로 병렬 구현:
- Planner가 의존성 분석 → 독립 태스크 식별
- 각 Developer가 별도 worktree에서 병렬 작업
- 완료 후 자동 merge → 충돌 시 Debugger가 해결

## State Directory

```
.tdc/
  sessions/        # Session persistence
  context/         # Context monitoring + agent-log.md
    .phase         # Current phase (status line reads this)
    .agent-status  # Active agent state (status line reads this)
    .agent-events  # Agent start/stop event log
    .agent-tokens  # Per-agent token usage tracking
    .deep         # Deep mode state (when active)
    .rate_limit    # Rate limit tracking
    notepad.md     # Compaction survival data (auto-saved before compaction)
  plans/           # Generated plans
  logs/            # Structured event log (events.ndjson — NDJSON per-agent events)
  learned-skills/  # Auto-learned skill patterns (/tdc-learn)
  project-memory.md # Cross-session project knowledge
  context-packs/   # Per-agent context generated by /tdc-learn
    developer-context.md
    planner-context.md
    reviewer-context.md
```
