---
name: tdc-version
description: "TechDog Claude - 설치된 tdc 버전 정보 표시"
user-invocable: true
argument-hint: ""
---

**입력:** $ARGUMENTS

# /tdc-version — Version Info

설치된 tdc 버전을 표시합니다.

## 실행 흐름

1. `~/.tdc/.repo/package.json`이 있는지 확인
2. 있으면 → `jq -r .version`으로 버전 추출 후 표시
3. 없으면 → `"버전 정보를 찾을 수 없습니다. 재설치를 권장합니다."` 안내

## 출력 형식

정상:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  TechDog Claude (tdc)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Version:  2.9.0
  Home:     ~/.tdc/
  Skills:   ~/.claude/skills/tdc*/  (N개 설치됨)

  업그레이드:  /tdc-upgrade
  문서:        ~/.tdc/.repo/README.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

오류:
```
[TDC] 버전 정보를 찾을 수 없습니다. 재설치를 권장합니다.
      설치: curl -sSL <install-url> | bash
```

## 참고

- `git -C ~/.tdc/.repo rev-parse --short HEAD`로 커밋 해시를 추가 표시 가능
- 설치된 스킬팩 목록도 함께 보여주면 디버깅에 유용
