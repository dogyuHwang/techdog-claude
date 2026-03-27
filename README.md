# TechDog Claude (tdc)

> Claude Code를 위한 멀티 에이전트 개발 오케스트레이션 시스템

**스펙 파일 하나만 쓰면, AI 에이전트 팀이 기획부터 개발까지 진행합니다.**

```
spec.md 작성  →  /tdc spec.md  →  기획 → 개발 → 리뷰 → 완성
```

---

## 처음 사용하시나요?

### 1단계: 설치

```bash
# 방법 A: 원격 설치
curl -sSL https://raw.githubusercontent.com/dogyuHwang/techdog-claude/main/install.sh | bash

# 방법 B: 클론 후 설치
git clone https://github.com/dogyuHwang/techdog-claude.git
cd techdog-claude && bash install.sh
```

> **필수 조건:** [Claude Code CLI](https://claude.ai/code)가 설치되어 있어야 합니다.
> ```bash
> npm install -g @anthropic-ai/claude-code
> ```

### 2단계: 프로젝트 초기화

만들고 싶은 프로젝트 폴더에서:

```bash
mkdir my-project && cd my-project
tdc init
```

이렇게 하면 두 가지가 생깁니다:
- `.tdc/` — tdc가 사용하는 상태 폴더
- `spec-template.md` — **여기에 만들고 싶은 것을 작성합니다**

### 3단계: 스펙 작성

`spec-template.md`를 `spec.md`로 복사하고 내용을 채웁니다:

```markdown
# Flask User API

## 목적
유저 관리용 REST API 서버

## 기술 스택
- 언어: Python 3.11+
- 프레임워크: Flask
- DB: SQLite
- 인증: JWT

## 기능 목록
- [ ] 회원가입
- [ ] 로그인 (JWT 발급)
- [ ] 유저 CRUD
- [ ] 헬스체크

## API 엔드포인트
| Method | Path           | Description |
|--------|----------------|-------------|
| POST   | /auth/register | 회원가입     |
| POST   | /auth/login    | 로그인       |
| GET    | /users         | 유저 목록    |
| GET    | /users/:id     | 유저 조회    |
| PUT    | /users/:id     | 유저 수정    |
| DELETE | /users/:id     | 유저 삭제    |
| GET    | /health        | 헬스체크     |

## 기타 요구사항
- 비밀번호 bcrypt 해싱
- 에러 응답 JSON 통일
- pytest 테스트
```

> **팁:** 스펙은 자유 형식입니다. 위 형식을 꼭 따를 필요 없이, 만들고 싶은 것을 자유롭게 적으면 됩니다.

### 4단계: 실행!

Claude Code를 열고:

```
/tdc spec.md
```

또는 터미널에서:

```bash
tdc spec.md
```

그러면 이런 일이 일어납니다:

```
📄 spec.md 읽기
    ↓
🧠 Planner Agent — 스펙을 분석하고 태스크 목록 생성
    ↓
📋 플랜을 보여주고 "이대로 진행할까요?" 확인
    ↓  승인
💻 Developer Agent — 태스크별로 코드 구현
    ↓
🔍 Reviewer Agent — 자동 코드 리뷰
    ↓
✅ 완성!
```

---

## 전체 워크플로우 예제: Flask REST API 서버

### 1. 기획

```
/tdc spec.md
```

Planner Agent가 스펙을 읽고 태스크를 분해합니다:

```markdown
## Plan: Flask User API

### 태스크
1. [ ] 프로젝트 초기화 (requirements.txt, 디렉토리 구조) — low
2. [ ] DB 모델 정의 (User, SQLAlchemy) — low
3. [ ] 인증 엔드포인트 (register, login) — mid
4. [ ] CRUD 엔드포인트 (/users) — mid
5. [ ] 에러 핸들링 & 입력 검증 — mid
6. [ ] 테스트 작성 (pytest) — mid

### 검증 기준
- [ ] GET /health → 200
- [ ] 회원가입 → 로그인 → JWT 발급 성공
- [ ] CRUD 전체 동작
- [ ] 잘못된 입력 → 에러 응답
```

> "이 플랜대로 진행할까요?" → **Y**

### 2. 개발

승인하면 Developer Agent가 순서대로 구현합니다:

```
✅ Task 1: requirements.txt, app.py, models.py 생성
✅ Task 2: User 모델 정의
✅ Task 3: /auth/register, /auth/login 구현
✅ Task 4: /users CRUD 구현
✅ Task 5: 에러 핸들링 추가
✅ Task 6: tests/test_app.py 작성
```

### 3. 문제 발생 시

서버 실행 중 에러가 나면:

```
/tdc-debug flask run 하면 "OperationalError: no such table: user" 에러
```

Debugger Agent가 원인을 찾고 수정합니다:

```
Root Cause: db.create_all()이 app context 밖에서 호출됨
Fix: app.py:15에 with app.app_context(): db.create_all() 추가
```

### 4. 코드 리뷰

```
/tdc-review
```

Reviewer Agent가 빠르게 체크합니다:

```
Review: APPROVE
Warnings:
- app.py:8 — SECRET_KEY 하드코딩 → 환경변수로 분리
- models.py:12 — email에 unique 제약 없음
```

### 5. 컨텍스트가 찰 때

작업이 길어지면 자동으로 알려줍니다:

```
[TDC] WARNING: 컨텍스트 사용량이 높습니다 (80 tool calls)
```

```
/tdc-session save     ← 진행 상황 저장
```

새 Claude Code 세션을 열고:

```
/tdc-session resume   ← 이전 작업 이어서 진행
```

---

## 명령어 정리

### Claude Code 안에서 (슬래시 커맨드)

| 명령어 | 설명 | 예시 |
|--------|------|------|
| `/tdc <file.md>` | 스펙 파일로 전체 워크플로우 시작 | `/tdc spec.md` |
| `/tdc <설명>` | 텍스트로 간단히 지시 | `/tdc 로그인 기능 추가해줘` |
| `/tdc-plan <file\|설명>` | 기획만 진행 | `/tdc-plan api-spec.md` |
| `/tdc-dev <file\|설명>` | 개발만 진행 | `/tdc-dev` (최신 플랜 사용) |
| `/tdc-debug <설명>` | 버그 진단 & 수정 | `/tdc-debug "에러 메시지"` |
| `/tdc-review [files]` | 코드 리뷰 | `/tdc-review` |
| `/tdc-session <cmd>` | 세션 관리 | `/tdc-session resume` |

### 터미널에서

```bash
tdc init                  # 프로젝트 초기화 + 스펙 템플릿 생성
tdc template my-spec.md   # 빈 스펙 템플릿 생성
tdc spec.md               # 스펙 파일로 시작
tdc plan spec.md          # 기획만
tdc dev                   # 개발 (최신 플랜 사용)
tdc debug "에러 메시지"    # 디버깅
tdc review                # 코드 리뷰
tdc session list           # 저장된 세션 목록
tdc session resume         # 마지막 세션 재개
tdc status                 # 컨텍스트 상태 확인
```

---

## Architecture

```
사용자가 spec.md 작성
        ↓
    /tdc spec.md
        ↓
┌─── Master Agent (opus) ── 오케스트레이션 ───┐
│       ↓                                      │
│   Planner (sonnet) ─── 태스크 분해           │
│       ↓                                      │
│   Developer (sonnet) ── 코드 구현            │
│       ↓ (에러 시)                            │
│   Debugger (sonnet) ─── 진단 & 수정          │
│       ↓                                      │
│   Reviewer (haiku) ──── 코드 리뷰            │
│       ↓ (아키텍처 이슈 시)                    │
│   Architect (opus) ──── 설계 판단            │
└──────────────────────────────────────────────┘
```

### 에이전트 역할

| Agent | Model | 비용 | 역할 |
|-------|-------|------|------|
| **Master** | opus | 높음 | 팀 리더. 에이전트 위임, 컨텍스트 관리, 세션 전환 |
| **Planner** | sonnet | 중간 | 요구사항 분석, 태스크 분해, PRD 생성 |
| **Developer** | sonnet | 중간 | 코드 구현, 기능 개발, 테스트 작성 |
| **Debugger** | sonnet | 중간 | 버그 진단, 근본 원인 분석, 수정 |
| **Reviewer** | haiku | 낮음 | 코드 리뷰, 보안 체크, 품질 검증 |
| **Architect** | opus | 높음 | 시스템 설계, 기술 스택 결정 (필요시만) |

### 토큰 최적화

비용을 30-50% 절감:

| 전략 | 설명 |
|------|------|
| **Model Tiering** | 간단한 작업은 haiku, 일반 작업은 sonnet, 복잡한 판단만 opus |
| **Context Compression** | 컨텍스트 차면 자동 요약 후 새 세션 |
| **Focused Delegation** | 에이전트에 최소 필요 컨텍스트만 전달 |
| **Session Persistence** | 저장 & 재개로 중복 처리 방지 |
| **Lazy Loading** | 필요한 에이전트만 활성화 |

---

## 디렉토리 구조

```
techdog-claude/                     # 이 레포지토리
├── .claude/
│   ├── agents/                     # 에이전트 정의
│   │   ├── master.md               # 팀 리더
│   │   ├── planner.md              # 기획자
│   │   ├── developer.md            # 개발자
│   │   ├── debugger.md             # 디버거
│   │   ├── reviewer.md             # 리뷰어
│   │   └── architect.md            # 아키텍트
│   ├── skills/                     # 슬래시 커맨드
│   │   ├── tdc.md                  # /tdc (메인)
│   │   ├── tdc-plan.md             # /tdc-plan
│   │   ├── tdc-dev.md              # /tdc-dev
│   │   ├── tdc-debug.md            # /tdc-debug
│   │   ├── tdc-review.md           # /tdc-review
│   │   └── tdc-session.md          # /tdc-session
│   └── hooks/                      # 자동화 훅
├── scripts/tdc                     # CLI
├── templates/
│   ├── spec-template.md            # 빈 스펙 템플릿
│   └── examples/
│       └── flask-api-spec.md       # Flask API 예제 스펙
├── install.sh                      # 설치 스크립트
├── CLAUDE.md                       # Claude Code 프로젝트 지침
└── MAINTENANCE.md                  # 유지보수 가이드

~/.tdc/                             # 글로벌 설치 (설치 시 생성)

your-project/                       # 사용자 프로젝트
├── .tdc/                           # tdc init 시 생성
│   ├── sessions/                   # 세션 저장
│   ├── context/                    # 컨텍스트 모니터링
│   └── plans/                      # 생성된 플랜
└── spec.md                         # 사용자가 작성하는 스펙
```

---

## Requirements

- [Claude Code CLI](https://claude.ai/code) v2.0+
- macOS or Linux
- bash 4+
- python3
- git

## Maintenance

에이전트 추가, 스킬 변경, 아키텍처 수정은 [`MAINTENANCE.md`](MAINTENANCE.md)를 참고하세요.

## Inspired By

- [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode)

## License

MIT
