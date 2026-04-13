---
name: tdc-stack-python-django
description: "Python + Django stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "python", "django"]
---

# Python + Django Stack Rules

이 스킬팩은 tdc 에이전트가 Python/Django 프로젝트에서 작업할 때 자동으로 참고하는 규칙입니다.

## Project Detection
- `manage.py`, `settings.py`, `wsgi.py`, `asgi.py` 존재 시 자동 적용
- `requirements.txt`, `pyproject.toml`, `Pipfile` 확인

## Coding Conventions
- Python 3.10+ 문법 사용 (match/case, type hints, `|` union)
- PEP 8 준수. 함수명/변수명 `snake_case`, 클래스명 `PascalCase`
- Type hints 필수 (함수 시그니처, 반환값)
- f-string 사용 (`.format()` 금지)
- `pathlib.Path` 사용 (`os.path` 대신)

## Django Patterns
- **Views**: Class-Based Views (CBV) 기본. 단순 로직은 함수형 허용
- **Models**: `__str__` 필수. `Meta` 클래스에 `ordering` 정의. `verbose_name` 한글 가능
- **URLs**: `path()` 사용 (`re_path` 최소화). `app_name` 네임스페이스 필수
- **Forms/Serializers**: DRF 사용 시 `ModelSerializer` 기본. 커스텀 validation은 `validate_<field>`
- **Migrations**: 자동 생성 후 반드시 검토. 데이터 마이그레이션은 별도 파일
- **Settings**: `django-environ` 또는 `python-decouple`로 환경변수 관리. `SECRET_KEY` 하드코딩 금지

## Security Rules
- `ALLOWED_HOSTS` 반드시 설정
- CSRF protection 해제 금지 (`@csrf_exempt` 최소화)
- `DEBUG=True`를 프로덕션에 남기지 않기
- Raw SQL 사용 시 반드시 parameterized query
- `User` 모델 커스텀 시 `AbstractUser` 상속

## Testing
- `pytest-django` 권장. `TestCase` < `pytest` fixtures
- Factory 패턴: `factory_boy` 사용
- API 테스트: `APIClient` 사용. status code + response body 모두 검증
- Coverage 목표: 80%+

## Dependencies
- 가상환경 필수 (`venv`, `poetry`, `pipenv`)
- `requirements.txt` 또는 `pyproject.toml`에 버전 고정
- `pip install` 후 반드시 lock 파일 업데이트

## Common Commands
```bash
python manage.py runserver        # 개발 서버
python manage.py makemigrations   # 마이그레이션 생성
python manage.py migrate          # 마이그레이션 적용
python manage.py test             # 테스트 실행
pytest --cov                      # pytest + coverage
```
