---
name: search-issues
description: "Sentry에서 이슈를 검색합니다. 자연어 또는 Sentry 쿼리 문법 모두 지원."
argument-hint: "[검색어] [프로젝트 (선택)]"
---

# Sentry 이슈 검색

Sentry에서 이슈를 검색하고 목록을 보여줍니다.

## 입력

$ARGUMENTS

## 실행 절차

### 1단계: 검색어 파싱

사용자 입력에서 추출:
- **검색어**: 에러 메시지, 키워드, Sentry 쿼리 등
- **프로젝트** (선택): 특정 앱/프로젝트로 필터링

### 2단계: 이슈 검색

```
search_issues → 자연어 기반 검색 (AI가 Sentry 쿼리로 변환)
```

자연어가 아닌 Sentry 쿼리 문법이 입력된 경우:
```
list_issues → Sentry 쿼리 문법으로 직접 검색
```

### 3단계: 결과 정리

검색 결과를 테이블 형식으로 보여줍니다:

```markdown
| # | 이슈 | 발생 횟수 | 최근 발생 | 상태 | 프로젝트 |
|---|------|----------|----------|------|---------|
| 1 | [제목] | N회 | 시간 | unresolved | project |
```

- 최대 10개까지 표시
- 상세 분석이 필요한 이슈가 있으면 `/sentry-ops:investigate` 또는 `/sentry-ops:issue-detail` 안내
