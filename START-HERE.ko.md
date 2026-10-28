# 보석 세팅 — 강보석 전용 멀티 에이전트 개발환경 치트 키트

## 여기서 시작하세요

이 폴더는 Windows PC 한 대를 코딩용으로 준비해 주는 도구 모음입니다. `START.cmd`를 한 번 실행하면 아래 일을 자동으로 합니다.

- 개발 프로그램 설치: PowerShell 7, Windows Terminal, Git, GitHub CLI, VS Code, uv(Python 관리), Node.js LTS, 그리고 uv로 Python 3.13
- uv가 자기가 설치한 Python만 쓰도록 설정 (사용자 환경 변수 `UV_PYTHON_PREFERENCE=only-managed`). 어떤 PC에서는 `python.exe`가 "Python 설치 관리자"라서, uv가 그것을 건드리기만 해도 Python이 하나 더 몰래 설치되기 때문입니다.
- 프로젝트 폴더 만들기. 기본은 `%USERPROFILE%\dev`(예: `C:\Users\내이름\dev`)이고, 위치는 사용자 환경 변수 `DEV`에 저장됩니다. 이 문서에서는 이 폴더를 `%DEV%`라고 씁니다. (보석 님 PC는 `C:\Dev`)
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
- 이 요약 없이 빨간 오류 글씨에서 멈췄다면 그 자리에서 실행이 멈춘 것입니다. 오류 문장을 그대로 복사해 `ASK-YOUR-AI.ko.md`의 안내대로 AI에게 물어보세요.
- 마지막에 나오는 `Next steps`를 따라 하세요.
  1. 이 창을 닫고 **Windows Terminal을 새로 엽니다.** (새로 설치한 프로그램은 새 창에서만 인식됩니다.)
  2. `gh auth login` 을 입력해 GitHub에 로그인합니다. 브라우저가 열리면 거기서 로그인하세요.
  3. Claude Code 설치: `irm https://claude.ai/install.ps1 | iex`
     설치 후 프로젝트 폴더에서 `claude` 를 입력하면 브라우저가 열리고, 거기서 로그인합니다.
  4. 프로젝트 폴더 위치는 `Your projects folder is ...` 줄에 나옵니다(`%DEV%`). `code $env:DEV` 로 VS Code에서 열 수 있습니다.

로그인은 언제나 본인이 브라우저에서 직접 합니다. 비밀번호나 토큰을 어디에 붙여 넣으라고 하는 안내는 따르지 마세요.

## 문제가 생기면

**먼저 `START.cmd`를 한 번 더 실행해 보세요.** 몇 번을 다시 실행해도 안전합니다. 이미 끝난 단계는 건너뛰고 실패한 단계만 다시 시도합니다. 처음 실행하기 전에 열어 둔 창에서 다시 실행해도, 저장해 둔 프로젝트 폴더(`DEV`), 답변 언어, overlay를 그대로 씁니다.

| 증상 | 해결 |
|---|---|
| `winget is not available on this PC.` | Microsoft Store를 열고 "앱 설치 관리자"(App Installer)를 검색해 설치 또는 업데이트한 뒤 `START.cmd`를 다시 실행 |
| `PowerShell 7 could not be installed.` | `START.cmd` 다시 실행. 또 실패하면 터미널에서 `winget install --id Microsoft.PowerShell -e --source winget` 을 실행하고 메시지 확인 |
| `These arguments contain a double quote, so they were split wrongly:` | 터미널에서 옵션을 줄 때 폴더 경로 끝에 `\`를 붙이지 마세요. 예: `.\START.cmd -Dev "D:\My Projects"` |
| `인수 '...'을(를) 받을 수 있는 위치 매개 변수를 찾을 수 없습니다` 또는 `매개 변수 이름 '...'과(와) 일치하는 매개 변수를 찾을 수 없습니다` | 터미널에서 준 옵션이 잘못되어 설정이 시작되지 않았습니다. 빈칸이 있는 이름은 따옴표로 감싸고(예: `.\START.cmd -GitName "Hong Gildong"`), 옵션 이름의 철자를 확인한 뒤 다시 실행 |
| `Installing apps with winget did not finish` | 인터넷 연결 확인 후 `START.cmd` 다시 실행 |
| `Git is not installed, so git identity and hooks were skipped.` | `START.cmd` 다시 실행 |
| `Claude Code attribution was not set: ...settings.json is not valid JSON or not a JSON object` | `%USERPROFILE%\.claude\settings.json` 내용이 깨져 있거나 형식이 맞지 않아 손대지 않았습니다(나머지 단계는 진행됨). 메모장으로 열어 고치거나(AI에게 내용을 보여 주면 도와줍니다), 고치기 어려우면 파일 이름을 `settings.json.broken`으로 바꾼 뒤(Claude Code는 기본 설정으로 시작합니다) `START.cmd` 다시 실행 |
| 새 터미널에서 `git`, `gh`, `code`, `uv` 가 "인식되지 않습니다" | 터미널 창을 모두 닫고 새로 열기. 그래도 안 되면 PC 재시작 |
| `git user.name is not set yet` | 새 터미널에서 `git config --global user.name "Hong Gildong"` 와 `git config --global user.email "GitHub 이메일"` |
| `git lfs install` 이 `Hook already exists: pre-push` 라고 함 | 정상입니다. LFS 설정은 이미 되었고, 이 도구의 `pre-push`가 LFS 파일도 올려 줍니다. 안내에 나오는 `git lfs update --force` 는 실행하지 마세요(이 도구의 git hook을 덮어씁니다). 이미 실행했다면 `START.cmd` 다시 실행 |
| 그 밖의 오류 | 오류 문장을 그대로 복사해 `ASK-YOUR-AI.ko.md`의 안내대로 AI에게 물어보세요 |

## 되돌리는 방법

이미 있던 파일을 바꿀 때는 바로 옆에 바꾸기 전 내용을 남깁니다.

- `<파일 이름>.bak`: 이 도구가 그 파일을 처음 바꾸기 직전의 내용입니다. 한 번 생기면 다시 덮어쓰지 않습니다. 이 도구를 쓰기 전부터 있던 파일이라면 이것이 원래 내용입니다.
- `<파일 이름>.<날짜-시각>.bak` (예: `settings.json.20261027-153000.bak`): 그 뒤에 다시 바꿀 때마다 바꾸기 직전 내용입니다.

이 도구가 새로 만든 파일은 처음에는 `.bak`이 없습니다. 나중에 도구가 그 파일을 다시 바꾸면 `.bak`에는 도구가 처음 쓴 내용이 들어갑니다. 그런 파일은 `.bak`으로 되돌리지 말고 `.bak` 파일들과 함께 지우면 됩니다. 되돌리기 전에 `.bak`을 메모장으로 열어 내용을 확인하세요. 이 도구의 예전 버전(보석 님 PC에서 처음 실행한 버전 포함)은 바꿀 때마다 `.bak`을 덮어썼기 때문에, 두 번 이상 실행했다면 `.bak`이 이 도구가 쓴 내용일 수 있습니다.

**`%USERPROFILE%\.gitconfig`는 예외입니다.** 이 파일은 `.bak`이 생기지 않고, 이 도구를 쓰기 전에 들어 있던 설정(보석 님 PC에서는 GitHub CLI의 로그인 연결 설정)도 같이 들어 있습니다. 이 파일은 절대 지우지 말고, 아래 명령으로 이 도구가 넣은 항목만 하나씩 지우세요.

이 도구가 쓰는 곳:

| 파일 / 설정 | 내용 |
|---|---|
| `문서\PowerShell\Microsoft.PowerShell_profile.ps1` | PowerShell 프로필 |
| `%DEV%\AGENTS.md`, `CLAUDE.md` | 프로젝트용 AI 작업 규칙 |
| `%USERPROFILE%\.claude\CLAUDE.md`, `.codex\AGENTS.md`, `.gemini\GEMINI.md`, `.config\opencode\AGENTS.md` | AI 도구 공통 규칙 |
| `%USERPROFILE%\.claude\settings.json` | `attribution` 항목만 바꿈 |
| `%USERPROFILE%\.config\git\hooks\` | git hook 파일들 |
| `%USERPROFILE%\.gitconfig` | `core.hooksPath`, 그리고 이 도구에서 입력했을 때만 `user.name`, `user.email` |
| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json` | Windows Terminal 설정 |
| 사용자 환경 변수 `DEV`, `AGENT_LANGUAGE`, `UV_PYTHON_PREFERENCE`, `DEVSTARTER_OVERLAY` | 프로젝트 폴더 위치, AI 답변 언어, uv가 자기 Python만 쓰게 하는 설정, overlay 폴더 위치(overlay를 쓸 때만) |
| 사용자 `Path`의 `%USERPROFILE%\.local\bin` | `python` 명령이 있는 폴더 (`uv python update-shell`이 추가) |
| uv로 설치한 Python 3.13 | `uv python install 3.13 --default` |
| winget으로 설치한 프로그램 | `winget.json`의 목록 (이미 있던 프로그램은 건너뜀) |

아래 명령은 PowerShell 7 터미널에서 필요한 부분만 골라 실행합니다.

`.bak`이 있는 파일 복원 (예: PowerShell 프로필):

```powershell
Move-Item -Force "$PROFILE.bak" $PROFILE
```

git hook 끄기:

```powershell
git config --global --unset core.hooksPath
Remove-Item -Recurse "$HOME\.config\git\hooks"
```

git 이름과 이메일 지우기. 이 도구의 질문에 입력했거나 `-GitName`/`-GitEmail`, overlay 설정으로 넣었을 때만 실행하세요. 원래 있던 값이면 그대로 둡니다.

```powershell
git config --global --unset user.name
git config --global --unset user.email
```

uv로 설치한 Python 지우기 (uv를 지우기 전에, 그리고 아래에서 `UV_PYTHON_PREFERENCE`를 지우기 전에 해야 합니다):

```powershell
uv python uninstall 3.13
```

사용자 환경 변수 지우기:

```powershell
[Environment]::SetEnvironmentVariable('DEV', $null, 'User')
[Environment]::SetEnvironmentVariable('AGENT_LANGUAGE', $null, 'User')
[Environment]::SetEnvironmentVariable('UV_PYTHON_PREFERENCE', $null, 'User')
[Environment]::SetEnvironmentVariable('DEVSTARTER_OVERLAY', $null, 'User')
```

사용자 `Path`에서 `.local\bin` 빼기: 아래 명령으로 "환경 변수" 창을 엽니다(시작 메뉴에서 "계정의 환경 변수 편집"을 검색해도 됩니다). 위쪽 사용자 변수에서 `Path` 선택 → **편집** → `C:\Users\내이름\.local\bin` 줄 선택 → **삭제** → **확인** → **확인**. Claude Code(`claude`)와 uv로 설치한 도구도 이 폴더에 있으니, 계속 쓸 거면 이 줄은 남겨 두세요.

```powershell
rundll32 sysdm.cpl,EditEnvironmentVariables
```

프로그램 제거 (ID는 `winget.json` 참고):

```powershell
winget uninstall --id astral-sh.uv -e
```

winget은 이 도구가 설치한 프로그램인지, 원래 있던 프로그램인지 구분하지 못합니다. 이 도구를 쓰기 전부터 있던 프로그램은 지우지 마세요. (보석 님 PC에는 Git과 GitHub CLI가 원래 있었습니다.)

여기까지는 이 도구가 직접 쓰는 것입니다. overlay의 `setup.d` 스크립트가 쓰는 것(보석 님 `gem-overlay`에서는 Claude Code 프로그램, `%USERPROFILE%\.claude\skills`, `문서\PowerShell\profile.ps1`)은 그 저장소의 `README.md` 표에 있습니다.

## 다른 PC로 옮기기

보석 님 개인 설정(git 이름과 이메일, 프로젝트 폴더 위치, 답변 언어, 추가 프로그램, AI 규칙, Claude Code skill)은 비공개 overlay 저장소 `gem-overlay`에 있습니다. 새 PC나 클라우드에서 GitHub로부터 같은 환경을 다시 만들 때는 그 저장소의 `MIGRATE.ko.md`를 따라 하세요. 이 PC에서는 `%DEV%\gem-overlay\MIGRATE.ko.md` 입니다. 로그인(GitHub, Claude)은 새 PC에서 다시 직접 합니다.

## AI에게 도움 받기

`ASK-YOUR-AI.ko.md` 를 열어 안의 회색 블록 전체를 복사해 ChatGPT 같은 AI 대화창에 붙여 넣으세요. 그다음 화면에 나온 오류 문장을 그대로 붙여 넣으면 한 단계씩 안내해 줍니다.

자세한 영어 설명은 `README.md` 에 있습니다.

---

원작: NaNIsaac. 자유롭게 공개·배포해도 되며, 이 출처 표기는 남겨 주세요.
