---
name: tdc-stack-rust
description: "Rust stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "rust"]
---

# Rust Stack Rules

## Project Detection
- `Cargo.toml`, `Cargo.lock` 존재 시 자동 적용

## Coding Conventions
- Rust 2021 edition+. `snake_case` 함수/변수, `PascalCase` 타입/트레이트
- `clippy` 경고 0개 목표. `#[allow]`는 주석으로 사유 명시
- `unwrap()` 금지 (테스트 제외). `?` 연산자 + `anyhow`/`thiserror` 사용
- `clone()` 최소화. 소유권/참조 우선
- `pub` 최소화. 필요한 것만 공개

## Error Handling
- 라이브러리: `thiserror` 로 커스텀 에러 타입
- 바이너리: `anyhow::Result` 사용
- `expect("reason")` > `unwrap()` (테스트에서도)

## Project Structure
```
src/
  main.rs / lib.rs
  module/
    mod.rs
    submodule.rs
tests/              # 통합 테스트
benches/            # 벤치마크
```

## Common Patterns
- Builder 패턴 for 복잡한 구조체 생성
- `impl From<T>` for 타입 변환
- `Iterator` trait 적극 활용 (for loop 대신 `.map().filter().collect()`)
- `Arc<Mutex<T>>` for 공유 상태 (최소화)

## Testing
- `#[test]`, `#[cfg(test)]` 모듈
- `assert_eq!`, `assert!(matches!(...))`
- `cargo test -- --nocapture` for 출력 확인

## Common Commands
```bash
cargo run             # 실행
cargo build --release # 릴리스 빌드
cargo test            # 테스트
cargo clippy          # 린트
cargo fmt             # 포맷
```
