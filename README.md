# Gem Setting — a multi-agent dev cheat kit, cut for Boseok

(Built on dev-starter.)

A Windows dev machine setup in one folder, for one PC: the core apps, a PowerShell profile,
rules for coding agents (Claude Code, Codex, Gemini CLI, OpenCode), and a git hook that keeps AI
credit lines out of commit messages.

Korean beginner guide: [START-HERE.ko.md](START-HERE.ko.md). A prompt to paste into your own AI
assistant so it can walk you through: [ASK-YOUR-AI.ko.md](ASK-YOUR-AI.ko.md).

## Quickstart

1. Extract the zip anywhere (for example `Downloads\dev-starter`).
2. Double-click `START.cmd`. If Windows asks "Do you want to run this file?", choose Run.
3. Answer two questions (your name and email for git; Enter skips either), and approve the
   Windows permission prompts the installers show.
4. Read the "Next steps" it prints at the end.

The same from a terminal:

```powershell
cd $HOME\Downloads\dev-starter
.\START.cmd
```

Running it again is safe: every step checks before it writes, so a second run changes nothing,
and a step that failed is retried.

## What it looks like

After setup, open a terminal in your projects folder and ask an agent for something small:

> 서울의 월별 평균기온을 꺾은선 그래프로 그리는 Python 스크립트를 uv로 만들어 줘. 결과는 seoul_temp.png로 저장하고, 한글이 깨지지 않게 해 줘.

![Claude Code session: uv init, uv add matplotlib, write and run the script](docs/demo/claude-session.png)

![The chart it produced](docs/demo/seoul_temp.png)

The agent follows the rules this kit installs: Korean replies, uv for Python, and it runs and checks
its own result before it says it is done. (Session condensed from a real run; paths shortened.)

## What it does

`START.cmd` runs `bootstrap.ps1` with the Windows PowerShell that ships with Windows (execution
policy bypassed for that one process). `bootstrap.ps1` removes the download mark from the kit's
files, installs PowerShell 7 with winget if it is missing, and runs `setup.ps1 -Apps -Language Korean`
under PowerShell 7.

| Step | When | Result |
|---|---|---|
| DEV | always | the folder for your projects, `%USERPROFILE%\dev` unless `-Dev <path>`; saved as user variable `DEV` |
| Apps | `-Apps` (START.cmd passes it) | `winget import winget.json`: PowerShell 7, Windows Terminal, Git, GitHub CLI, VS Code, uv, Node.js LTS; then `uv python install 3.13 --default` |
| Profile | always | `profile.ps1` to `$PROFILE` (UTF-8 console, `[user@host] PS path>` prompt with `#` when elevated) |
| Agent rules | always | `AGENTS.md` and a `CLAUDE.md` that imports it, in `DEV`; they apply to every project under it |
| Agent global rules | always | `claude-global.md`, with your name and language filled in, to `~\.claude\CLAUDE.md`, `~\.codex\AGENTS.md`, `~\.gemini\GEMINI.md`, `~\.config\opencode\AGENTS.md` |
| Claude Code | always | sets only `attribution` in `~\.claude\settings.json` (no co-author, PR or session lines); other settings are kept |
| Git identity | always | asks for `user.name` and `user.email` when they are not set; `-GitName`/`-GitEmail` skip the questions |
| Git hooks | always | `commit-msg`, `pre-push` and forwarding copies of `forward-hook` in `~\.config\git\hooks`, set as global `core.hooksPath` |
| Windows Terminal | always | `terminal\settings.json` (starts in `%DEV%`, Cascadia Mono, dark scheme) |
| CLI tools | `-Tools` (off by default) | `tools.ps1`: the optional tools in `tools.json` |

A file that already exists and differs is kept next to it as `<name>.bak` before it is replaced
(the `.bak` holds the version before the most recent change; a later change replaces it).
A failed `winget`, `uv` or `git` command does not stop the run: the other steps still run, and
the end of the output lists each failed step with the command to retry, then exits with code 1.

`setup.ps1` parameters: `-Apps`, `-Tools`, `-Dev <path>`, `-GitName <name>`, `-GitEmail <email>`,
`-Language <name>` (default English; START.cmd passes Korean), `-Overlay <dir>`. Arguments given to
`START.cmd` are passed on, for example `.\START.cmd -Dev D:\code -Language English`.

## The commit-msg hook

Claude Code's `attribution` setting only stops the lines it adds itself. An agent can still type
`Co-Authored-By: Claude ...` into a message. `commit-msg` removes, from every commit in every
repository:

- `Co-authored-by:` lines naming Claude, Copilot, Cursor, Codex, ChatGPT, Gemini, Devin, Aider,
  Codeium, Windsurf, Tabnine or Jules (human co-authors stay)
- `Claude-Session:` links
- "Generated with/by Claude ..." lines

A global `core.hooksPath` hides each repository's `.git\hooks`, so the other hook names are
copies of `forward-hook`, which runs the repository's own hook when there is one. `pre-push` also
runs the ruff lint a repository pins in `.github/workflows/lint.yml` before handing over
(`SKIP_LOCAL_CI=1` skips it, `LOCAL_CI_TESTS=1` adds `uv run pytest`); without that file it only
hands over.

## Customizing the agent rules

- `AGENTS.md`: rules for every project under `DEV`. Edit it and run `setup.ps1` again.
- `claude-global.md`: your personal rules for every agent. `<YOUR_NAME>` is filled from git
  `user.name` and `<LANGUAGE>` from `-Language` (saved as user variable `AGENT_LANGUAGE`). Replace
  either placeholder with fixed text if you prefer, add or delete lines, and run `setup.ps1` again.
- A repository's own `AGENTS.md` or `CLAUDE.md` adds to these for that repository.

## Extras

- `extras\office-view.ps1`: keeps a file that a build writes apart from the copy open in Office.
  `publish <work.pptx> <view.pptx>` copies to the view file, or to `<view>_view2.pptx` while the
  view file is open; `render <deck.pptx> <outdir>` exports slides as PNG; `pdf <deck.pptx> <out.pdf>`
  prints through PowerPoint and trims the page to the slide (`office-view-crop.py`, run with uv).
  Needs PowerPoint for `render` and `pdf`.
- Optional CLI tools (`.\tools.ps1`, or `setup.ps1 -Tools`): codigest (`cdg`) and deai. `-DryRun`
  shows what would run, `-Update` updates, `-Only a,b` picks. More tools (a gh extension, a release
  `install.ps1`) go in an overlay's `config.json` `tools` list; the source repository's
  `examples\overlay` adds hanfix, gh-garden and clippath that way.
- More apps you might want: `winget install --id <id> -e` with Rustlang.Rustup, Kitware.CMake,
  Ninja-build.Ninja, prefix-dev.pixi, BurntSushi.ripgrep.MSVC, Helix.Helix, voidtools.Everything,
  M2Team.NanaZip, DigitalScholar.Zotero.

## Left out on purpose

This kit is for one PC used by one person. It does not set up SSH, a VPN between machines, a
phone, remote agents, several agent accounts, or syncing between PCs. To add them later, keep
them out of the core scripts: put the settings in an overlay (below), so this folder stays the
same on every machine. A second PC is then the same kit plus its own overlay; SSH keys, VPN
sign-in and account logins stay manual steps in their own tools, never files in the kit.

## Tests

```powershell
pwsh tests\run.ps1
```

Runs `START.cmd` and `setup.ps1` end to end with fake `winget`, `uv` and `gh`, with
`DEVSTARTER_SANDBOX` sending every user-level write (profile, home files, git config, user
variables, terminal settings) into a temporary folder; also the example overlay, `tools.ps1`, the
git hooks, `office-view.ps1 publish`, and a parse check of every script (`bootstrap.ps1` under
Windows PowerShell 5.1 too). `.\build.ps1` makes `dist\dev-starter-v0.zip` from the committed tree,
without `tests\` and `examples\`.

## Extending with an overlay (advanced)

An overlay is a folder kept outside this kit (a private repository, say) that adds personal
settings without changing the kit. Point setup at it once with `.\setup.ps1 -Overlay <dir>`
(saved as user variable `DEVSTARTER_OVERLAY`). Without one, the kit works on its own. It may hold:

```
config.json      identity, DEV, language, extra winget ids, extra tools
rules\*.md       appended in name order to the generated global agent rules
setup.d\*.ps1    run in name order after the kit's own steps, each in its own pwsh
```

```json
{
  "git": { "name": "Your Name", "email": "your email" },
  "name": "Name used in the agent rules",
  "dev": "%USERPROFILE%\\dev",
  "language": "English",
  "winget": ["voidtools.Everything"],
  "tools": [ { "Name": "my-tool", "Kind": "uv", "Command": "my-tool", "Package": "my-tool" } ]
}
```

Every key is optional; a `setup.ps1` parameter wins over `config.json`. A `tools` entry uses the
fields described at the top of `tools.ps1`, and replaces a `tools.json` entry of the same name.
Hooks see `DEVSTARTER_ROOT` (this kit), `DEVSTARTER_OVERLAY` and `DEV`; a hook that exits nonzero
is listed in the summary and the next one still runs. The source repository has a worked example
in `examples\overlay`.

---

Original work by NaNIsaac. You may share or publish it; please keep this credit.
