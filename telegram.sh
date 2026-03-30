#!/bin/bash
# ============================================================
#  telegram.sh — 텔레그램 메시지 전송 헬퍼
#  사용법:
#    ./telegram.sh "메시지 내용"
#    ./telegram.sh --push    (최근 git push 정보 전송)
#    ./telegram.sh --commit  (최근 git commit 정보 전송)
#    ./telegram.sh --status  (현재 git 상태 전송)
#    ./telegram.sh --file /path/to/file.txt  (파일 첨부)
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  source "$ENV_FILE"
fi

if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
  echo "❌ TELEGRAM_BOT_TOKEN 또는 TELEGRAM_CHAT_ID 가 설정되지 않았습니다."
  echo "   .env 파일을 확인하거나 환경변수를 직접 설정해주세요."
  exit 1
fi

API_URL="https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN"

send_message() {
  local MESSAGE="$1"
  local RESPONSE
  RESPONSE=$(curl -s -X POST "$API_URL/sendMessage" \
    -H "Content-Type: application/json" \
    -d "{
      \"chat_id\": \"$TELEGRAM_CHAT_ID\",
      \"text\": \"$MESSAGE\",
      \"parse_mode\": \"Markdown\",
      \"disable_web_page_preview\": false
    }")

  if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "✅ 텔레그램 전송 완료"
  else
    echo "❌ 전송 실패: $RESPONSE"
    exit 1
  fi
}

send_file() {
  local FILE_PATH="$1"
  local CAPTION="${2:-}"

  if [ ! -f "$FILE_PATH" ]; then
    echo "❌ 파일을 찾을 수 없습니다: $FILE_PATH"
    exit 1
  fi

  curl -s -X POST "$API_URL/sendDocument" \
    -F "chat_id=$TELEGRAM_CHAT_ID" \
    -F "document=@$FILE_PATH" \
    -F "caption=$CAPTION" > /dev/null

  echo "✅ 파일 전송 완료: $FILE_PATH"
}

send_push_info() {
  local REPO_NAME
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')")
  local BRANCH
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  local COMMIT_HASH
  COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
  local COMMIT_MSG
  COMMIT_MSG=$(git log -1 --format="%s" 2>/dev/null || echo "N/A")
  local AUTHOR
  AUTHOR=$(git log -1 --format="%an" 2>/dev/null || echo "N/A")
  local REMOTE_URL
  REMOTE_URL=$(git remote get-url origin 2>/dev/null | sed 's/git@github.com:/https:\/\/github.com\//' | sed 's/\.git$//' || echo "")

  local MSG="📤 *Git Push 완료!*

📁 *저장소:* \`$REPO_NAME\`
🌿 *브랜치:* \`$BRANCH\`
📝 *커밋:* \`$COMMIT_HASH\` — $COMMIT_MSG
👤 *작성자:* $AUTHOR
📅 $(date '+%Y-%m-%d %H:%M:%S')
${REMOTE_URL:+🔗 $REMOTE_URL}"

  send_message "$MSG"
}

send_commit_info() {
  local REPO_NAME
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')")
  local BRANCH
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  local COMMIT_HASH
  COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "N/A")
  local COMMIT_MSG
  COMMIT_MSG=$(git log -1 --format="%s" 2>/dev/null || echo "N/A")
  local FILES_CHANGED
  FILES_CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | head -10 | tr '\n' ', ' | sed 's/,$//' || echo "N/A")

  local MSG="✅ *Git Commit 완료!*

📁 *저장소:* \`$REPO_NAME\`
🌿 *브랜치:* \`$BRANCH\`
🔑 *해시:* \`$COMMIT_HASH\`
📝 *메시지:* $COMMIT_MSG
📂 *변경 파일:* $FILES_CHANGED
📅 $(date '+%Y-%m-%d %H:%M:%S')"

  send_message "$MSG"
}

send_git_status() {
  local REPO_NAME
  REPO_NAME=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')")
  local BRANCH
  BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  local STATUS
  STATUS=$(git status --short 2>/dev/null | head -15 || echo "(status 없음)")

  local MSG="📊 *Git Status*

📁 *저장소:* \`$REPO_NAME\`
🌿 *브랜치:* \`$BRANCH\`
📋 *상태:*
\`\`\`
$STATUS
\`\`\`
📅 $(date '+%Y-%m-%d %H:%M:%S')"

  send_message "$MSG"
}

if [ $# -eq 0 ]; then
  echo "사용법:"
  echo "  ./telegram.sh '메시지'             — 텍스트 전송"
  echo "  ./telegram.sh --push               — git push 정보 전송"
  echo "  ./telegram.sh --commit             — git commit 정보 전송"
  echo "  ./telegram.sh --status             — git status 전송"
  echo "  ./telegram.sh --file /path/file    — 파일 전송"
  exit 0
fi

case "$1" in
  --push)   send_push_info   ;;
  --commit) send_commit_info ;;
  --status) send_git_status  ;;
  --file)
    shift
    FILE_PATH="$1"
    shift
    CAPTION="${*:-}"
    send_file "$FILE_PATH" "$CAPTION"
    ;;
  *)
    MESSAGE="$*"
    send_message "$MESSAGE"
    ;;
esac
