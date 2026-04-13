---
name: tdc-stack-kotlin
description: "Kotlin stack conventions (Android/Ktor/Spring) for TDC agents"
user-invocable: false
tags: ["skill-pack", "kotlin", "android"]
---

# Kotlin Stack Rules

## Project Detection
- `build.gradle.kts` 내 `kotlin` 플러그인 또는 `*.kt` 파일 존재 시 자동 적용

## Coding Conventions
- Kotlin 1.9+. `camelCase` 함수/변수, `PascalCase` 클래스
- `val` 기본 (불변). `var` 최소화
- Data class: DTO/모델에 적극 사용
- Sealed class/interface: 상태 표현에 사용
- Extension functions 활용 (유틸 클래스 대신)
- `when` expression > `if-else` 체인
- Null safety: `?.`, `?:` 활용. `!!` 사용 금지

## Android Patterns (Jetpack Compose 기준)
- **UI**: Jetpack Compose 기본 (XML 레이아웃 레거시)
- **Architecture**: MVVM + Repository. `ViewModel` + `StateFlow`/`SharedFlow`
- **DI**: Hilt (Dagger) 권장
- **Navigation**: Navigation Compose
- **Coroutines**: `viewModelScope`, `lifecycleScope`. `GlobalScope` 금지
- **State**: `collectAsStateWithLifecycle()` for Flow 수집

## Ktor (서버) Patterns
- Routing: `routing { get("/api/...") { } }`
- Serialization: `kotlinx.serialization`
- DI: Koin 권장

## Testing
- `JUnit5` + `kotlin.test`
- `MockK` for 모킹 (Mockito-Kotlin 대안)
- Compose: `composeTestRule`
- `Turbine` for Flow 테스트

## Common Commands
```bash
./gradlew assembleDebug       # Android 빌드
./gradlew test                # 테스트
./gradlew ktlintCheck         # 린트
./gradlew run                 # Ktor 서버 실행
```
