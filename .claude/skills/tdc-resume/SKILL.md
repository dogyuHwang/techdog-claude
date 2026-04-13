---
name: tdc-resume
description: "TechDog Claude - 저장된 세션을 불러와 작업을 이어갑니다. `list`로 목록 확인."
user-invocable: true
argument-hint: "[list | session_id]"
---

**입력:** $ARGUMENTS

# /tdc-resume — Session Resume

`/tdc-save`로 저장했던 세션을 불러와 중단된 작업을 이어갑니다.

## 실행 흐름

### 1단계: 세션 선택

- `$ARGUMENTS`가 비어있으면 → `.tdc/sessions/`에서 **가장 최근** 세션 파일 선택
- `$ARGUMENTS == "list"` → 저장된 세션 목록만 표시 후 종료 (재개 안 함)
- `$ARGUMENTS`가 ID면 → 해당 세션 파일 읽기 (없으면 에러 + 목록 안내)

### `/tdc-resume list` 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] SAVED SESSIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ID                           Date        Task                      Status
  ─────────────────────────    ─────────   ──────────────────────    ──────
  2026-04-13T14-23-45          2시간 전     API 인증 구현              in_progress
  2026-04-12T09-05-18          1일 전       대시보드 리팩토링           pending
  2026-04-10T18-40-02          3일 전       로그인 버그 수정           completed

  재개:  /tdc-resume <ID>   (또는 `/tdc-resume`로 최신 재개)
  정리:  /tdc-clean --days 7
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2단계: 세션 요약 표시

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] RESUMING SESSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ID:      2026-04-13T14-23-45
  Saved:   2시간 전
  Task:    <원래 요청>
  Deep:    active | inactive

  Completed (2):
    ✓ API 스키마 설계
    ✓ User 모델 구현

  In Progress (1):
    → Auth 미들웨어 구현 (50% 완료)

  Pending (4):
    · JWT 토큰 발급 엔드포인트
    · 로그인/회원가입 폼
    · 비밀번호 초기화 플로우
    · 통합 테스트

  Files modified: 3 (src/models/User.ts, src/schemas/auth.ts, ...)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3단계: 세션 재구성 (풍부도에 따라)

**A. Rich session** (`completed`/`pending` 배열 채워져 있음)
1. TaskList에 기존 태스크 복원
2. `in_progress` 태스크부터 이어서 시작
3. `plan_file`이 있으면 해당 플랜을 컨텍스트로 로드

**B. Minimal session** (메타데이터만)
1. `.tdc/plans/`에서 최신 플랜 로드
2. `git log --oneline -10` + `git diff --stat`으로 최근 변경 파악
3. 현재 상태 재구성 후 진행

### 4단계: Deep 모드 복원

`deep_mode: true`였으면:
```bash
mkdir -p .tdc/context
echo "DEEP=active" > .tdc/context/.deep
# RETRY_COUNT, VERIFY_PASS 등도 복원
```

### 5단계: 작업 재개

- 첫 `in_progress` 태스크를 `in_progress`로 두고 진행
- 파이프라인이 중단되었던 Phase부터 재개 (Planner/Developer/Reviewer)

## 에러 처리

- 세션 파일 없음 → "저장된 세션이 없습니다. `/tdc-save`로 먼저 저장하세요." 안내 후 종료
- JSON 파싱 실패 → 손상된 세션 보고 + 다른 세션 선택 유도
- `plan_file` 유실 → Minimal session 로직으로 폴백
