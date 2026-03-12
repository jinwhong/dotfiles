---
name: reference_cicd
description: CI/CD 현황. SwiftRead만 GitHub Actions 설정됨. MyScan, Protocol Drift는 미설정.
type: reference
---

## CI/CD 현황 (2026-03 기준)

| 프로젝트 | CI/CD | 위치 |
|----------|-------|------|
| SwiftRead | GitHub Actions | `swiftread/.github/workflows/ci.yml` |
| MyScan | 미설정 | — |
| Protocol Drift | 미설정 | — |

- GitHub Actions CI/CD 최적화는 항상 신경 써야 하는 항목
- 새 프로젝트에 CI 세팅 제안할 것

**How to apply:** 배포/테스트 관련 작업 시 해당 프로젝트의 CI 유무를 먼저 확인. CI가 없는 프로젝트에서 배포 작업 요청 시 CI 설정 필요성 언급할 것.
