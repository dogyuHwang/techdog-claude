---
name: tdc-plan
description: "TechDog Claude - Planning workflow. Accepts a spec file (.md) or inline description."
user-invocable: true
---

# /tdc-plan — 기획 워크플로우

스펙 파일 또는 텍스트 설명을 받아 실행 가능한 개발 플랜을 생성합니다.

## 사용법

```
/tdc-plan spec.md                  스펙 파일 기반 기획
/tdc-plan plan.md                  기획서 파일 기반
/tdc-plan 간단한 Flask CRUD 서버    인라인 설명
```

## 실행 흐름

### 1. 입력 읽기

**파일이 전달된 경우:**
1. Read 도구로 파일을 읽는다
2. 내용을 파싱하여 목적, 기술 스택, 기능 목록, 요구사항을 추출한다

**텍스트만 전달된 경우:**
1. 설명이 충분한지 판단한다
2. 부족하면 최대 3개까지 핵심 질문을 한다:
   - "어떤 기술 스택을 사용하시나요?"
   - "핵심 기능 3가지를 알려주세요"
   - "특별한 요구사항이 있나요? (인증, DB, 배포 등)"
3. 질문은 3개를 넘기지 않는다 (토큰 절약)

### 2. 플랜 생성

Planner Agent (model: sonnet)를 호출하여 다음을 생성한다:

```markdown
## Plan: <프로젝트 이름>

### 목표
<한 줄 요약>

### 기술 스택
- <언어/프레임워크>
- <DB>
- <기타>

### 디렉토리 구조 (예상)
```
project/
├── app.py
├── models.py
└── ...
```

### 태스크
1. [ ] <태스크> — 난이도: low|mid|high — 담당: developer|debugger|architect
2. [ ] <태스크> — ...

### 의존성
- Task N → Task M (이유)

### 검증 기준
- [ ] <기준 1>
- [ ] <기준 2>
```

### 3. 플랜 저장

`.tdc/plans/<프로젝트명>.md`에 저장한다.

### 4. 사용자 확인

플랜을 보여주고 묻는다:

> 이 플랜대로 진행할까요?
> - **Y** → `/tdc-dev` 워크플로우로 자동 전환
> - **수정 요청** → 플랜 수정 후 재확인
> - **N** → 중단

## 토큰 최적화

- 기존 코드베이스 탐색 시 파일 이름만 확인 (내용 X)
- 플랜 출력은 200줄 이내
- Planner에게 스펙 원문 + 파일 트리만 전달
