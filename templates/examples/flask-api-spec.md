# Flask User API

## 목적
유저 관리용 REST API 서버. 회원가입, 로그인, 유저 CRUD를 제공한다.

## 기술 스택
- 언어: Python 3.11+
- 프레임워크: Flask
- DB: SQLite (개발), PostgreSQL (운영)
- ORM: Flask-SQLAlchemy
- 인증: JWT (Flask-JWT-Extended)
- 검증: marshmallow

## 기능 목록
- [ ] 회원가입 (이메일 + 비밀번호)
- [ ] 로그인 (JWT 토큰 발급)
- [ ] 유저 조회 (단건 / 목록)
- [ ] 유저 정보 수정
- [ ] 유저 삭제
- [ ] 헬스체크

## API 엔드포인트
| Method | Path | Description | Auth |
|--------|------|-------------|------|
| GET | /health | 헬스체크 | X |
| POST | /auth/register | 회원가입 | X |
| POST | /auth/login | 로그인, JWT 발급 | X |
| GET | /users | 유저 목록 조회 | O |
| GET | /users/:id | 유저 단건 조회 | O |
| PUT | /users/:id | 유저 정보 수정 | O |
| DELETE | /users/:id | 유저 삭제 | O |

## 기타 요구사항
- 비밀번호는 bcrypt로 해싱
- 에러 응답은 `{"error": "message", "code": 400}` 형태로 통일
- 테스트: pytest 기반, 커버리지 80%+
- 환경변수로 설정 분리 (SECRET_KEY, DATABASE_URL)
