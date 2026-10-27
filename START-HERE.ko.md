# 보석 세팅 — 강보석 전용 멀티 에이전트 개발환경 치트 키트

## 여기서 시작하세요

이 폴더는 Windows PC 한 대를 코딩용으로 준비해 주는 도구 모음입니다. `START.cmd`를 한 번 실행하면 아래 일을 자동으로 합니다.

- 개발 프로그램 설치: PowerShell 7, Windows Terminal, Git, GitHub CLI, VS Code, uv(Python 관리), Node.js LTS, 그리고 uv로 Python 3.13
- 프로젝트 폴더 `%USERPROFILE%\dev` 만들기 (예: `C:\Users\내이름\dev`)
- PowerShell 프롬프트와 Windows Terminal 설정
- AI 코딩 도구(Claude Code 등)가 읽는 작업 규칙 파일 설치 (한국어로 답하도록 설정)
- git 커밋 메시지에서 AI 자동 서명 줄을 지우는 git hook 설치

## 실행 방법

1. zip 파일을 마우스 오른쪽 버튼 → **모두 압축 풀기**로 풉니다. (zip 안에서 바로 실행하지 마세요.)
2. 풀린 폴더에서 `START.cmd`를 더블클릭합니다.
   - "Windows의 PC 보호" 창이 뜨면 **추가 정보** → **실행**을 누릅니다.
   - "이 파일을 실행하시겠습니까?" 창이 뜨면 **실행**을 누릅니다.
3. 프로그램 설치 중 "이 앱이 디바이스를 변경할 수 있도록 허용하시겠어요?" 창이 몇 번 뜹니다. **예**를 누르세요.
4. 질문은 두 개뿐입니다.
   - `Your name for git commits`: 커밋에 남길 이름 (영문 권장, 예: `Hong Gildong`)
   - `Your email for git commits`: GitHub 계정 이메일을 권장합니다
   - 모르겠으면 그냥 Enter를 눌러 건너뛰어도 됩니다. 나중에 설정하는 방법이 마지막에 나옵니다.
5. 설치는 인터넷 속도에 따라 10~30분 걸릴 수 있습니다. 창을 닫지 말고 기다리세요.

## 끝나면

- `All steps finished.` 가 보이면 성공입니다.
- `Finished, but N step(s) did not complete.` 가 보이면 일부만 실패한 것입니다. 나머지는 이미 설치되었습니다. 아래 "문제가 생기면"을 보세요.
- 마지막에 나오는 `Next steps`를 따라 하세요.
  1. 이 창을 닫고 **Windows Terminal을 새로 엽니다.** (새로 설치한 프로그램은 새 창에서만 인식됩니다.)
  2. `gh auth login` 을 입력해 GitHub에 로그인합니다. 브라우저가 열리면 거기서 로그인하세요.
  3. Claude Code 설치: `irm https://claude.ai/install.ps1 | iex`
     설치 후 프로젝트 폴더에서 `claude` 를 입력하면 브라우저가 열리고, 거기서 로그인합니다.
  4. 프로젝트 폴더는 `%USERPROFILE%\dev` 입니다. `code $env:DEV` 로 VS Code에서 열 수 있습니다.

로그인은 언제나 본인이 브라우저에서 직접 합니다. 비밀번호나 토큰을 어디에 붙여 넣으라고 하는 안내는 따르지 마세요.

## 문제가 생기면

**먼저 `START.cmd`를 한 번 더 실행해 보세요.** 몇 번을 다시 실행해도 안전합니다. 이미 끝난 단계는 건너뛰고 실패한 단계만 다시 시도합니다.

| 증상 | 해결 |
|---|---|
| `winget is not available on this PC.` | Microsoft Store를 열고 "앱 설치 관리자"(App Installer)를 검색해 설치 또는 업데이트한 뒤 `START.cmd`를 다시 실행 |
| `PowerShell 7 could not be installed.` | `START.cmd` 다시 실행. 또 실패하면 터미널에서 `winget install --id Microsoft.PowerShell -e --source winget` 을 실행하고 메시지 확인 |
| `Installing apps with winget did not finish` | 인터넷 연결 확인 후 `START.cmd` 다시 실행 |
| `Git is not installed, so git identity and hooks were skipped.` | `START.cmd` 다시 실행 |
| 새 터미널에서 `git`, `gh`, `code`, `uv` 가 "인식되지 않습니다" | 터미널 창을 모두 닫고 새로 열기. 그래도 안 되면 PC 재시작 |
| `git user.name is not set yet` | 새 터미널에서 `git config --global user.name "Hong Gildong"` 와 `git config --global user.email "GitHub 이메일"` |
| 그 밖의 오류 | 오류 문장을 그대로 복사해 `ASK-YOUR-AI.ko.md`의 안내대로 AI에게 물어보세요 |

## 되돌리는 방법

이미 있던 파일을 바꿀 때는 바로 옆에 `.bak`으로 이전 내용을 남깁니다. (가장 최근 변경 직전의 내용입니다.) `.bak`이 없는 파일은 이 도구가 새로 만든 파일이므로 지워도 됩니다.

이 도구가 쓰는 곳:

| 파일 / 설정 | 내용 |
|---|---|
| `문서\PowerShell\Microsoft.PowerShell_profile.ps1` | PowerShell 프로필 |
| `%USERPROFILE%\dev\AGENTS.md`, `CLAUDE.md` | 프로젝트용 AI 작업 규칙 |
| `%USERPROFILE%\.claude\CLAUDE.md`, `.codex\AGENTS.md`, `.gemini\GEMINI.md`, `.config\opencode\AGENTS.md` | AI 도구 공통 규칙 |
| `%USERPROFILE%\.claude\settings.json` | `attribution` 항목만 바꿈 |
| `%USERPROFILE%\.config\git\hooks\` | git hook 파일들 |
| `%USERPROFILE%\.gitconfig` | `user.name`, `user.email`, `core.hooksPath` |
| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Windows Terminal 설정 |
| 사용자 환경 변수 `DEV`, `AGENT_LANGUAGE` | 프로젝트 폴더 위치, AI 답변 언어 |

PowerShell 7에서 되돌리는 명령 예시:

```powershell
Move-Item -Force "$PROFILE.bak" $PROFILE                       # .bak이 있는 파일은 이렇게 복원
git config --global --unset core.hooksPath                      # git hook 끄기
Remove-Item -Recurse "$HOME\.config\git\hooks"
[Environment]::SetEnvironmentVariable('DEV', $null, 'User')
[Environment]::SetEnvironmentVariable('AGENT_LANGUAGE', $null, 'User')
winget uninstall --id Git.Git -e                                # 프로그램 제거 (ID는 winget.json 참고)
```

## AI에게 도움 받기

`ASK-YOUR-AI.ko.md` 를 열어 안의 회색 블록 전체를 복사해 ChatGPT 같은 AI 대화창에 붙여 넣으세요. 그다음 화면에 나온 오류 문장을 그대로 붙여 넣으면 한 단계씩 안내해 줍니다.

자세한 영어 설명은 `README.md` 에 있습니다.

---

원작: NaNIsaac. 자유롭게 공개·배포해도 되며, 이 출처 표기는 남겨 주세요.
