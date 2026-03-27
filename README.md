# TechDog Claude (tdc)

> Claude Code를 위한 멀티 에이전트 개발 오케스트레이션 시스템

**만들고 싶은 것을 문서로 적고, `/tdc spec.md` 한 줄이면 AI 에이전트 팀이 기획부터 개발까지 해줍니다.**

---

## 이게 뭔가요?

[Claude Code](https://claude.ai/code)는 터미널에서 AI와 대화하며 코드를 작성하는 도구입니다.

TechDog Claude(tdc)는 이 Claude Code 위에 **6명의 전문 AI 에이전트**를 배치하여,
혼자 하는 코딩을 **팀 개발**처럼 바꿔줍니다.

```
평소:  나 ↔ Claude (1:1 대화)

tdc:   나 → Master Agent → Planner    (기획)
                         → Developer  (개발)
                         → Debugger   (디버깅)
                         → Reviewer   (리뷰)
                         → Architect  (설계)
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
- `tdc` 명령어가 터미널에 등록됩니다
- Claude Code에 `/tdc` 슬래시 커맨드가 추가됩니다
- [rtk](https://github.com/rtk-ai/rtk) (토큰 60-90% 절감 도구)가 함께 설치됩니다
- Claude Code Team 모드가 활성화됩니다

---

## 사용법 (처음부터 따라하기)

### 0. Claude Code란?

Claude Code는 **터미널(명령 프롬프트)**에서 실행하는 AI 코딩 도구입니다.

```bash
# 터미널을 열고 아무 폴더에서:
claude
```

이렇게 치면 Claude Code가 실행되고, AI와 대화할 수 있는 입력창이 나타납니다.
이 입력창 안에서 `/tdc` 같은 슬래시(/) 명령어를 사용합니다.

```
╭─────────────────────────────────────────╮
│ Claude Code                             │
│                                         │
│ > 여기에 타이핑합니다                      │
│ > /tdc spec.md    ← 이렇게 입력          │
╰─────────────────────────────────────────╯
```

### 1. 프로젝트 시작

먼저 터미널에서 프로젝트 폴더를 만들고 초기화합니다:

```bash
mkdir my-project
cd my-project
tdc init         # .tdc/ 폴더가 생깁니다
```

### 2. 스펙 파일 작성

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

> 한국어/영어 모두 OK. 완벽하지 않아도 됩니다. AI가 부족한 부분은 물어봅니다.

### 3. 실행

터미널에서 Claude Code를 열고 `/tdc` 명령어를 입력합니다:

```bash
claude               # Claude Code 실행
```

Claude Code 입력창에서:

```
/tdc spec.md
```

그러면 **Master Agent가 전부 자동으로 처리합니다:**

```
/tdc spec.md   ← 이것만 입력하면 끝!
    ↓
[자동] Planner Agent가 스펙을 분석하고 태스크를 분해합니다
    ↓
[자동] Developer Agent가 태스크별로 코드를 작성합니다
    ↓ (에러가 나면?)
[자동] Debugger Agent가 알아서 원인을 찾고 고칩니다  ← 사용자 개입 불필요
    ↓
[자동] Reviewer Agent가 완성된 코드를 검토합니다
    ↓ (심각한 문제가 있으면?)
[자동] Developer Agent가 다시 수정합니다  ← 사용자 개입 불필요
    ↓
최종 결과를 사용자에게 보고합니다
```

> **핵심:** 에이전트들끼리 Master Agent를 통해 자동으로 소통합니다.
> 개발 중 에러가 나면 Debugger가 자동 호출되고, 리뷰에서 문제가 발견되면
> Developer가 자동으로 수정합니다. **사용자는 처음에 한 번만 입력하면 됩니다.**

### 4. 개별 명령어 (선택사항)

자동 파이프라인이 아니라, 특정 단계만 따로 실행하고 싶을 때 사용합니다.
**평소에는 쓸 일이 없습니다** — `/tdc spec.md` 하나면 충분합니다.

```
/tdc-plan spec.md     ← 기획만 하고 멈추고 싶을 때
/tdc-dev              ← 기획은 이미 했고 개발만 시작하고 싶을 때
/tdc-debug <에러>     ← 이미 만들어진 코드에서 새 에러를 발견했을 때
/tdc-review           ← 직접 작성한 코드를 리뷰받고 싶을 때
```

### 5. 작업이 길어질 때 (세션 관리)

오랜 작업 중 "컨텍스트 사용량이 높습니다"라는 경고가 나오면:

```
/tdc-session save      # 지금까지 한 것 저장
```

Claude Code를 다시 열고:

```
/tdc-session resume    # 이전 작업 이어서 계속
```

---

## 명령어 모음

모든 명령어는 **Claude Code 입력창** 안에서 사용합니다.
(터미널에서 `claude`를 실행한 후 나오는 입력창)

### 메인 명령어 (보통 이것만 씁니다)

| 입력하는 것 | 무슨 일이 벌어지는지 |
|------------|-------------------|
| `/tdc spec.md` | 스펙 파일을 읽고 **기획 → 개발 → 디버깅 → 리뷰까지 전부 자동** 진행 |
| `/tdc 로그인 기능 추가해줘` | 텍스트로 간단히 지시 (스펙 파일 없이도 전체 자동 진행) |

### 개별 명령어 (특정 단계만 따로 하고 싶을 때)

| 입력하는 것 | 언제 쓰는지 |
|------------|-----------|
| `/tdc-plan spec.md` | 기획만 미리 보고 싶을 때 (개발은 아직) |
| `/tdc-dev` | 기획은 끝났고 개발만 시작할 때 |
| `/tdc-debug <에러 내용>` | 이미 있는 코드에서 새 버그를 발견했을 때 |
| `/tdc-review` | 직접 작성한 코드를 리뷰받고 싶을 때 |

### 세션 관리

| 입력하는 것 | 무슨 일이 벌어지는지 |
|------------|-------------------|
| `/tdc-session save` | 현재 진행 상황을 파일로 저장 |
| `/tdc-session resume` | 저장한 세션에서 이어서 작업 |
| `/tdc-session list` | 저장된 세션 목록 보기 |
| `/tdc-session clean` | 7일 이상 된 세션 삭제 |

### 터미널 명령어 (Claude Code 밖에서)

Claude Code를 실행하지 않고 터미널에서 직접 쓸 수도 있습니다:

```bash
tdc init              # 프로젝트 초기화
tdc spec.md           # Claude Code를 열면서 스펙 파일 전달
tdc status            # 현재 세션 상태 확인
tdc session list      # 저장된 세션 목록
tdc session resume    # 이전 세션 재개
tdc --help            # 도움말
```

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
│       ↓ 심각한 이슈?                                            │
│       └→ Developer (sonnet) ── 자동 수정                        │
│       ↓ 자동                                                    │
│   [Phase 4] 최종 결과 보고 → 사용자에게 전달                     │
│                                                                 │
│   * Architect (opus) ── 설계 판단이 필요할 때만 자동 호출        │
└─────────────────────────────────────────────────────────────────┘

에이전트 간 통신:
  Master가 중앙 허브 역할. 에이전트끼리 직접 통신하지 않고,
  Master를 통해 필요한 컨텍스트만 전달받습니다.

  Planner 결과 → (Master가 요약) → Developer에게 전달
  Developer 에러 → (Master가 감지) → Debugger 자동 호출
  Reviewer 이슈 → (Master가 판단) → Developer에게 수정 지시
```

### 왜 에이전트를 나누나요?

| Agent | AI 모델 | 비용 | 하는 일 |
|-------|---------|------|--------|
| **Master** | opus (고성능) | 높음 | 전체 지휘. 누구한테 뭘 시킬지 판단 |
| **Planner** | sonnet (범용) | 중간 | "뭘 만들어야 하는지" 정리 |
| **Developer** | sonnet (범용) | 중간 | 실제 코드 작성 |
| **Debugger** | sonnet (범용) | 중간 | 버그 찾아서 고침 |
| **Reviewer** | haiku (경량) | 낮음 | 코드 검토 (빠르고 저렴) |
| **Architect** | opus (고성능) | 높음 | 큰 그림 설계 (필요할 때만) |

간단한 리뷰에 비싼 opus를 쓸 필요가 없습니다.
모델을 역할에 맞게 배치해서 **비용을 30-50% 절감**합니다.

### 토큰 절감 전략

| 방법 | 설명 | 절감 효과 |
|------|------|----------|
| **모델 티어링** | 역할별로 haiku/sonnet/opus 배치 | 30-50% |
| **rtk** | 명령어 출력을 자동 압축 ([rtk-ai/rtk](https://github.com/rtk-ai/rtk)) | 60-90% |
| **컨텍스트 압축** | 오래된 대화 자동 요약 후 새 세션 | 중복 제거 |
| **최소 컨텍스트 전달** | 에이전트에 필요한 정보만 전달 | 불필요한 토큰 제거 |
| **세션 저장/재개** | 처음부터 다시 설명할 필요 없음 | 재작업 방지 |

### 세션 관리 (컨텍스트 오버플로)

AI와 오래 대화하면 "컨텍스트"가 가득 차서 이전 내용을 잊게 됩니다.
tdc는 이걸 자동으로 관리합니다:

```
대화 중...
  ↓ (도구 호출 80회) → "컨텍스트가 높습니다" 경고
  ↓ (도구 호출 120회) → 자동으로 진행 상황 저장
  ↓
/tdc-session resume  →  이전 맥락을 불러와서 이어서 작업
```

---

## 디렉토리 구조

```
~/.tdc/                         # 글로벌 설치 (한 번 설치하면 어디서든 사용)
  agents/                       # 에이전트 정의 파일들
  skills/                       # 슬래시 커맨드 정의 파일들
  hooks/                        # 자동화 스크립트
  scripts/tdc                   # tdc CLI

your-project/                   # 사용자의 프로젝트 폴더
├── .tdc/                       # tdc init 시 생성 (gitignore 권장)
│   ├── sessions/               # 저장된 세션
│   ├── context/                # 컨텍스트 모니터링
│   └── plans/                  # 생성된 플랜
├── spec.md                     # 사용자가 작성하는 스펙
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
A: 네. 기존 프로젝트 폴더에서 `tdc init` 후 바로 사용 가능합니다.

---

## Requirements

- [Claude Code](https://claude.ai/code) v2.0+
- macOS or Linux
- Node.js 18+
- bash 4+
- python3
- git

## Maintenance

에이전트 추가, 스킬 변경, 아키텍처 수정은 [MAINTENANCE.md](MAINTENANCE.md)를 참고하세요.

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode) — Claude Code 멀티 에이전트 프레임워크
- [rtk](https://github.com/rtk-ai/rtk) — LLM 토큰 절감 CLI 프록시

## License

MIT
