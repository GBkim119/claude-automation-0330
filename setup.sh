#!/bin/bash
# ============================================================
#  setup.sh — 개발 환경 최초 세팅 스크립트
#  GitHub + Telegram 워크플로우 자동화 도구 설치
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✘]${NC} $1"; exit 1; }
section() { echo -e "\n${YELLOW}══════════════════════════════${NC}"; echo -e "${YELLOW} $1${NC}"; echo -e "${YELLOW}══════════════════════════════${NC}"; }

section "🚀 개발 환경 세팅 시작"

# ── 1. Homebrew ─────────────────────────────────────────────
section "1) Homebrew 확인"
if command -v brew &>/dev/null; then
  info "Homebrew 이미 설치됨"
else
  warn "Homebrew 설치 중..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  info "Homebrew 설치 완료"
fi

# ── 2. Git ───────────────────────────────────────────────────
section "2) Git 확인"
if command -v git &>/dev/null; then
  info "Git 이미 설치됨 ($(git --version))"
else
  warn "Git 설치 중..."
  brew install git
  info "Git 설치 완료"
fi

# ── 3. GitHub CLI (gh) ───────────────────────────────────────
section "3) GitHub CLI (gh) 확인"
if command -v gh &>/dev/null; then
  info "GitHub CLI 이미 설치됨 ($(gh --version | head -1))"
else
  warn "GitHub CLI 설치 중..."
  brew install gh
  info "GitHub CLI 설치 완료"
fi

# ── 4. GitHub CLI 로그인 확인 ────────────────────────────────
section "4) GitHub 로그인 확인"
if gh auth status &>/dev/null; then
  info "GitHub 이미 로그인됨"
else
  warn "GitHub 로그인이 필요합니다."
  gh auth login
fi

# ── 5. jq (JSON 파싱용) ──────────────────────────────────────
section "5) jq 확인"
if command -v jq &>/dev/null; then
  info "jq 이미 설치됨"
else
  warn "jq 설치 중..."
  brew install jq
  info "jq 설치 완료"
fi

# ── 6. curl 확인 (텔레그램 API 호출용) ──────────────────────
section "6) curl 확인"
if command -v curl &>/dev/null; then
  info "curl 이미 설치됨"
else
  warn "curl 설치 중..."
  brew install curl
  info "curl 설치 완료"
fi

# ── 7. .env 파일 설정 ────────────────────────────────────────
section "7) 환경변수 (.env) 설정"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -f "$SCRIPT_DIR/.env" ]; then
  info ".env 파일이 이미 존재합니다."
else
  if [ -f "$SCRIPT_DIR/.env.example" ]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    warn ".env 파일이 생성되었습니다. 아래 값을 반드시 입력해주세요:"
    echo ""
    echo "  📝 편집 명령어: nano $SCRIPT_DIR/.env"
    echo ""
    echo "  필수 설정 항목:"
    echo "    TELEGRAM_BOT_TOKEN=  ← 텔레그램 봇 토큰"
    echo "    TELEGRAM_CHAT_ID=    ← 텔레그램 채팅 ID"
    echo "    GITHUB_USERNAME=     ← 깃허브 유저명"
    echo ""
  else
    error ".env.example 파일을 찾을 수 없습니다. 저장소를 다시 클론해주세요."
  fi
fi

# ── 8. 스크립트 실행 권한 설정 ───────────────────────────────
section "8) 스크립트 실행 권한 설정"
chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
info "모든 .sh 파일에 실행 권한 부여 완료"

# ── 9. (선택) PATH 등록 안내 ─────────────────────────────────
section "9) 전역 명령어 등록 (선택사항)"
echo "  어디서든 'new-project' 명령어로 실행하려면 아래를 ~/.zshrc 에 추가하세요:"
echo ""
echo "    export PATH=\"\$PATH:$SCRIPT_DIR\""
echo "    alias new-project='$SCRIPT_DIR/new-project.sh'"
echo ""
warn "  자동 등록하시겠습니까? (y/N)"
read -r REPLY
if [[ "$REPLY" =~ ^[Yy]$ ]]; then
  ZSHRC="$HOME/.zshrc"
  echo "" >> "$ZSHRC"
  echo "# GitHub + Telegram 자동화 스크립트" >> "$ZSHRC"
  echo "export PATH=\"\$PATH:$SCRIPT_DIR\"" >> "$ZSHRC"
  echo "alias new-project='$SCRIPT_DIR/new-project.sh'" >> "$ZSHRC"
  source "$ZSHRC" 2>/dev/null || true
  info "~/.zshrc 에 등록 완료! 터미널 재시작 또는 'source ~/.zshrc' 실행"
fi

section "✅ 세팅 완료!"
echo ""
echo "  사용 방법:"
echo "    ./new-project.sh           ← 새 GitHub 프로젝트 생성"
echo "    ./telegram.sh '메시지'     ← 텔레그램으로 메시지 전송"
echo ""
