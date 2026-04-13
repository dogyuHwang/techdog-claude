---
name: tdc-save
description: "TechDog Claude - 현재 세션 상태를 저장하여 나중에 이어갈 수 있게 합니다"
user-invocable: true
argument-hint: "[메모]"
---

**입력:** $ARGUMENTS

# /tdc-save — Session Save

현재 세션의 작업 상태를 `.tdc/sessions/`에 저장합니다.
컨텍스트 오버플로 직전이거나, 잠시 중단하고 나중에 `/tdc-resume`으로 이어갈 때 사용하세요.

## 실행 흐름

### 1단계: 현재 상태 수집

- **진행 중 태스크**: TaskList에서 활성 태스크 및 상태
- **수정 파일**: `git diff --stat`과 `git status` 결과
- **핵심 결정**: 이번 세션에서 내린 설계/구현 결정 요약
- **대기 작업**: 아직 시작하지 않은 후속 작업
- **컨텍스트 요약**: 지금까지의 대화 흐름 압축 (100줄 이내)
- **Deep 모드 상태**: `.tdc/context/.deep` 존재 여부 및 RETRY_COUNT

### 2단계: 세션 파일 작성

`.tdc/sessions/<ISO-timestamp>.json`:

```json
{
  "session_id": "2026-04-13T14-23-45",
  "project": "/current/working/dir",
  "task": "원래 요청한 작업 요약",
  "note": "$ARGUMENTS (사용자가 넘긴 메모)",
  "completed": [],
  "in_progress": [],
  "pending": [],
  "decisions": [],
  "files_modified": [],
  "plan_file": ".tdc/plans/<latest>.md",
  "deep_mode": false,
  "context_summary": "<압축된 대화 요약>",
  "token_usage": { "total": 0, "by_agent": {} }
}
```

### 3단계: 확인 출력

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] SESSION SAVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ID:      2026-04-13T14-23-45
  Task:    <원래 요청>
  Files:   3 modified, 2 pending
  Tasks:   2 completed / 1 in_progress / 4 pending

  재개: /tdc-resume          (최신 세션)
  재개: /tdc-resume <ID>     (특정 세션)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 토큰 최적화

- JSON 형식 (마크다운보다 간결)
- context_summary는 100줄 이내
- 전체 대화 이력 저장 X — 재개에 필요한 최소 정보만
