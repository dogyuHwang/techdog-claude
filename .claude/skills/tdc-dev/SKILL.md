---
name: tdc-dev
description: "TechDog Claude - Development workflow. Accepts a plan file or task description."
user-invocable: true
argument-hint: "[plan.md 또는 설명]"
---

**입력:** $ARGUMENTS

# /tdc-dev — 개발 워크플로우

플랜 파일 또는 태스크 설명을 받아 코드를 구현합니다.

## 사용법

```
/tdc-dev                           .tdc/plans/ 에서 최신 플랜을 찾아 실행
/tdc-dev plan.md                   플랜 파일 기반 구현
/tdc-dev "로그인 API 구현"          인라인 태스크
```

## 실행 흐름

### 1. 플랜 확인

**파일이 전달된 경우:**
1. Read 도구로 파일을 읽는다
2. 태스크 목록이 있으면 → 순서대로 구현
3. 스펙이지만 태스크가 없으면 → `/tdc-plan`을 먼저 권장

**파일 없이 실행된 경우:**
1. `.tdc/plans/` 디렉토리에서 가장 최근 플랜을 찾는다
2. 플랜이 있으면 → 해당 플랜의 미완료 태스크부터 구현
3. 플랜이 없으면 → 인라인 설명 기반으로 직접 구현

### 2. 구현

Developer Agent (model: sonnet)를 호출한다:

- 태스크별로 순차 실행 (의존성이 있는 경우)
- 독립적인 태스크는 병렬 실행 가능
- 각 태스크 완료 후 플랜의 체크박스를 업데이트

**에이전트에게 전달하는 컨텍스트:**
- 현재 태스크 설명
- 관련 파일만 (Read로 필요한 파일만 읽기)
- 이전 태스크에서 생성/수정한 파일 목록

### 3. 검증

구현 완료 후:
1. 프로젝트에 테스트가 있으면 → 테스트 실행
2. 린터/타입체크가 있으면 → 실행
3. 실패 시 → Debugger Agent에게 자동 위임

### 4. 보고

```markdown
### 구현 완료

**생성된 파일:**
- `app.py` — Flask 앱 + 라우트
- `models.py` — DB 모델

**수정된 파일:**
- `requirements.txt` — 의존성 추가

**테스트:** 통과 (5/5)

**다음 단계:** /tdc-review 로 코드 리뷰 권장
```

## 토큰 최적화

- 구현할 파일만 읽기 (전체 프로젝트 탐색 X)
- 변경하지 않는 파일은 컨텍스트에 포함하지 않기
- 결과 보고는 간결하게 — diff가 설명을 대신함
