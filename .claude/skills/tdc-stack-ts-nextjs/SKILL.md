---
name: tdc-stack-ts-nextjs
description: "TypeScript + Next.js stack conventions, patterns, and best practices for TDC agents"
user-invocable: false
tags: ["skill-pack", "typescript", "nextjs"]
---

# TypeScript + Next.js Stack Rules

## Project Detection
- `next.config.js`/`next.config.ts`, `app/` or `pages/` 디렉토리 존재 시 자동 적용
- `tsconfig.json`, `package.json` 내 `next` 의존성 확인

## Coding Conventions
- **Strict TypeScript**: `strict: true` in tsconfig. `any` 사용 금지. `unknown` + type guard 사용
- `interface` > `type` (확장 가능한 객체). `type`은 유니온/인터섹션에만
- 함수 컴포넌트만 사용 (클래스 컴포넌트 금지)
- `const` 기본. `let`은 재할당 필요 시만. `var` 금지
- 파일명: 컴포넌트 `PascalCase.tsx`, 유틸/훅 `camelCase.ts`
- Import 순서: 외부 → 내부 → 상대경로 → 스타일

## Next.js Patterns (App Router)
- **App Router** (`app/`) 기본. Pages Router는 레거시
- **Server Components** 기본. `'use client'`는 인터랙션이 필요한 곳만
- **Data Fetching**: `fetch()` with `cache`/`revalidate`. Server Actions for mutations
- **Route Handlers**: `app/api/` 내 `route.ts`. `GET`, `POST` 등 named exports
- **Layouts**: `layout.tsx`로 공통 레이아웃. `loading.tsx`, `error.tsx` 활용
- **Metadata**: `generateMetadata()` 또는 `metadata` export로 SEO
- **Images**: `next/image` 필수 사용. 외부 이미지는 `next.config` domains 설정

## State Management
- **Server state**: React Server Components + `fetch` (TanStack Query 불필요)
- **Client state**: `useState`/`useReducer` 기본. 복잡하면 Zustand
- **Form**: `react-hook-form` + `zod` validation

## Styling
- **Tailwind CSS** 기본. CSS Modules 대안. styled-components 비권장 (RSC 비호환)
- `cn()` 유틸리티로 조건부 클래스 (`clsx` + `tailwind-merge`)

## Security
- Server Actions에서 항상 입력 검증 (zod)
- API routes에서 인증 미들웨어 필수
- 환경변수: `NEXT_PUBLIC_` 접두사는 공개 데이터만
- XSS 방지: `dangerouslySetInnerHTML` 사용 금지

## Testing
- `vitest` 권장 (jest 대안). `@testing-library/react`
- E2E: Playwright
- Coverage 목표: 70%+

## Common Commands
```bash
npm run dev          # 개발 서버
npm run build        # 프로덕션 빌드
npm run lint         # ESLint
npx tsc --noEmit     # 타입 체크
npm test             # 테스트
```
