---
name: feedback_playwright_issue
description: Playwright 플러그인이 에러 후 비활성화됐던 사례. 도구 에러 시 끄지 말고 원인 파악할 것.
type: feedback
---

도구/플러그인에서 에러 발생 시, 비활성화로 회피하지 말고 원인을 파악해서 해결할 것.

**Why:** 2026-02-25에 Playwright가 404 에러 나자 설정에서 `false`로 꺼버림. 이후 프론트엔드 작업에서 실제 브라우저 검증이 빠진 채로 3주간 작업함. CLAUDE.md 규칙과 설정이 불일치한 상태를 아무도 못 잡음.
**How to apply:** 도구 에러 발생 시 → 로그 확인 → 원인 수정 → 재시도. 끄는 건 최후의 수단. 설정 변경 시 CLAUDE.md와의 일관성도 체크.
