---
name: issue-detail
description: "특정 Sentry 이슈의 상세 정보를 조회합니다. 이슈 ID 또는 URL을 입력하세요."
argument-hint: "[이슈 ID 또는 Sentry URL]"
---

# Sentry 이슈 상세 조회

특정 이슈의 스택트레이스, breadcrumbs, 태그 등 상세 정보를 조회합니다.

## 입력

$ARGUMENTS

## 실행 절차

### 1단계: 이슈 ID 추출

사용자 입력에서 이슈 ID를 추출합니다:
- 숫자 ID: `12345`
- Sentry URL: `https://sentry.io/organizations/.../issues/12345/` → ID 추출
- 짧은 ID: `PROJECT-ABC` 형태

### 2단계: 이슈 상세 조회

```
get_issue_details → 이슈 기본 정보, 스택트레이스, breadcrumbs
get_issue_tag_values → 태그별 분포 (environment, browser, os, user 등)
```

### 3단계: 이벤트 조회 (필요 시)

특정 이벤트를 더 자세히 볼 필요가 있으면:
```
search_issue_events → 해당 이슈의 개별 이벤트 상세
```

### 4단계: 결과 보고

```markdown
## 이슈 상세: [이슈 제목]

- **ID**: [이슈 ID]
- **프로젝트**: [프로젝트명]
- **최초 발생**: [날짜]
- **최근 발생**: [날짜]
- **발생 횟수**: [N]회
- **영향 사용자**: [N]명
- **상태**: [unresolved/resolved/ignored]
- **담당자**: [assignee]

### 스택트레이스
[포맷된 스택트레이스]

### Breadcrumbs (최근 10개)
[시간순 breadcrumbs 목록]

### 태그 분포
| 태그 | 상위 값 |
|------|---------|
| environment | production (80%), staging (20%) |
| browser | Chrome (60%), Safari (30%) |
```

- 근본 원인 분석이 필요하면 `/sentry-ops:investigate` 안내
