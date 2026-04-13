---
name: tdc-stack-java
description: "Java + Spring Boot stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "java", "spring-boot"]
---

# Java + Spring Boot Stack Rules

## Project Detection
- `pom.xml` 또는 `build.gradle`/`build.gradle.kts` 존재 시 자동 적용
- `@SpringBootApplication` 어노테이션 확인

## Coding Conventions
- Java 17+ (records, sealed classes, pattern matching, text blocks)
- `PascalCase` 클래스, `camelCase` 메서드/변수, `UPPER_SNAKE` 상수
- `Optional` 반환 사용 (`null` 반환 금지). 파라미터에는 `Optional` 금지
- `var` 사용 가능 (로컬 변수, 타입 명확할 때)
- Record 클래스: DTO/Value Object에 적극 사용

## Spring Boot Patterns
- **Layered Architecture**: Controller → Service → Repository
- **Dependency Injection**: 생성자 주입만 사용 (`@Autowired` 필드 주입 금지)
- **Validation**: `@Valid` + `jakarta.validation` 어노테이션
- **Exception Handling**: `@RestControllerAdvice` + `@ExceptionHandler`
- **Configuration**: `application.yml` 사용. `@ConfigurationProperties` for 타입 안전 설정
- **Profiles**: `dev`, `staging`, `prod` 분리

## Security (Spring Security)
- `SecurityFilterChain` 빈 기반 설정 (WebSecurityConfigurerAdapter deprecated)
- JWT: `spring-security-oauth2-resource-server`
- CORS 설정 명시적으로. `@CrossOrigin` 남발 금지
- 비밀번호: `BCryptPasswordEncoder`

## Testing
- `@SpringBootTest` 통합 테스트. `@WebMvcTest` 컨트롤러 단위 테스트
- `MockMvc` for 컨트롤러 테스트
- `@MockBean` for 서비스 모킹
- Testcontainers for DB 테스트

## Common Commands
```bash
./mvnw spring-boot:run    # Maven 실행
./gradlew bootRun          # Gradle 실행
./mvnw test                # Maven 테스트
./gradlew test             # Gradle 테스트
```
