#!/bin/bash
set -euo pipefail

# ============================================================
# sentry-ops 플러그인 설치 스크립트
# Sentry MCP 서버 연결 + Claude Code 플러그인 설치
# ============================================================

# --- 색상 출력 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step()  { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }

# --- 1단계: 사전 요구사항 확인 ---
step "1/4 사전 요구사항 확인"

# Claude Code 확인
if command -v claude &> /dev/null; then
    ok "Claude Code 설치 확인"
else
    error "Claude Code가 설치되어 있지 않습니다."
    echo "  설치: https://docs.anthropic.com/en/docs/claude-code"
    exit 1
fi

# pnpm 확인
if command -v pnpm &> /dev/null; then
    ok "pnpm 설치 확인"
else
    error "pnpm이 설치되어 있지 않습니다."
    echo "  설치: npm install -g pnpm"
    exit 1
fi

# --- 2단계: Sentry Auth Token 설정 ---
step "2/4 Sentry Auth Token 설정"

info "Sentry User Auth Token이 필요합니다."
echo ""
echo -e "  ${BOLD}토큰 생성 방법:${NC}"
echo -e "  1. ${CYAN}https://sentry.io/settings/auth-tokens/${NC} 접속"
echo -e "  2. ${CYAN}Create New Token${NC} 클릭"
echo -e "  3. 생성된 토큰 복사"
echo ""

read -p "$(echo -e "${CYAN}Sentry Auth Token을 입력하세요: ${NC}")" sentry_token

if [[ -z "$sentry_token" ]]; then
    error "토큰이 입력되지 않았습니다."
    exit 1
fi

# 토큰 형식 확인
if [[ ! "$sentry_token" =~ ^sntryu_ ]]; then
    warn "토큰이 'sntryu_'로 시작하지 않습니다. 올바른 User Auth Token인지 확인하세요."
    read -p "$(echo -e "${YELLOW}계속 진행할까요? (y/N): ${NC}")" proceed
    if [[ ! "$proceed" =~ ^[Yy]$ ]]; then
        error "설치를 취소합니다."
        exit 1
    fi
fi

# --- 3단계: Sentry MCP 서버 등록 ---
step "3/4 Sentry MCP 서버 등록"

# 이미 등록되어 있는지 확인
if claude mcp list 2>/dev/null | grep -q "^sentry:"; then
    warn "Sentry MCP 서버가 이미 등록되어 있습니다."
    read -p "$(echo -e "${YELLOW}기존 설정을 덮어쓸까요? (y/N): ${NC}")" overwrite
    if [[ "$overwrite" =~ ^[Yy]$ ]]; then
        claude mcp remove sentry --scope user 2>/dev/null || true
        info "기존 설정 제거 완료"
    else
        ok "기존 설정 유지"
    fi
fi

# MCP 서버 등록
if ! claude mcp list 2>/dev/null | grep -q "^sentry:"; then
    claude mcp add \
        -e SENTRY_AUTH_TOKEN="$sentry_token" \
        --scope user \
        sentry \
        -- pnpm dlx @sentry/mcp-server --access-token "$sentry_token"

    ok "Sentry MCP 서버 등록 완료 (user scope)"
fi

# 연결 확인
echo ""
info "MCP 서버 연결 상태 확인 중..."
if claude mcp list 2>/dev/null | grep "^sentry:" | grep -q "Connected"; then
    ok "Sentry MCP 서버 연결 성공!"
else
    warn "MCP 서버가 아직 연결되지 않았습니다. Claude Code를 새로 시작하면 연결됩니다."
fi

# --- 4단계: 플러그인 설치 ---
step "4/4 sentry-ops 플러그인 설치"

# 기존 설치 확인
if claude plugin list 2>/dev/null | grep -q "sentry-ops"; then
    warn "sentry-ops 플러그인이 이미 설치되어 있습니다. 재설치합니다..."
    claude plugin uninstall sentry-ops 2>/dev/null || true
fi

# 마켓플레이스에서 설치 시도, 실패하면 로컬 설치
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if claude plugin marketplace add nathankim0/sentry-ops 2>/dev/null && \
   claude plugin install sentry-ops 2>/dev/null; then
    ok "마켓플레이스에서 플러그인 설치 완료"
else
    info "마켓플레이스 설치 실패. 로컬에서 설치합니다..."
    if claude plugin install --local "$SCRIPT_DIR" 2>/dev/null; then
        ok "로컬 플러그인 설치 완료"
    else
        warn "자동 설치 실패. 수동으로 설치해주세요:"
        echo ""
        echo "  claude plugin marketplace add nathankim0/sentry-ops"
        echo "  claude plugin install sentry-ops"
    fi
fi

# --- 완료 ---
echo ""
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo -e "${GREEN}${BOLD}  sentry-ops 설치 완료!${NC}"
echo -e "${GREEN}${BOLD}============================================================${NC}"
echo ""
echo -e "${BOLD}사용 가능한 스킬:${NC}"
echo -e "  ${GREEN}/sentry-ops:investigate${NC}    이슈 원인 종합 파악"
echo -e "  ${GREEN}/sentry-ops:search-issues${NC}  이슈 검색/목록"
echo -e "  ${GREEN}/sentry-ops:issue-detail${NC}   특정 이슈 상세 조회"
echo ""
echo -e "${BOLD}예시:${NC}"
echo -e "  ${CYAN}/sentry-ops:investigate 결제 실패가 어제 발생${NC}"
echo -e "  ${CYAN}/sentry-ops:search-issues 500 error${NC}"
echo -e "  ${CYAN}/sentry-ops:issue-detail 12345${NC}"
echo ""
ok "Claude Code를 새로 시작하여 사용하세요!"
