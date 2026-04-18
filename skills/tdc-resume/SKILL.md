---
name: tdc-resume
description: "TechDog Claude - 저장된 세션을 불러와 작업을 이어갑니다. `list`로 목록 확인."
user-invocable: true
argument-hint: "[list | session_id]"
---

**입력:** $ARGUMENTS

# /tdc-resume — Session Resume

`/tdc-save`로 저장했던 세션을 불러와 중단된 작업을 이어갑니다.

## Auto-Resume Detection (자동 감지)

**Master Agent는 파이프라인 시작 전 Phase 0에서 다음을 자동 체크한다:**

```bash
cat .tdc/sessions/.pending 2>/dev/null
```

`.pending` 파일이 존재하면:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] 미완료 세션 감지
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  세션:   2026-04-13T14-23-45
  작업:   Auth API 구현
  단계:   Phase 2/4 — IMPLEMENTATION (태스크 3/5 진행 중)
  저장:   12분 전

  → /tdc-resume 으로 이어서 진행하시겠습니까?
    (y) 재개  |  (n) 새 작업 시작
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

사용자 응답 없이 `/tdc-resume`만 실행 시 → 자동으로 `.pending` 세션 재개.

## 실행 흐름

### 1단계: 세션 선택

- `$ARGUMENTS`가 비어있으면 → `.tdc/sessions/.pending`에서 세션 ID 읽기, 없으면 최신 JSON 파일
- `$ARGUMENTS == "list"` → 저장된 세션 목록만 표시 후 종료
- `$ARGUMENTS`가 ID면 → 해당 세션 파일 읽기

### `/tdc-resume list` 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] SAVED SESSIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  *  ID                    Date       Phase        Task
  ─────────────────────   ─────────  ───────────  ─────────────────────
  ★ 2026-04-13T14-23-45  12분 전    Phase 2/4    Auth API 구현 (in_progress)
     2026-04-12T09-05-18  1일 전     Phase 1/4    대시보드 리팩토링
     2026-04-10T18-40-02  3일 전     completed    로그인 버그 수정

  ★ = .pending (가장 최근 미완료)
  재개:  /tdc-resume         (★ 세션 자동 선택)
  재개:  /tdc-resume <ID>    (특정 세션)
  정리:  /tdc-clean --days 7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2단계: 세션 요약 표시 + 변경 감지

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] RESUMING SESSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ID:      2026-04-13T14-23-45
  Saved:   12분 전 (git: a1b2c3d | branch: main)
  Task:    Auth API 구현
  Phase:   Phase 2/4 — IMPLEMENTATION
  Deep:    inactive (총 회귀: 2회)

  Context: Auth API 구현 중. User 모델과 DB 스키마는 완료.
           현재 JWT 미들웨어 50% 구현 중.

  Completed (2):
    ✓ API 스키마 설계
    ✓ User 모델 구현

  In Progress (1):
    → Auth 미들웨어 구현 (50% 완료)

  Pending (2):
    · JWT 토큰 발급 엔드포인트
    · 통합 테스트

  Files modified: src/models/User.ts, src/schemas/auth.ts (+2 others)

  ⚠️ 저장 이후 변경 감지:
    git diff a1b2c3d..HEAD → 2 files changed (저장 이후 추가 수정됨)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

저장 이후 변경이 있으면 `git diff <saved_sha>..HEAD --stat`으로 표시하여 컨텍스트 불일치를 사전에 인지시킨다.

### 3단계: 상태 복원

**Rich session** (`phase`, `in_progress` 포함):
1. Deep 모드 복원: `deep_mode.active == true`이면:
   ```bash
   echo "DEEP=active" > .tdc/context/.deep
   echo "RETRY_COUNT={deep_mode.retry_count}" >> .tdc/context/.deep
   echo "VERIFY_PASS={deep_mode.verify_pass}" >> .tdc/context/.deep
   echo "TOTAL_REGRESSIONS={deep_mode.total_regressions}" >> .tdc/context/.deep
   ```
2. Regression history 복원: `regression_history` → `.tdc/context/.regression-history`
3. Notepad 복원: `notepad_snapshot`이 있으면 → `.tdc/context/notepad.md`에 기록
4. Phase 복원: `phase` → `.tdc/context/.phase`
5. `last_reviewer_feedback`을 컨텍스트에 로드 (재개 시 Reviewer 맥락 유지)

**Minimal session** (필드 부족):
1. `.tdc/plans/`에서 최신 플랜 로드
2. `git log --oneline -5` + `git diff --stat`으로 현재 상태 파악
3. 가능한 상태 재구성 후 진행

### 4단계: `.pending` 파일 정리 + 작업 재개

```bash
rm -f .tdc/sessions/.pending   # 재개 시작 시 삭제 (파이프라인 완료 전까지 다시 생성 가능)
```

파이프라인이 `in_progress` 태스크부터 재개:
- Phase 2 중단 → Developer에게 `in_progress` 태스크 할당
- Phase 3 중단 → Reviewer 재호출 (저장 이후 diff 기반)
- Phase 1 중단 → Planner 재호출

### 5단계: 재개 완료 배너

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] SESSION RESUMED — Auth 미들웨어부터 재개
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 에러 처리

| 상황 | 처리 |
|------|------|
| 세션 파일 없음 | "저장된 세션이 없습니다. `/tdc-save`로 먼저 저장하세요." |
| JSON 파싱 실패 | 손상된 세션 보고 + 다른 세션 선택 유도 |
| `plan_file` 유실 | Minimal session 로직으로 폴백 |
| `git_head_sha` 불일치 | 경고 표시 후 계속 진행 (git diff 확인 안내) |
| `.pending` 세션 완료 상태 | `.pending` 삭제 후 "이미 완료된 세션입니다" 안내 |
