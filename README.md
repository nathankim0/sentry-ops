# sentry-ops

Sentry MCP 서버 + 이슈 조사/검색 스킬을 제공하는 Claude Code 플러그인

## 설치

```bash
# 원클릭 설치
git clone https://github.com/nathankim0/sentry-ops.git
cd sentry-ops
./setup.sh
```

또는 수동 설치:

```bash
# 1. 마켓플레이스 등록 + 설치
claude plugin marketplace add nathankim0/sentry-ops
claude plugin install sentry-ops

# 2. Sentry MCP 서버 등록 (OAuth 인증)
claude mcp add --transport http sentry --scope user https://mcp.sentry.dev/mcp
```

## 스킬

| 스킬 | 설명 | 예시 |
|------|------|------|
| `/sentry-ops:investigate` | 이슈 원인 종합 파악 | `/sentry-ops:investigate 결제 실패가 어제 발생` |
| `/sentry-ops:search-issues` | 이슈 검색/목록 | `/sentry-ops:search-issues 500 error` |
| `/sentry-ops:issue-detail` | 특정 이슈 상세 조회 | `/sentry-ops:issue-detail 12345` |

### investigate

가장 핵심 스킬. 이슈 설명을 입력하면:

1. Sentry에서 관련 이슈 검색
2. 스택트레이스, breadcrumbs, 태그 분석
3. Sentry AI(Seer) 근본 원인 분석
4. 코드베이스에서 해당 코드 위치 추적
5. 종합 보고서 생성

### search-issues

자연어 또는 Sentry 쿼리 문법으로 이슈를 검색합니다.

### issue-detail

특정 이슈 ID 또는 URL로 상세 정보(스택트레이스, breadcrumbs, 태그 분포)를 조회합니다.

## Sentry MCP 도구

이 플러그인은 [Sentry 공식 Remote MCP 서버](https://docs.sentry.io/product/sentry-mcp/)를 사용합니다.

주요 도구:
- `search_issues` — 자연어 이슈 검색
- `get_issue_details` — 이슈 상세 (스택트레이스, breadcrumbs)
- `get_issue_tag_values` — 태그별 분포
- `analyze_issue_with_seer` — AI 근본 원인 분석
- `search_events` — 이벤트 검색/집계
- `get_trace_details` — 트레이스 상세

전체 26개 도구가 제공됩니다.

## 인증

OAuth 기반 인증으로, 처음 사용 시 브라우저에서 Sentry 로그인 후 권한을 승인하면 됩니다. 별도 토큰 생성이 필요 없습니다.

## License

MIT
