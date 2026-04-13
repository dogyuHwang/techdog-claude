---
name: tdc-stack-flutter
description: "Flutter + Dart stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "flutter", "dart"]
---

# Flutter + Dart Stack Rules

## Project Detection
- `pubspec.yaml` 내 `flutter` SDK 의존성 존재 시 자동 적용

## Coding Conventions
- Dart 3.0+ (records, patterns, sealed classes)
- `camelCase` 변수/함수, `PascalCase` 클래스, `_privatePrefix`
- `final` 기본. `var`은 재할당 필요 시만. `dynamic` 금지
- Null safety 준수. `!` 연산자 최소화 (null check 또는 `??` 사용)
- `const` 생성자 적극 활용 (위젯 리빌드 최적화)

## Flutter Patterns
- **State Management**: Riverpod 권장. Provider/Bloc 대안
- **Widget Structure**: 작은 위젯으로 분리 (build 메서드 100줄 미만)
- **Navigation**: GoRouter 권장
- **Theming**: `ThemeData` 중앙 관리. 하드코딩 색상/폰트 금지
- **Responsive**: `LayoutBuilder`, `MediaQuery` 활용

## Project Structure
```
lib/
  main.dart
  app/              # App-level config (router, theme)
  features/         # Feature-first 구조
    auth/
      data/         # Repository, Data source
      domain/       # Entity, UseCase
      presentation/ # Screen, Widget, Controller
  core/             # 공통 유틸, 상수
```

## Testing
- `flutter_test` 유닛 테스트 + 위젯 테스트
- `integration_test/` 통합 테스트
- `mockito` 또는 `mocktail` for 모킹
- Golden tests for UI 스냅샷

## Common Commands
```bash
flutter run                    # 실행
flutter build apk/ios          # 빌드
flutter test                   # 테스트
flutter analyze                # 정적 분석
dart fix --apply               # 자동 수정
```
