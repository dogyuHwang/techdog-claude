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

다음 소스에서 상태를 수집한다:

- **Phase 상태**: `.tdc/context/.phase` 파일 읽기
- **에이전트 상태**: `.tdc/context/.agent-status` 읽기
- **진행 중 태스크**: `.tdc/plans/` 최신 플랜에서 `[ ]`/`[x]` 마커 파싱
- **수정 파일**: `git diff --stat HEAD` 결과
- **Git 상태**: `git rev-parse HEAD` (커밋 SHA), `git branch --show-current`
- **Deep 모드**: `.tdc/context/.deep` 파일 전체 내용 (RETRY_COUNT, VERIFY_PASS, TOTAL_REGRESSIONS 등)
- **Regression 이력**: `.tdc/context/.regression-history` 파일 내용
- **토큰 사용량**: `.tdc/context/.agent-tokens` 파일 내용
- **Notepad**: `.tdc/context/notepad.md` 내용 (compaction 후 복구 데이터)
- **컨텍스트 요약**: 지금까지의 작업 요약 (3~5문장, 재개 시 컨텍스트용)
- **마지막 Reviewer 피드백**: 최근 회귀에서 받은 이슈 목록 (재개 시 맥락 유지)

### 2단계: 세션 파일 작성

`.tdc/sessions/<ISO-timestamp>.json`:

```json
{
  "session_id": "2026-04-13T14-23-45",
  "saved_at": "2026-04-13T14:23:45Z",
  "project": "/current/working/dir",
  "git_branch": "main",
  "git_head_sha": "a1b2c3d",
  "task": "원래 요청한 작업 요약 (한 줄)",
  "note": "$ARGUMENTS (사용자가 넘긴 메모)",
  "phase": "Phase 2/4 — IMPLEMENTATION",
  "completed": ["태스크 1 — API 모델 구현", "태스크 2 — DB 스키마"],
  "in_progress": ["태스크 3 — Auth 미들웨어 (50% 완료)"],
  "pending": ["태스크 4 — JWT 엔드포인트", "태스크 5 — 통합 테스트"],
  "decisions": ["JWT 선택 (세션 대신)", "PostgreSQL + Prisma 사용"],
  "files_modified": ["src/models/User.ts", "src/schemas/auth.ts"],
  "plan_file": ".tdc/plans/2026-04-13.md",
  "deep_mode": {
    "active": false,
    "retry_count": 0,
    "verify_pass": 0,
    "total_regressions": 2
  },
  "regression_history": "...내용...",
  "last_reviewer_feedback": "...마지막 Reviewer 원문...",
  "token_usage": {
    "total_estimated": 45200,
    "by_agent": { "planner": 2400, "developer": 32000, "reviewer": 1800 }
  },
  "context_summary": "Auth API 구현 중. User 모델과 DB 스키마는 완료. 현재 JWT 미들웨어 50% 구현 중. 다음: JWT 발급 엔드포인트 → 통합 테스트.",
  "notepad_snapshot": "...notepad.md 내용...",
  "resume_hint": "/tdc-resume 로 태스크 3 'Auth 미들웨어'부터 자동 재개됩니다."
}
```

### 3단계: `.pending` 포인터 파일 작성

세션 저장 후 `.tdc/sessions/.pending`에 최신 세션 ID를 기록한다:

```bash
echo "2026-04-13T14-23-45" > .tdc/sessions/.pending
```

이 파일은 다음 세션 시작 시 Master가 감지하여 자동 재개 배너를 표시하는 데 사용된다.

### 4단계: 확인 출력

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] SESSION SAVED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ID:      2026-04-13T14-23-45
  Task:    Auth API 구현
  Phase:   Phase 2/4 — IMPLEMENTATION
  Files:   3 modified
  Tasks:   2 completed / 1 in_progress / 2 pending
  Deep:    inactive (regressions: 2)

  새 대화에서 바로 재개:
    /tdc-resume           ← 자동으로 이 세션 선택
    /tdc-resume <ID>      ← 특정 세션

  또는 새 대화 시작 시 미완료 세션이 자동 감지됩니다.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 오버플로 자동 저장 동작

`context-guard.sh`가 다음 임계값에서 세션을 자동 저장한다:
- **80 tool calls**: 선제적 저장 + `.pending` 파일 작성 (경고만 아님)
- **120 tool calls**: 강제 저장 + 사용자에게 새 세션 안내

## 토큰 최적화

- JSON 형식 (마크다운보다 간결)
- `context_summary`는 5문장 이내
- `notepad_snapshot`은 있을 때만 포함
- `regression_history`는 최근 3회분만
- `last_reviewer_feedback`은 마지막 1회분만
