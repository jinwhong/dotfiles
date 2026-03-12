---
name: project_workspace
description: airs 워크스페이스 구조. 현재 활발한 프로젝트 3개와 그 외 아카이브/보조 프로젝트 정리.
type: project
---

`/Users/hong.jinwoo/airs`는 git 레포가 아닌 워크스페이스 디렉토리. 각 서브디렉토리가 독립 git 프로젝트.

## 현재 활발한 프로젝트 (우선순위순, 2026-03 기준)

### 1. SwiftRead (`swiftread/`)
- 환자 MRI 리포트를 쉬운 말로 번역하는 서비스
- Python/FastAPI 백엔드 + React/TypeScript 프론트엔드
- LLM 파이프라인 (structuring → translation → validation → enrichment)
- Go 마이그레이션 버전도 있음 (`swiftread-go/`)
- CI: GitHub Actions (`ci.yml`)

### 2. MyScan (`myscan/`)
- 의료 스캔 관련 신제품 (랜딩 페이지 + 패키지 상세)
- React/TypeScript 프론트엔드
- 병원 데이터셋 1000+ 전국 규모
- CI: 아직 미설정

### 3. Protocol Drift (`protocol-drift/`)
- MRI 프로토콜 모니터링/비교 도구
- Fleet Overview, Sequence Completeness 기능
- CI: 아직 미설정

## 보조/유지보수 프로젝트
- `wholebody-patient-report/` — 전신 환자 리포트
- `graphics/`, `graphics-compare/` — 렌더링/시각화
- `version-insight/`, `version_dashboard/` — 버전 추적
- `protocol_alert/` — 프로토콜 알림 (protocol-drift의 전신?)
- `serena/` — LSP 기반 코딩 에이전트 (MCP 플러그인으로도 사용 중)

**How to apply:** 작업 요청 시 어느 프로젝트인지 먼저 파악. 각 프로젝트에 개별 CLAUDE.md가 있으므로 해당 파일 참조할 것. MyScan과 Protocol Drift는 CI 미설정 상태이므로 배포 관련 작업 시 주의.
