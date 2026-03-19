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

# --- 2단계: Sentry MCP 서버 등록 ---
step "2/4 Sentry MCP 서버 등록"

info "Sentry 공식 Remote MCP 서버를 등록합니다."
info "OAuth 인증 방식이므로 별도 토큰 생성이 필요 없습니다."
echo ""

# 이미 등록되어 있는지 확인
if claude mcp list 2>/dev/null | grep -q "sentry"; then
    warn "Sentry MCP 서버가 이미 등록되어 있습니다."
    echo ""
    read -p "$(echo -e "${YELLOW}기존 설정을 덮어쓸까요? (y/N): ${NC}")" overwrite
    if [[ "$overwrite" =~ ^[Yy]$ ]]; then
        claude mcp remove sentry 2>/dev/null || true
        info "기존 설정 제거 완료"
    else
        ok "기존 설정 유지"
    fi
fi

# MCP 서버 등록 (user scope - 모든 프로젝트에서 사용 가능)
if ! claude mcp list 2>/dev/null | grep -q "sentry"; then
    echo ""
    info "Sentry MCP 서버를 등록합니다..."
    echo ""
    echo -e "  ${BOLD}등록 범위를 선택하세요:${NC}"
    echo "  1) user   - 모든 프로젝트에서 사용 (권장)"
    echo "  2) project - 현재 프로젝트에서만 사용"
    echo ""
    read -p "$(echo -e "${CYAN}선택 (1/2, 기본: 1): ${NC}")" scope_choice
    scope_choice="${scope_choice:-1}"

    if [[ "$scope_choice" == "2" ]]; then
        claude mcp add --transport http sentry --scope project https://mcp.sentry.dev/mcp
        ok "Sentry MCP 서버 등록 완료 (project scope)"
    else
        claude mcp add --transport http sentry --scope user https://mcp.sentry.dev/mcp
        ok "Sentry MCP 서버 등록 완료 (user scope)"
    fi
fi

# --- 3단계: 플러그인 설치 ---
step "3/4 sentry-ops 플러그인 설치"

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
        echo ""
        echo "  또는 로컬 설치:"
        echo "  claude plugin install --local $SCRIPT_DIR"
    fi
fi

# --- 4단계: OAuth 인증 안내 ---
step "4/4 Sentry OAuth 인증"

echo -e "${BOLD}설치가 완료되었습니다!${NC}"
echo ""
echo "OAuth 인증은 Claude Code에서 Sentry 도구를 처음 사용할 때 자동으로 진행됩니다:"
echo ""
echo -e "  1. Claude Code를 시작합니다: ${CYAN}claude${NC}"
echo -e "  2. Sentry 관련 질문을 합니다: ${CYAN}/sentry-ops:search-issues 최근 에러${NC}"
echo -e "  3. 브라우저가 열리며 Sentry OAuth 로그인 화면이 표시됩니다"
echo -e "  4. Sentry 계정으로 로그인하고 권한을 승인합니다"
echo -e "  5. 인증 완료! 이후에는 자동으로 연결됩니다"
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
ok "sentry-ops 설치 완료!"
