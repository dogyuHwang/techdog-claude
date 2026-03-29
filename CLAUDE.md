# TechDog Claude (tdc)

Multi-agent development orchestration system for Claude Code.

## Core Workflow

1. 사용자가 spec 파일(.md)을 작성
2. `/tdc spec.md` 로 실행
3. Planner가 스펙을 분석하여 태스크 분해
4. Developer가 자동 구현 (승인 불필요)
5. Reviewer가 자동 리뷰 → 이슈 심각도에 따라 회귀 루프 실행
6. 모든 진행 상황은 Live Dashboard로 실시간 표시

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

## Live Dashboard

Master Agent가 모든 에이전트 활동을 실시간으로 표시:
- Phase 배너 (PLANNING → IMPLEMENTATION → REVIEW → COMPLETE)
- 에이전트 간 통신 로그 (`[Master → Developer] 태스크 할당`)
- 회귀 발생 시 `[REGRESSION #N]` 태그
- 완료 후 `.tdc/context/agent-log.md`에 전체 로그 기록

## Token Optimization

- 스펙 원문은 planner에게만. 다른 에이전트에는 플랜/태스크만 전달.
- haiku → sonnet → opus 순으로 비용 효율적 라우팅.
- 각 에이전트 프롬프트에 토큰 예산 명시 (planner: 4k, developer: 8k, debugger: 6k, reviewer: 3k).
- rtk (https://github.com/rtk-ai/rtk) 로 명령어 출력 자동 압축 (60-90% 절감).
  - context-guard.sh가 세션 시작 시 rtk 상태를 검증 (미설치/오작동 시 경고).
- 컨텍스트 오버플로 시 자동 세션 저장 (.tdc/sessions/) — 태스크 상태 포함.

## State Directory

```
.tdc/
  sessions/     # Session persistence
  context/      # Context monitoring + agent-log.md
  plans/        # Generated plans
```
