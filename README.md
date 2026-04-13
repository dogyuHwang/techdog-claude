한국어 | [English](README_EN.md)

# TechDog Claude (tdc)

<p align="center">
  <img src="tdc.png" alt="TechDog Claude" width="400" />
</p>

> Claude Code를 위한 멀티 에이전트 개발 오케스트레이션 시스템

**만들고 싶은 것을 문서로 적고, `/tdc spec.md` 한 줄이면 AI 에이전트 팀이 기획부터 개발까지 해줍니다.**

[시작하기](#이게-뭔가요) | [설치](#설치) | [사용법](#사용법-처음부터-따라하기) | [명령어](#명령어-모음) | [아키텍처](#아키텍처) | [FAQ](#faq)

---

## 이게 뭔가요?

[Claude Code](https://claude.ai/code)는 터미널에서 AI와 대화하며 코드를 작성하는 도구입니다.

TechDog Claude(tdc)는 이 Claude Code 위에 **8명의 전문 AI 에이전트**를 배치하여,
혼자 하는 코딩을 **팀 개발**처럼 바꿔줍니다.

```
평소:  나 ↔ Claude (1:1 대화)

tdc:   나 → Master Agent → Planner           (기획)
                         → Developer          (개발)
                         → Debugger           (디버깅)
                         → Reviewer           (리뷰)
                         → Security Reviewer  (보안 리뷰)
                         → Test Engineer      (테스트 생성)
                         → Architect          (설계)
```

---

## 설치

### 사전 준비

1. **Node.js** (18 이상) — [설치](https://nodejs.org/)
2. **Claude Code** 설치:
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```
3. Claude Code 로그인:
   ```bash
   claude    # 처음 실행하면 로그인 안내가 나옵니다
   ```

### tdc 설치

```bash
# 방법 A: 원격 설치 (권장)
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

# 방법 B: 클론 후 설치
git clone https://github.com/dogyuHwang/techdog-claude.git
cd techdog-claude && bash install.sh
```

설치하면 자동으로:
- Claude Code에 `/tdc` 슬래시 커맨드가 추가됩니다 (`~/.claude/skills/` 에 설치)
- [rtk](https://github.com/rtk-ai/rtk) (토큰 60-90% 절감 도구)가 함께 설치됩니다
- Claude Code Team 모드가 활성화됩니다
- **개발언어 스킬팩** 선택 설치 (Python/Django, Next.js, Go, Rust, Java, Flutter, Kotlin, React)

설치 시 개발언어 스킬팩 선택 화면:
```
=== 개발언어 Skill Pack Installation ===

  1) 전체 설치 (All skill packs)
  2) 선택 설치 (Choose individually)
  3) 스킬팩 없이 설치 (Core only)

  선택 (1/2/3) [1]:
```

> 설치 직후 바로 사용 가능합니다. 터미널에서 `claude`를 실행하고 `/tdc spec.md`를 입력하세요.

---

## 사용법 (처음부터 따라하기)

### 1. 스펙 파일 작성

**스펙 파일**은 "내가 뭘 만들고 싶은지" 적은 문서입니다.
형식은 자유이고, 메모장이나 에디터로 `spec.md` 파일을 만들면 됩니다.

**예시 — 간단한 웹 서버:**

```markdown
# 내 블로그 API

## 목적
블로그 글을 관리하는 REST API 서버

## 기술 스택
- Python + Flask
- SQLite

## 기능
- 글 작성 (제목, 내용, 작성자)
- 글 목록 조회
- 글 수정 / 삭제
- 헬스체크 엔드포인트
```

**예시 — React 앱:**

```markdown
# 할일 관리 앱

## 목적
간단한 Todo 앱

## 기술 스택
- React + TypeScript
- localStorage 저장

## 기능
- 할일 추가 / 삭제 / 완료 체크
- 필터링 (전체 / 완료 / 미완료)
- 다크모드
```

**예시 — CLI 도구:**

```markdown
# 파일 정리 스크립트

## 목적
다운로드 폴더의 파일을 확장자별로 자동 분류

## 기술 스택
- Python

## 기능
- 지정한 폴더를 스캔
- 확장자별로 하위 폴더로 이동 (images/, docs/, videos/ 등)
- 중복 파일 감지
- dry-run 모드 (실제로 옮기지 않고 미리보기)
```

> 한국어/영어 모두 OK. 완벽하지 않아도 됩니다. 스펙이 모호하면 AI가 개발 전에 한 번만 질문합니다.

### 2. 실행

터미널에서 Claude Code를 열고 `/tdc` 명령어를 입력합니다:

```bash
claude               # Claude Code 실행
```

Claude Code 입력창에서:

#### 일반 모드 — 기획부터 개발까지 자동 진행
```
/tdc spec.md
```

#### Deep 모드 — 모든 검증을 통과할 때까지 끈질기게 반복
```
/tdc deep spec.md
```

> **일반 모드**는 기획 → 개발 → 리뷰를 한 번 돌고 완료합니다.
> **Deep 모드**는 테스트 통과 + 빌드 성공 + 리뷰 APPROVE가 **전부 통과할 때까지** 수정을 반복합니다.
> 품질이 중요한 작업에는 Deep 모드를 추천합니다.

어느 모드든 **Master Agent가 전부 자동으로 처리합니다:**

```
/tdc spec.md (또는 /tdc deep spec.md)   ← 이것만 입력하면 끝!
    ↓
[필요 시] 스펙이 모호하면 개발 전에 한 번만 종합 질문 (명확하면 생략)
    ↓
[자동] Planner Agent가 스펙을 분석하고 태스크를 분해합니다
    ↓
[자동] Developer Agent가 태스크별로 코드를 작성합니다
    ↓ (에러가 나면?)
[자동] Debugger Agent가 알아서 원인을 찾고 고칩니다  ← 사용자 개입 불필요
    ↓
[자동] 테스트/린터 실행 → 실패 시 Debugger가 자동 수정
    ↓
[자동] Reviewer + Security Reviewer가 코드를 검토합니다
    ↓ (심각한 문제가 있으면?)
[자동] Developer Agent가 다시 수정합니다  ← 사용자 개입 불필요
    ↓ (Deep 모드라면?)
[자동] 테스트 + 빌드 + 리뷰 전부 통과할 때까지 반복  ← 절대 대충 넘어가지 않음
    ↓
최종 결과를 사용자에게 보고합니다 (에이전트별 토큰 사용량 포함)
```

> **핵심:** 스펙이 모호하면 개발 전에 한 번만 질문하고, 답변 후에는 끝까지 자동입니다.
> 에이전트들끼리 Master Agent를 통해 자동으로 소통합니다.
> **사용자는 처음에 한 번만 입력하면 됩니다.**

### 3. 개별 명령어 (선택사항)

자동 파이프라인이 아니라, 특정 단계만 따로 실행하고 싶을 때 사용합니다.
**평소에는 쓸 일이 없습니다** — `/tdc spec.md` 하나면 충분합니다.

```
/tdc-plan spec.md     ← 기획만 하고 멈추고 싶을 때
/tdc-dev              ← 기획은 이미 했고 개발만 시작하고 싶을 때
/tdc-debug <에러>     ← 이미 만들어진 코드에서 새 에러를 발견했을 때
/tdc-review           ← 직접 작성한 코드를 리뷰받고 싶을 때
/tdc-learn            ← 기존 프로젝트에 tdc 도입할 때 (자동 분석 → project-memory.md)
/tdc-upgrade          ← tdc를 최신 버전으로 업데이트
```

### 4. 프로젝트 학습 (기존 프로젝트에 처음 도입할 때)

기존 프로젝트에서 tdc를 처음 쓸 때, 한 번만 실행하면 됩니다:

```
/tdc-learn
```

프로젝트의 기술 스택, 코딩 컨벤션, 디렉토리 구조, 빌드 명령을 **자동 분석**하여
`.tdc/project-memory.md`에 저장합니다.

이후 `/tdc spec.md`를 실행하면 이 정보를 자동으로 활용하여 더 정확한 코드를 생성합니다.
세션 중 반복된 패턴을 재사용 스킬로 저장하려면 `/tdc-learn patterns extract`를 사용하세요.

### 5. 업데이트

```
/tdc-upgrade
```

tdc의 스킬, 에이전트, 훅을 최신 버전으로 업데이트합니다.
프로젝트별 데이터(세션, 플랜, 메모리)는 보존됩니다.
새 버전이 있으면 세션 시작 시 자동으로 알려줍니다.

### 6. 작업이 길어질 때 (세션 관리)

오랜 작업 중 "컨텍스트 사용량이 높습니다"라는 경고가 나오면:

```
/tdc-save              # 지금까지 한 것 저장
```

Claude Code를 다시 열고:

```
/tdc-resume            # 이전 작업 이어서 계속 (최신 세션 자동 선택)
/tdc-resume list       # 저장된 세션 목록
/tdc-resume <ID>       # 특정 세션 선택
```

---

## 명령어 모음

모든 명령어는 **Claude Code 입력창** 안에서 사용합니다.
(터미널에서 `claude`를 실행한 후 나오는 입력창)

### 메인 명령어 (보통 이것만 씁니다)

| 입력하는 것 | 모드 | 무슨 일이 벌어지는지 |
|------------|------|-------------------|
| `/tdc spec.md` | 일반 | 기획 → 개발 → 리뷰까지 **자동 진행** |
| `/tdc-deep spec.md` | Deep | 일반 모드 + **배너·요약·리뷰 강제 + 테스트/빌드 검증 반복** |
| `/tdc 로그인 기능 추가해줘` | 일반 | 스펙 파일 없이 텍스트로 지시 |
| `/tdc-deep 결제 시스템 구현해줘` | Deep | 텍스트 지시 + 끈질긴 검증 |

### 개별 명령어 (특정 단계만 따로 하고 싶을 때)

| 입력하는 것 | 언제 쓰는지 |
|------------|-----------|
| `/tdc-plan spec.md` | 기획만 미리 보고 싶을 때 (개발은 아직) |
| `/tdc-dev` | 기획은 끝났고 개발만 시작할 때 |
| `/tdc-debug <에러 내용>` | 이미 있는 코드에서 새 버그를 발견했을 때 |
| `/tdc-review` | 직접 작성한 코드를 리뷰받고 싶을 때 |
| `/tdc-learn` | 기존 프로젝트 자동 분석 → `.tdc/project-memory.md` |
| `/tdc-upgrade` | tdc를 최신 버전으로 업데이트 |
| `/tdc-version` | 설치된 tdc 버전 확인 |

### 세션 관리

| 입력하는 것 | 무슨 일이 벌어지는지 |
|------------|-------------------|
| `/tdc-save` | 현재 진행 상황을 파일로 저장 |
| `/tdc-resume` | 가장 최근 세션 이어서 작업 |
| `/tdc-resume list` | 저장된 세션 목록 보기 |
| `/tdc-resume <ID>` | 특정 세션 이어서 작업 |
| `/tdc-clean` | 7일 이상 된 세션 삭제 (`--days N`, `--all` 옵션) |

---

## 아키텍처

### 에이전트 팀 구성

```
사용자: /tdc spec.md  (이것만 입력)
              ↓
┌─── Master Agent (opus) ─── 팀 리더, 전체 자동 진행 ────────────┐
│                                                                 │
│   [Phase 1] Planner (sonnet) ── 스펙 → 태스크 분해              │
│       ↓ 자동                                                    │
│   [Phase 2] Developer (sonnet) ── 태스크별 코드 구현             │
│       ↓ 에러 발생?                                              │
│       └→ Debugger (sonnet) ── 자동 진단 & 수정 → Developer 계속  │
│       ↓ 자동                                                    │
│   [Phase 3] Reviewer (haiku) ── 자동 코드 리뷰                  │
│       ↓ 이슈 발견?                                              │
│       ├→ code-level → Developer 수정                            │
│       ├→ design-level → Planner 재기획 → Developer 재구현       │
│       └→ critical → Planner 재기획 + Developer 긴급 수정        │
│       ↓ 자동                                                    │
│   [Phase 4] 최종 결과 보고 → 사용자에게 전달                     │
│                                                                 │
│   * Architect (opus) ── 설계 판단이 필요할 때만 자동 호출        │
└─────────────────────────────────────────────────────────────────┘

에이전트 간 통신 (Live Dashboard로 실시간 표시):
  Master가 중앙 허브 역할. 에이전트끼리 직접 통신하지 않고,
  Master를 통해 필요한 컨텍스트만 전달받습니다.
  모든 통신은 사용자에게 실시간으로 보여지며, 로그로 기록됩니다.

  Planner 결과 → (Master가 요약) → Developer에게 전달
  Developer 에러 → (Master가 감지) → Debugger 자동 호출
  Reviewer 이슈 → (Master가 심각도 판단) →
    code-level: Developer에게 수정 지시
    design-level: Planner에게 재기획 요청 → Developer 재구현
```

### 병렬 개발 (git worktree)

독립적인 태스크가 여러 개 있으면 **git worktree로 병렬 실행**합니다:

```
[TDC] Phase 2 — Parallel execution (3 independent tasks)
  [TDC] developer-1 working on Task 1: "DB 모델" (worktree)
  [TDC] developer-2 working on Task 3: "프론트엔드" (worktree)

[TDC] developer-1 completed Task 1 (15s)
[TDC] developer-2 completed Task 3 (22s)
[TDC] Worktrees merged successfully
[TDC] Continuing with dependent tasks...
```

Planner가 태스크 간 의존성을 분석하여 독립 태스크를 식별하고,
각 Developer가 별도 worktree에서 동시에 작업합니다.
완료 후 자동 merge되며, 충돌 시 Debugger가 해결합니다.

### 실시간 진행 상황 (3중 가시성)

`/tdc spec.md`를 실행하면 에이전트 활동을 **3가지 방법**으로 실시간 확인할 수 있습니다:

#### 1. Status Line (터미널 하단 상시 표시)

터미널 맨 아래에 현재 상태가 항상 보입니다:

```
[TDC] Phase 2/4 — IMPLEMENTATION | developer[sonnet] working | ~14.0k tokens | 45 tools | rtk:99.7%
```

에이전트명, **사용 모델**, 누적 토큰, rtk 상태가 실시간 업데이트됩니다.

#### 2. Console Messages (에이전트 시작/완료 알림 + 모델명)

에이전트가 시작하거나 완료될 때 **모델명과 함께** 자동으로 메시지가 표시됩니다:

```
[TDC] planner agent started [sonnet] (14:03:01)
[TDC] planner [sonnet] completed (21s) — Token Usage:
       planner    ██████████ ~2.4k (100%)
       ──────────── total: ~2.4k
[TDC] developer agent started [sonnet] (14:03:23) — cumulative: ~2.4k tokens
[TDC] developer [sonnet] completed (22s) — Token Usage:
       planner    ██░░░░░░░░ ~2.4k (17%)
       developer  ██████████ ~8.8k (63%)
       ──────────── total: ~11.2k
```

#### 3. Dashboard Banners (Phase 전환 시 상세 로그)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 1 — PLANNING                        [1/4]
  Planner Agent가 스펙을 분석하고 있습니다...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  14:03:01 [Master → Planner] 스펙 파일 전달
  14:03:22 [Planner → Master] 5개 태스크 분해 완료 (21s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 2 — IMPLEMENTATION                  [2/4]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  14:03:23 [Master → Developer] 태스크 1/5: "DB 모델 구현"
  14:03:45 [Developer → Master] 완료 (22s)
  14:03:46 [Master → Developer] 태스크 2/5: "API 엔드포인트"
  14:04:10 [Developer → Master] 에러 발생!
  14:04:10 [Master → Debugger] 자동 진단 요청
  14:04:25 [Debugger → Master] 수정 완료 (15s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  PHASE 4 — COMPLETE                        [4/4]
  모든 작업이 완료되었습니다!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

에이전트 간 모든 상호작용 기록은 `.tdc/context/agent-log.md`에 저장됩니다.

### 왜 에이전트를 나누나요?

| Agent | AI 모델 | 비용 | 하는 일 |
|-------|---------|------|--------|
| **Master** | opus (고성능) | 높음 | 전체 지휘. 누구한테 뭘 시킬지 판단 |
| **Planner** | sonnet (범용) | 중간 | "뭘 만들어야 하는지" 정리 |
| **Developer** | sonnet (범용) | 중간 | 실제 코드 작성 |
| **Debugger** | sonnet (범용) | 중간 | 버그 찾아서 고침 |
| **Reviewer** | haiku (경량) | 낮음 | 코드 검토 (빠르고 저렴) |
| **Security Reviewer** | haiku (경량) | 낮음 | OWASP 보안 취약점 검토 |
| **Test Engineer** | sonnet (범용) | 중간 | 테스트 커버리지 분석 + 테스트 자동 생성 |
| **Architect** | opus (고성능) | 높음 | 큰 그림 설계 (필요할 때만) |

간단한 리뷰에 비싼 opus를 쓸 필요가 없습니다.
모델을 역할에 맞게 배치해서 **비용을 30-50% 절감**합니다.

### 실시간 토큰 대시보드

에이전트가 완료될 때마다 **누적 토큰 게이지가 실시간으로 표시**됩니다:

```
[TDC] developer [sonnet] completed (22s) — Token Usage:
       planner(sonnet)    ██░░░░░░░░ ~2.4k (17%)
       developer(sonnet)  ████████░░ ~8.8k (63%)
       debugger(sonnet)   ██░░░░░░░░ ~2.8k (20%)
       ──────────────────── total: ~14.0k
```

Phase 4에서는 전체 요약 + rtk 절감 추정 + 비용 추정이 포함됩니다.

### 토큰 절감 전략

| 방법 | 설명 | 절감 효과 |
|------|------|----------|
| **모델 티어링** | 역할별로 haiku/sonnet/opus 배치 | 30-50% |
| **rtk** | 명령어 출력을 자동 압축 ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) | 60-90% |
| **Smart Read** | 대용량 파일 읽기 감지 + 타겟 읽기 강제 (Grep 선행, offset/limit 필수) | 40-60% |
| **Diff-Only Review** | Reviewer에게 전체 파일 대신 git diff만 전달 | 50-70% |
| **Conversation Compaction** | 60 tool calls에서 중간 결과 자동 요약 | 컨텍스트 확장 |
| **Response Budget** | 누적 토큰 모니터링 + 초과 시 간결화 경고 | 과다 출력 방지 |
| **최소 컨텍스트 전달** | 에이전트에 필요한 정보만 전달 | 불필요한 토큰 제거 |
| **세션 저장/재개** | 처음부터 다시 설명할 필요 없음 | 재작업 방지 |
| **Preemptive Compaction** | 압축 전에 상태 자동 저장 → 복구 | 컨텍스트 손실 방지 |
| **Rate Limit Guard** | API 제한 자동 감지 + 대기 안내 | 세션 중단 방지 |
| **Project Memory** | 프로젝트 지식을 세션 간 유지 | 반복 설명 제거 |

### 세션 관리 (컨텍스트 오버플로)

AI와 오래 대화하면 "컨텍스트"가 가득 차서 이전 내용을 잊게 됩니다.
tdc는 이걸 자동으로 관리합니다:

```
대화 중...
  ↓ (도구 호출 80회) → "컨텍스트가 높습니다" 경고
  ↓ (도구 호출 120회) → 자동으로 진행 상황 저장 (완료/미완료 태스크, 변경 파일 포함)
  ↓
/tdc-resume          →  이전 맥락을 불러와서 이어서 작업
```

---

## 디렉토리 구조

```
~/.tdc/                             # 글로벌 설치 (install.sh로 생성)
  hooks/                            # 자동화 스크립트
  state/sessions/                   # 세션 데이터
  state/context/                    # 컨텍스트 모니터링

~/.claude/                          # Claude Code가 읽는 경로 (install.sh로 생성)
  skills/                           # /tdc 슬래시 커맨드 + 스킬팩
    tdc/SKILL.md                    # 메인 진입점
    tdc-plan/ tdc-dev/ ...          # 개별 명령어
    tdc-learn/SKILL.md              # 스킬 학습
    tdc-stack-python-django/        # 스킬팩 (선택 설치)
    tdc-stack-ts-nextjs/
    tdc-stack-go/ tdc-stack-rust/
    tdc-stack-java/ tdc-stack-react/
    tdc-stack-flutter/ tdc-stack-kotlin/
  agents/                           # 에이전트 정의 (8개)
    master.md, planner.md, developer.md, debugger.md,
    reviewer.md, security-reviewer.md, test-engineer.md, architect.md

your-project/                       # 사용자의 프로젝트 폴더
├── .tdc/                           # /tdc 첫 실행 시 자동 생성
│   ├── sessions/                   # 저장된 세션
│   ├── context/                    # 컨텍스트 모니터링 + 토큰 추적
│   ├── plans/                      # 생성된 플랜
│   ├── learned-skills/             # 학습된 스킬 패턴
│   └── project-memory.md           # 프로젝트 지식 (세션 간 유지)
├── spec.md                         # 사용자가 작성하는 스펙
└── (개발 코드들...)
```

---

## FAQ

**Q: Claude Code가 뭔가요?**
A: Anthropic이 만든 AI 코딩 도구입니다. 터미널에서 `claude`를 치면 실행됩니다.
자세한 내용은 [claude.ai/code](https://claude.ai/code)를 참고하세요.

**Q: 유료인가요?**
A: Claude Code는 Anthropic API 사용량에 따라 과금됩니다.
tdc 자체는 무료이며, 모델 티어링과 rtk로 비용을 최소화합니다.

**Q: spec.md는 꼭 써야 하나요?**
A: 아닙니다. `/tdc 로그인 기능 만들어줘`처럼 직접 타이핑해도 됩니다.
하지만 복잡한 프로젝트일수록 스펙 파일을 쓰는 게 결과가 좋습니다.

**Q: 어떤 언어/프레임워크를 지원하나요?**
A: 제한 없습니다. Python, JavaScript, TypeScript, Go, Rust, Java, Swift, Kotlin 등
Claude가 지원하는 모든 언어로 개발할 수 있습니다.

**Q: 기존 프로젝트에도 쓸 수 있나요?**
A: 네. 기존 프로젝트 폴더에서 `claude`를 실행하고 `/tdc spec.md`를 입력하면 됩니다.

---

## 삭제 (Uninstall)

```bash
# 방법 A: 클론한 폴더에서 (권장)
bash uninstall.sh

# 방법 B: 원격 스크립트 다운로드 후 실행
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/uninstall.sh -o /tmp/tdc-uninstall.sh && bash /tmp/tdc-uninstall.sh
```

> **안전 장치:** 삭제 시 반드시 `y`를 입력하고 Enter를 눌러야 진행됩니다.

스킬, 에이전트, 스킬팩, 글로벌 파일(`~/.tdc/`), settings.json 훅 설정까지 전부 자동 정리됩니다.
rtk(토큰 절감 도구)도 삭제할지 물어봅니다.

---

## 트러블슈팅

**`/tdc` 입력 시 "Unknown skill" 에러**
- `~/.claude/skills/tdc/SKILL.md` 파일이 있는지 확인
- 없으면: `curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash`로 재설치

**Settings Error (Invalid key)**
- `~/.claude/settings.json`에 잘못된 hook 키가 있을 수 있습니다
- 재설치하면 자동으로 수정됩니다

**rtk가 동작하지 않음**
- `rtk --version` 확인
- 안 되면: `brew install rtk` 또는 재설치

---

## Requirements

- [Claude Code](https://claude.ai/code) v2.0+
- macOS or Linux
- Node.js 18+
- bash 4+
- python3
- git
- jq (rtk 토큰 압축에 필요 — install.sh가 자동 설치 시도)

## Maintenance

에이전트 추가, 스킬 변경, 아키텍처 수정은 [MAINTENANCE.md](MAINTENANCE.md)를 참고하세요.

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) — Claude Code 멀티 에이전트 프레임워크
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — Claude Code 올인원 에이전트 하니스
- [rtk](https://github.com/rtk-ai/rtk) — LLM 토큰 절감 CLI 프록시

## License

MIT
