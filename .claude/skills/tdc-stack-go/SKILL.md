---
name: tdc-stack-go
description: "Go stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "go", "golang"]
---

# Go Stack Rules

## Project Detection
- `go.mod`, `go.sum` 존재 시 자동 적용

## Coding Conventions
- Go 1.21+ 문법. `slog` 로깅, generic 활용
- 변수명: `camelCase`. 패키지명: 단수 소문자 (`user`, not `users`/`utils`)
- Export: `PascalCase`. Unexported: `camelCase`
- 에러는 반환값으로 처리 (`if err != nil { return err }`). 패닉 금지 (init/main 제외)
- `interface`는 사용처에서 정의 (제공처가 아님)
- 빈 인터페이스 `any` 대신 제네릭 사용 가능하면 제네릭

## Project Structure
```
cmd/            # 실행 파일 (main.go)
internal/       # 비공개 패키지
pkg/            # 공개 패키지 (라이브러리)
api/            # API 정의 (proto, openapi)
```

## Error Handling
- `fmt.Errorf("context: %w", err)` — 항상 래핑
- 커스텀 에러: `errors.New()` 또는 sentinel errors
- `errors.Is()`, `errors.As()` 사용

## Testing
- `_test.go` 파일. Table-driven tests 패턴
- `testify` 또는 표준 라이브러리만 사용
- `httptest` 로 HTTP 핸들러 테스트
- `go test ./... -race -cover`

## Security
- `database/sql` parameterized queries 필수
- `html/template` 자동 이스케이프 활용
- `crypto/rand` 사용 (`math/rand` 보안 용도 금지)

## Common Commands
```bash
go run ./cmd/server       # 실행
go build ./...            # 빌드
go test ./... -race       # 테스트 (race detector)
go vet ./...              # 정적 분석
golangci-lint run         # 린트
```
