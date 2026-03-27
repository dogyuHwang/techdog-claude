---
name: tdc
description: "TechDog Claude - Main entry point. Pass a spec file (.md) or describe what you want to build."
user-invocable: true
---

# /tdc — TechDog Claude

멀티 에이전트 개발 오케스트레이션의 메인 진입점입니다.

## 사용법

```
/tdc <파일.md>              스펙 파일을 읽고 기획 → 개발까지 진행
/tdc <설명>                 텍스트로 간단히 지시
/tdc plan <파일.md|설명>    기획만 진행
/tdc dev <파일.md|설명>     개발만 진행
/tdc debug <설명>           디버깅
/tdc review [파일들]        코드 리뷰
/tdc session <명령>         세션 관리
```

## 실행 흐름

### 1단계: 입력 분석

**A. 파일이 전달된 경우** (`.md` 확장자 또는 파일 경로)
1. 해당 파일을 Read 도구로 읽는다
2. 스펙이면 → **기획 워크플로우**로 진입
3. 이미 태스크가 분해된 플랜이면 → **개발 워크플로우**로 진입

**B. 서브커맨드가 있는 경우** (plan, dev, debug, review, session)
- 해당 워크플로우로 직접 라우팅

**C. 텍스트만 전달된 경우**
- 의도를 분석하여 적절한 에이전트 선택
- 단순 질문 → 직접 답변
- 구현 요청 → 복잡도에 따라 기획 또는 개발로 라우팅

### 2단계: 프로젝트 초기화

처음 실행 시 자동으로:
```bash
mkdir -p .tdc/{sessions,context,plans}
```

### 3단계: 자동 파이프라인 실행

Master Agent가 전체 파이프라인을 **사용자 개입 없이 자동으로** 실행한다.
사용자는 `/tdc spec.md` 한 번만 입력하면 된다.

```
스펙 파일 읽기
    ↓
[Phase 1] Planner Agent — 태스크 분해 → .tdc/plans/에 저장
    ↓ (자동 진행, 승인 불필요)
[Phase 2] Developer Agent — 태스크별 순차/병렬 구현
    ↓ (에러 발생 시 자동으로 Debugger 호출)
[Phase 3] Reviewer Agent — 자동 코드 리뷰
    ↓ (치명적 이슈 발견 시 자동으로 Developer가 수정)
[Phase 4] 최종 결과 보고 — 사용자에게 한 번에 전달
```

**에이전트 간 통신은 Master를 통해 자동으로 이루어진다.**
Developer가 에러를 만나면 Master가 Debugger를 호출하고,
Reviewer가 문제를 찾으면 Master가 Developer에게 수정을 지시한다.
사용자가 중간에 개입할 필요 없다.

## 스펙 파일 형식

자유 형식. 어떤 형태든 만들고 싶은 것이 적혀 있으면 됩니다.
다음 정보가 포함되면 더 좋은 결과를 얻을 수 있습니다:
- 무엇을 만드는지 (목적)
- 어떤 기술을 쓸지 (기술 스택)
- 어떤 기능이 필요한지 (기능 목록)

## 토큰 최적화 규칙

- 스펙 원문은 planner에게만 전달 (다른 에이전트에는 플랜만 전달)
- 단순 작업은 에이전트 위임 없이 직접 처리
- 각 에이전트에게는 해당 태스크에 필요한 최소 컨텍스트만 전달
