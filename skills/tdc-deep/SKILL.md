---
name: tdc-deep
description: "TechDog Claude - Deep mode (끈질긴 검증 루프). 배너·요약·리뷰를 항상 강제 출력."
user-invocable: true
argument-hint: "<파일.md 또는 설명>"
---

**입력:** $ARGUMENTS

# /tdc-deep — Deep Mode (강제 가시성)

일반 `/tdc`와 달리 **항상 Phase 배너·Reviewer 검증·완료 요약을 강제 출력**하는 엄격 모드입니다.
"파이프라인이 돌고 있는지 체감되지 않는다"는 문제를 해결하기 위해 설계되었습니다.

## 일반 모드와의 차이

| 항목 | `/tdc` (일반) | `/tdc-deep` |
|------|---------------|-------------|
| Phase 배너 | 생략 가능 | **항상 출력** |
| Reviewer 호출 | 태스크 규모에 따라 | **항상 실행** |
| 완료 요약 | 선택적 | **항상 표시** (이슈/토큰/RTK 절감) |
| 회귀 루프 횟수 | design-level 최대 5회 | **무제한** |
| 검증 단계 | Reviewer만 | 테스트 + 빌드 + Reviewer 다중 |
| Developer 재시도 | 2회 후 보고 | 3회 실패 시 Architect 에스컬레이션 |

## 실행 흐름

### 1단계: Deep 모드 활성화

```bash
mkdir -p .tdc/context
echo "DEEP=active" > .tdc/context/.deep
echo "RETRY_COUNT=0" >> .tdc/context/.deep
echo "VERIFY_PASS=0" >> .tdc/context/.deep
echo "TOTAL_REGRESSIONS=0" >> .tdc/context/.deep
```

### 2단계: Phase 배너 강제 출력

Master Agent는 각 Phase 진입 시 **반드시 다음 형식의 배너를 출력**한다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [DEEP] Phase 1/4 — PLANNING
  Agent: planner (sonnet)    Time: 14:03:22
  Token Budget: 4k  |  Cumulative used: ~0k
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

각 에이전트 호출 **전**에 토큰 예산과 현재까지 누적 사용량을 표시한다:

```
  [Token] planner  budget: 4k  |  session so far: ~2.1k (planner: ~1.2k + master: ~0.9k)
  [Token] developer  budget: 8k  |  session so far: ~7.4k
```

`.tdc/context/.agent-tokens` 파일에서 누적값을 읽는다. 파일이 없으면 "~0k"로 표시.

### 3단계: 파이프라인 실행

```
[사전 질문] 필요 시 (명확도 점수 < 3.5)
    ↓
[Phase 1/4] PLANNING — Planner Agent
    ↓
[Phase 2/4] IMPLEMENTATION — Developer Agent
    ↓
[Deep Verify Loop]
    ├─ 테스트 실행 → 실패 시 Debugger
    ├─ 빌드/타입체크 → 실패 시 Debugger
    └─ Reviewer 코드 리뷰 → 이슈 심각도별 회귀
    ↓ (Reviewer APPROVE + 테스트/빌드 전체 통과까지 반복)
[Phase 3/4] REVIEW — 최종 검증 통과
    ↓
[Phase 4/4] COMPLETE — **요약 배너 강제 출력**
```

### 4단계: 완료 요약 (강제)

작업이 끝나면 **반드시** 다음 요약을 출력한다. `.tdc/context/.agent-tokens` 파일을 읽어 실제 사용량을 채운다.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [DEEP] COMPLETE — 검증 통과
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ 테스트: {pass}/{total}  (또는 N/A)
  ✓ 빌드: {success|skipped}
  ✓ Reviewer Stage 1: COMPLIANT
  ✓ Reviewer Stage 2: APPROVE (critical {C} / design {D} / code {CL})
  ✓ 회귀 루프: {N}회 실행  (oscillation: {없음 | N회 감지 → Architect 에스컬레이션})

  📁 수정된 파일 ({N}개):
     - src/foo.ts (+32 / -5)
     - src/bar.ts (+12 / -0)

  📊 토큰 사용 (에이전트별):
  ─────────────────────────────────────────────────
  planner           ██░░░░░░░░░░░░░░░░░░   ~{K} tokens
  developer         ████████████░░░░░░░░   ~{K} tokens
  reviewer          ██░░░░░░░░░░░░░░░░░░   ~{K} tokens
  [others if used]  █░░░░░░░░░░░░░░░░░░░   ~{K} tokens
  ─────────────────────────────────────────────────
  TOTAL: ~{K} tokens  |  RTK 절감: ~{saved} est.
  Cost: ~${usd} (sonnet) + ${usd} (haiku/opus)

  📝 에이전트 로그: .tdc/context/agent-log.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**게이지 생성 규칙**: 가장 큰 값을 20칸 기준으로 `█`/`░` 비율 표시. `.agent-tokens` 파일이 없으면 "~0k"로 표시.

### 5단계: Deep 모드 해제

```bash
rm -f .tdc/context/.deep
```

## 에스컬레이션 규칙

- Developer가 같은 태스크에서 **3회 연속 실패** 시 → Architect Agent(opus) 자동 호출
- Reviewer `critical` 이슈가 **2회 연속 반복** 시 → Planner 재기획 + Architect 설계 검토
- 회귀 총 횟수 무제한이나, 토큰 누적 200k 초과 시 → 자동 세션 저장 + 사용자 확인

## 토큰 최적화

- Phase 배너/완료 요약은 형식이 짧아 오버헤드 미미 (~200 토큰)
- Reviewer에게는 전체 파일 대신 `git diff --unified=5` 전달 (일반 모드와 동일)
- `.tdc/context/.deep`의 RETRY_COUNT로 무한 루프 방지
