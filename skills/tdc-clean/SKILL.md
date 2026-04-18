---
name: tdc-clean
description: "TechDog Claude - 오래된 세션/컨텍스트 파일 정리"
user-invocable: true
argument-hint: "[--all | --days <N>]"
---

**입력:** $ARGUMENTS

# /tdc-clean — Cleanup

`.tdc/sessions/`, `.tdc/context/` 의 오래된 임시 파일을 정리합니다.

## 기본 동작 (인자 없음)

**7일 이상 지난 세션 파일만 삭제** (기본 안전 모드):

1. `.tdc/sessions/*.json`을 스캔, mtime이 7일 이전인 파일 목록 수집
2. 대상 파일 목록 출력 후 **확인 없이 바로 삭제**
3. 삭제 완료 요약 출력

## 옵션

### `/tdc-clean --days <N>`
`N`일 이상 된 세션만 삭제 (예: `--days 3`).

### `/tdc-clean --all`
**모든 세션 파일 삭제** (위험 — 이 옵션만 사용자 확인 요청 후 삭제).
`.tdc/sessions/*.json` 전체 제거.

### `/tdc-clean context`
진행 중 상태 파일 정리 (파이프라인이 비정상 종료되어 찌꺼기가 남은 경우):
```bash
rm -f .tdc/context/.phase .tdc/context/.agent-status .tdc/context/.agent-events \
      .tdc/context/.read_tokens .tdc/context/.compaction_done \
      .tdc/context/.budget_warned .tdc/context/.deep .tdc/context/.rate_limit \
      .tdc/context/.agent-tokens .tdc/context/notepad.md
```
`.tdc/context/agent-log.md`는 **보존**합니다 (과거 파이프라인 기록용).

## 출력 형식

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [TDC] CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  대상:  .tdc/sessions/ (7일 이전)
  발견:  3 files, 420 KB
  
  - 2026-03-20T11-02-33.json   (24일 전)
  - 2026-03-28T09-14-02.json   (16일 전)
  - 2026-04-02T16-45-11.json   (11일 전)

  → 자동 삭제 완료 (3 files removed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 주의사항

- **플랜 파일**(`.tdc/plans/`)과 **학습 스킬**(`.tdc/learned-skills/`), **project-memory.md**는 건드리지 않음
- 현재 진행 중인 세션 파일(오늘 mtime)은 기본 삭제 대상에서 제외
