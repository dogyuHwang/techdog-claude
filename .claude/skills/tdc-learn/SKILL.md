---
name: tdc-learn
description: "TechDog Claude - Extract reusable problem-solving patterns from sessions as skill files"
user-invocable: true
argument-hint: "[extract|list|apply <name>]"
---

**입력:** $ARGUMENTS

# /tdc-learn - Skill Learning System

세션에서 문제 해결 패턴을 추출하여 재사용 가능한 스킬 파일로 저장합니다.
다음 세션에서 유사한 문제를 만나면 자동으로 해당 스킬이 적용됩니다.

## Commands

### `/tdc-learn extract`
현재 세션에서 학습할 패턴을 추출합니다.

**추출 프로세스:**

1. **세션 분석** — 현재 대화에서 다음을 찾는다:
   - 반복적으로 사용된 디버깅 패턴 (에러 → 진단 → 해결 흐름)
   - 특정 기술 스택에서의 해결책 (예: "React hydration 에러 → useEffect 래핑")
   - 프로젝트 특화 규칙 (예: "이 프로젝트에서는 항상 ESM import 사용")
   - 반복된 코드 패턴 (예: "API 엔드포인트 추가 시 항상 validation middleware 추가")

2. **품질 게이트** — 다음 기준을 모두 충족해야 스킬로 저장:
   - **재사용 가능성**: 이 패턴이 미래에 다시 쓰일 가능성이 높은가?
   - **구체성**: 패턴이 충분히 구체적인가? (너무 일반적이면 거부)
   - **검증됨**: 이 세션에서 실제로 문제를 해결했는가?

3. **스킬 파일 생성** — `.tdc/learned-skills/<name>.md` 형식:
   ```markdown
   ---
   name: <skill-name>
   triggers: [keyword1, keyword2, ...]
   category: debug|pattern|config|workflow
   learned_from: <session_id or date>
   confidence: high|medium
   ---

   ## Problem
   <어떤 상황에서 이 패턴이 필요한가>

   ## Solution
   <구체적인 해결 단계>

   ## Example
   <실제 적용 예시>
   ```

4. **사용자 확인** — 추출된 스킬을 보여주고 저장 여부를 물어본다.

### `/tdc-learn list`
저장된 학습 스킬 목록을 보여줍니다.

1. `.tdc/learned-skills/*.md` 스캔
2. 테이블 출력: Name | Category | Triggers | Confidence | Learned Date

### `/tdc-learn apply <name>`
특정 학습 스킬을 현재 세션에 수동 적용합니다.

1. `.tdc/learned-skills/<name>.md` 읽기
2. 스킬 내용을 현재 작업 컨텍스트에 주입

### `/tdc-learn clean`
confidence가 낮거나 30일 이상 미사용된 스킬을 정리합니다.

## Auto-Injection (자동 주입)

Master Agent가 파이프라인 시작 시 `.tdc/learned-skills/`를 스캔하여:
1. 현재 태스크의 키워드와 각 스킬의 `triggers`를 매칭
2. 매칭된 스킬이 있으면 해당 에이전트에게 컨텍스트로 전달
3. 자동 주입된 스킬은 로그에 `[SKILL-INJECTED] <name>` 태그로 기록

**매칭 규칙:**
- 태스크 설명/스펙에 trigger 키워드가 포함되면 매칭
- confidence: high인 스킬만 자동 주입 (medium은 `/tdc-learn apply`로 수동)
- 한 번에 최대 3개 스킬만 주입 (토큰 절약)

## Token Optimization

- 스킬 파일은 간결하게 유지 (200줄 미만)
- 자동 주입 시 Problem + Solution만 전달 (Example 생략)
- 매칭되지 않는 스킬은 로드하지 않음
