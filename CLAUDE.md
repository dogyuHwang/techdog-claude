# TechDog Claude (tdc)

Multi-agent development orchestration system for Claude Code.

## Core Workflow

1. 사용자가 spec 파일(.md)을 작성
2. `/tdc spec.md` 로 실행
3. Planner가 스펙을 분석하여 태스크 분해
4. 사용자 승인 후 Developer가 구현
5. Reviewer가 자동 리뷰

## Commands

- `/tdc <file.md>` - 스펙 파일을 읽고 기획→개발 진행. 메인 진입점.
- `/tdc <설명>` - 텍스트로 간단히 지시
- `/tdc-plan <file|desc>` - 기획만 진행 (스펙 파일 또는 텍스트)
- `/tdc-dev <file|desc>` - 개발만 진행 (플랜 파일 또는 텍스트)
- `/tdc-debug <desc>` - 디버깅 워크플로우
- `/tdc-review [files]` - 코드 리뷰
- `/tdc-session <save|resume|list|clean>` - 세션 관리

## Agents (model tier)

- **Master** (opus): 오케스트레이션, 세션 전환
- **Planner** (sonnet): 요구사항 분석, 태스크 분해
- **Developer** (sonnet): 코드 구현
- **Debugger** (sonnet): 버그 진단/수정
- **Reviewer** (haiku): 코드 리뷰
- **Architect** (opus): 시스템 설계 (필요시만)

## Token Optimization

- 스펙 원문은 planner에게만. 다른 에이전트에는 플랜/태스크만 전달.
- haiku → sonnet → opus 순으로 비용 효율적 라우팅.
- rtk (https://github.com/rtk-ai/rtk) 로 명령어 출력 자동 압축 (60-90% 절감).
- 컨텍스트 오버플로 시 자동 세션 저장 (.tdc/sessions/).

## State Directory

```
.tdc/
  sessions/     # Session persistence
  context/      # Context monitoring
  plans/        # Generated plans
```
