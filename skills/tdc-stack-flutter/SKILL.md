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

## Testing (TDD 패턴)

### TDD 사이클
1. **RED**: 실패 테스트 먼저 작성 → `flutter test` 실행 → 반드시 실패 확인
2. **GREEN**: 최소 구현으로 통과 → `flutter test` 재실행 → 전부 통과 확인
3. **REFACTOR**: 코드 정리 → `flutter test` 재실행 → 여전히 통과 확인

### 유닛 테스트 (mocktail 패턴)
```dart
// test/features/auth/domain/use_case/login_use_case_test.dart
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase sut;
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
    sut = LoginUseCase(mockRepo);
  });

  test('login_with_valid_credentials — returns JWT token', () async {
    when(() => mockRepo.login(any(), any()))
        .thenAnswer((_) async => const Right('jwt-token'));
    final result = await sut(email: 'a@b.com', password: 'pass');
    expect(result, const Right('jwt-token'));
  });
}
```

### Riverpod 상태 TDD (ProviderContainer)
```dart
test('counter increments', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  expect(container.read(counterProvider), 0);
  container.read(counterProvider.notifier).increment();
  expect(container.read(counterProvider), 1);
});
```

### 위젯 테스트 (Widget Test)
```dart
testWidgets('LoginScreen shows error on empty submit', (tester) async {
  await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: LoginScreen())));
  await tester.tap(find.byKey(const Key('login_button')));
  await tester.pump();
  expect(find.text('이메일을 입력하세요'), findsOneWidget);
});
```

### Golden Test (UI 스냅샷)
```dart
testWidgets('ProfileCard golden test', (tester) async {
  await tester.pumpWidget(MaterialApp(home: ProfileCard(user: fakeUser)));
  await expectLater(find.byType(ProfileCard), matchesGoldenFile('goldens/profile_card.png'));
});
// 골든 업데이트: flutter test --update-goldens
```

### GoRouter 테스트
```dart
test('unauthenticated redirects to /login', () {
  final router = AppRouter(authNotifier: FakeAuthNotifier(isLoggedIn: false)).router;
  expect(router.routerDelegate.currentConfiguration.fullPath, '/login');
});
```

### 의존성 주입 (테스트 가능성)
```dart
// 프로덕션: ProviderScope(overrides: [])
// 테스트: ProviderContainer(overrides: [repoProvider.overrideWithValue(mockRepo)])
```

### Platform Channel 모킹
```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (call) async {
  if (call.method == 'getBatteryLevel') return 42;
  return null;
});
```

## Common Commands
```bash
flutter run                             # 실행
flutter build apk --release             # Android 빌드
flutter build ipa                       # iOS 빌드
flutter test                            # 전체 테스트
flutter test --coverage                 # 커버리지 리포트
flutter test --update-goldens           # Golden 업데이트
flutter analyze                         # 정적 분석
dart fix --apply                        # 자동 수정
flutter pub run build_runner build      # 코드 생성 (freezed, json_serializable 등)
```

## Dependency Conventions
```yaml
# pubspec.yaml 권장 패키지
dependencies:
  flutter_riverpod: ^2.x    # 상태관리
  go_router: ^13.x          # 라우팅
  freezed_annotation: ^2.x  # 불변 모델
  dartz: ^0.10.x            # Either (함수형 에러 처리)

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.x            # 모킹
  build_runner: ^2.x
  freezed: ^2.x
```
