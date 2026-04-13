---
name: tdc-stack-react
description: "React + TypeScript stack conventions (Vite/CRA) for TDC agents"
user-invocable: false
tags: ["skill-pack", "react", "typescript"]
---

# React + TypeScript Stack Rules

## Project Detection
- `package.json` 내 `react` 의존성 + `vite.config.ts` 또는 `react-scripts` 존재 시
- Next.js 프로젝트는 `tdc-stack-ts-nextjs` 스킬팩이 우선 적용

## Coding Conventions
- **Strict TypeScript**. `any` 금지. Props는 `interface`로 정의
- 함수 컴포넌트만 사용. `function` 선언 또는 화살표 함수 (프로젝트 통일)
- 파일명: 컴포넌트 `PascalCase.tsx`, 훅 `use*.ts`, 유틸 `camelCase.ts`
- Export: named export 기본 (`export default` 최소화)
- Import 순서: React → 외부 라이브러리 → 내부 모듈 → 스타일

## React Patterns
- **Hooks**: `useState`, `useEffect`, `useMemo`, `useCallback` 적절히 사용
  - `useMemo`/`useCallback`: 측정 후 필요할 때만 (premature optimization 금지)
- **Custom Hooks**: 재사용 가능한 로직은 `use*` 훅으로 추출
- **Props**: Destructure in parameter. Children은 `React.ReactNode`
- **Event Handlers**: `handle*` 네이밍 (`handleClick`, `handleSubmit`)
- **Conditional Rendering**: 삼항연산자 또는 `&&`. 복잡하면 early return

## State Management
- **Local**: `useState` / `useReducer`
- **Server state**: TanStack Query (`@tanstack/react-query`)
- **Global client state**: Zustand (Redux 대신)
- **Form**: `react-hook-form` + `zod`

## Styling
- Tailwind CSS 권장. CSS Modules 대안
- `cn()` 유틸리티 (`clsx` + `tailwind-merge`)

## Project Structure
```
src/
  components/       # 공유 UI 컴포넌트
  features/         # Feature-first 구조
    auth/
      components/
      hooks/
      api/
  hooks/            # 공유 커스텀 훅
  lib/              # 유틸리티
  types/            # 공유 타입
```

## Testing
- `vitest` + `@testing-library/react`
- User-centric testing: `getByRole`, `getByText` (implementation detail 테스트 금지)
- `msw` (Mock Service Worker) for API 모킹
- E2E: Playwright

## Common Commands
```bash
npm run dev          # Vite 개발 서버
npm run build        # 프로덕션 빌드
npm run lint         # ESLint
npx tsc --noEmit     # 타입 체크
npm test             # 테스트
```
