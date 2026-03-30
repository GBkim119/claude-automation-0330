# 🚀 GitHub + Telegram 자동화 스크립트 (claude-automation-0330)

맥북에서 GitHub 프로젝트 생성부터 텔레그램 알림까지 한 번에 처리하는 쉘 스크립트 모음입니다.

---

## 📦 스크립트 구성

| 파일 | 설명 |
|------|------|
| `setup.sh` | 최초 1회 실행 — 필수 도구 설치 및 환경 설정 |
| `new-project.sh` | 새 GitHub 프로젝트 생성 + 텔레그램 알림 |
| `telegram.sh` | 텔레그램 메시지/파일 전송 헬퍼 |
| `.env.example` | 환경변수 템플릿 |

---

## 🛠️ 최초 설정 (딱 한 번만)

### 1. 저장소 클론
```bash
git clone https://github.com/GBkim119/claude-automation-0330.git
cd claude-automation-0330
```

### 2. 환경변수 설정
```bash
cp .env.example .env
nano .env
```

필수 입력값:
- TELEGRAM_BOT_TOKEN: BotFather에서 발급한 봇 토큰
- TELEGRAM_CHAT_ID: 본인 텔레그램 채팅 ID (@userinfobot 으로 확인)
- GITHUB_USERNAME: GBkim119

### 3. 세팅 실행
```bash
chmod +x *.sh
./setup.sh
```

---

## 🎯 사용법

### 새 GitHub 프로젝트 생성
```bash
./new-project.sh           # 대화형
./new-project.sh my-app    # 이름 바로 지정
```

### 텔레그램 전송
```bash
./telegram.sh "배포 완료! 🎉"
./telegram.sh --push       # git push 정보 전송
./telegram.sh --commit     # git commit 정보 전송
./telegram.sh --status     # git status 전송
./telegram.sh --file ./log.txt "로그 파일"
```

---

## 📁 지원 프로젝트 템플릿

| 번호 | 템플릿 | 생성 파일 |
|------|--------|-----------|
| 1 | Blank | README.md, .gitignore |
| 2 | Node.js | package.json, index.js, .gitignore |
| 3 | Python | main.py, requirements.txt, .gitignore |
| 4 | Next.js | create-next-app (TypeScript + Tailwind) |
| 5 | React | Vite + React |

---

## 💡 push 시 자동 알림 설정

`.git/hooks/post-push` 파일 생성:
```bash
#!/bin/bash
~/claude-automation-0330/telegram.sh --push
```
```bash
chmod +x .git/hooks/post-push
```
