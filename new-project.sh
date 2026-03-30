#!/bin/bash
# ============================================================
#  new-project.sh — GitHub 프로젝트 생성 + 텔레그램 알림
#  사용법: ./new-project.sh [프로젝트명]
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}[✔]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[✘]${NC} $1"; exit 1; }
ask()     { echo -e "${CYAN}[?]${NC} $1"; }
section() { echo -e "\n${BOLD}$1${NC}"; echo -e "──────────────────────────────"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  error ".env 파일이 없습니다. 먼저 ./setup.sh 를 실행해주세요."
fi
source "$ENV_FILE"

[ -z "$TELEGRAM_BOT_TOKEN" ] && error "TELEGRAM_BOT_TOKEN 이 .env 에 설정되어 있지 않습니다."
[ -z "$TELEGRAM_CHAT_ID" ]   && error "TELEGRAM_CHAT_ID 가 .env 에 설정되어 있지 않습니다."
[ -z "$GITHUB_USERNAME" ]    && error "GITHUB_USERNAME 이 .env 에 설정되어 있지 않습니다."

if ! gh auth status &>/dev/null; then
  error "GitHub 로그인이 필요합니다. 'gh auth login' 을 실행해주세요."
fi

section "📁 새 GitHub 프로젝트 생성"

if [ -n "$1" ]; then
  PROJECT_NAME="$1"
else
  ask "프로젝트 이름을 입력하세요 (영문, 하이픈 사용 가능):"
  read -r PROJECT_NAME
fi

PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')

if [ -z "$PROJECT_NAME" ]; then
  error "프로젝트 이름을 입력해야 합니다."
fi

ask "프로젝트 설명 (엔터 시 생략):"
read -r PROJECT_DESC

ask "공개 설정: [1] Public  [2] Private  (기본: 1)"
read -r VISIBILITY_CHOICE
case "$VISIBILITY_CHOICE" in
  2) VISIBILITY="private" ;;
  *) VISIBILITY="public"  ;;
esac

ask "프로젝트 템플릿 선택:"
echo "  [1] Blank        — 빈 프로젝트 (README만)"
echo "  [2] Node.js      — package.json + .gitignore"
echo "  [3] Python       — requirements.txt + venv + .gitignore"
echo "  [4] Next.js      — Next.js 보일러플레이트"
echo "  [5] React        — Vite + React 보일러플레이트"
read -r TEMPLATE_CHOICE

DEFAULT_DIR="$HOME/Projects"
ask "프로젝트를 생성할 폴더 (기본: $DEFAULT_DIR):"
read -r PROJECTS_DIR
PROJECTS_DIR="${PROJECTS_DIR:-$DEFAULT_DIR}"

mkdir -p "$PROJECTS_DIR"
PROJECT_PATH="$PROJECTS_DIR/$PROJECT_NAME"

if [ -d "$PROJECT_PATH" ]; then
  error "이미 '$PROJECT_PATH' 폴더가 존재합니다."
fi

section "🔨 프로젝트 생성 중..."

mkdir -p "$PROJECT_PATH"
cd "$PROJECT_PATH"
git init
info "Git 초기화 완료"

cat > README.md <<EOF
# $PROJECT_NAME

${PROJECT_DESC:-프로젝트 설명을 입력하세요.}

## 시작하기

\`\`\`bash
git clone https://github.com/$GITHUB_USERNAME/$PROJECT_NAME.git
cd $PROJECT_NAME
\`\`\`

## 라이선스

MIT
EOF
info "README.md 생성 완료"

apply_template_node() {
  cat > package.json <<EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "${PROJECT_DESC:-}",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "node --watch index.js"
  },
  "keywords": [],
  "author": "$GITHUB_USERNAME",
  "license": "MIT"
}
EOF
  echo 'console.log("Hello, World!");' > index.js
  cat > .gitignore <<'GITEOF'
node_modules/
.env
*.log
.DS_Store
dist/
GITEOF
  info "Node.js 템플릿 적용 완료"
}

apply_template_python() {
  touch requirements.txt
  cat > main.py <<'PYEOF'
def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
PYEOF
  cat > .gitignore <<'GITEOF'
__pycache__/
*.py[cod]
.env
venv/
.venv/
dist/
build/
.DS_Store
GITEOF
  info "Python 템플릿 적용 완료"
}

apply_template_nextjs() {
  warn "Next.js 프로젝트는 npx로 생성합니다. 잠시 기다려주세요..."
  cd "$PROJECTS_DIR"
  rm -rf "$PROJECT_PATH"
  npx create-next-app@latest "$PROJECT_NAME" --typescript --tailwind --eslint --app --src-dir --import-alias "@/*" --no-git 2>&1
  cd "$PROJECT_PATH"
  git init
  info "Next.js 템플릿 적용 완료"
}

apply_template_react() {
  warn "React(Vite) 프로젝트는 npm create로 생성합니다. 잠시 기다려주세요..."
  cd "$PROJECTS_DIR"
  rm -rf "$PROJECT_PATH"
  npm create vite@latest "$PROJECT_NAME" -- --template react 2>&1
  cd "$PROJECT_PATH"
  git init
  info "React(Vite) 템플릿 적용 완료"
}

case "$TEMPLATE_CHOICE" in
  2) apply_template_node   ;;
  3) apply_template_python ;;
  4) apply_template_nextjs ;;
  5) apply_template_react  ;;
  *) info "Blank 템플릿 사용" ;;
esac

if [ ! -f .gitignore ]; then
  cat > .gitignore <<'GITEOF'
.env
.DS_Store
*.log
GITEOF
fi

git add .
git commit -m "chore: initial commit 🎉"
info "첫 번째 커밋 완료"

section "☁️  GitHub 저장소 생성 중..."

GH_CREATE_ARGS=("$PROJECT_NAME" "--$VISIBILITY" "--source=." "--remote=origin" "--push")
[ -n "$PROJECT_DESC" ] && GH_CREATE_ARGS+=("--description" "$PROJECT_DESC")

gh repo create "${GH_CREATE_ARGS[@]}"
REPO_URL="https://github.com/$GITHUB_USERNAME/$PROJECT_NAME"
info "GitHub 저장소 생성 완료: $REPO_URL"

section "📨 텔레그램 알림 전송 중..."

VISIBILITY_KO="$( [ "$VISIBILITY" = "public" ] && echo "공개" || echo "비공개" )"
TEMPLATE_NAMES=("Blank" "Node.js" "Python" "Next.js" "React")
TEMPLATE_IDX=$(( ${TEMPLATE_CHOICE:-1} - 1 ))
TEMPLATE_NAME="${TEMPLATE_NAMES[$TEMPLATE_IDX]:-Blank}"

TG_MESSAGE="🚀 *새 GitHub 프로젝트 생성됨!*

📁 *이름:* \`$PROJECT_NAME\`
📝 *설명:* ${PROJECT_DESC:-없음}
🔧 *템플릿:* $TEMPLATE_NAME
🔒 *공개 설정:* $VISIBILITY_KO
🔗 *URL:* $REPO_URL

📅 $(date '+%Y-%m-%d %H:%M:%S')"

"$SCRIPT_DIR/telegram.sh" "$TG_MESSAGE"

section "✅ 완료!"
echo ""
echo -e "  ${BOLD}프로젝트 경로:${NC} $PROJECT_PATH"
echo -e "  ${BOLD}GitHub URL:${NC}   $REPO_URL"
echo ""
echo "  바로 이동하려면:"
echo -e "  ${CYAN}cd $PROJECT_PATH${NC}"
echo ""
