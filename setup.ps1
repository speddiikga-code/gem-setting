# Set up a Windows dev machine. Safe to run again; every step checks before it writes, and a
# failed step does not stop the others: they are listed at the end with the command to retry.
#   .\setup.ps1                     profile, agent rules, Claude Code attribution, git hooks and identity, terminal
#   .\setup.ps1 -Apps               also install the apps in winget.json (and the overlay's extra ids)
#   .\setup.ps1 -Tools              also install the optional CLI tools in tools.json (tools.ps1)
#   .\setup.ps1 -Dev <path>         the folder for repositories (default: %USERPROFILE%\dev; saved as DEV)
#   .\setup.ps1 -GitName <name> -GitEmail <email>   git identity without the questions
#   .\setup.ps1 -Language <name>    the language agents reply in (saved as AGENT_LANGUAGE; default English)
#   .\setup.ps1 -Overlay <dir>      a private overlay folder (saved as DEVSTARTER_OVERLAY); see README
# A parameter wins over the overlay's config.json, which wins over what the machine already has.
# DEVSTARTER_SANDBOX=<dir> sends every user-level write (profile, home files, git config, user
# variables, terminal settings) into <dir>; tests/run.ps1 uses it to run this script end to end.
# A stray word, such as the second half of an unquoted -GitName Boseok Kang, would otherwise
# become -Dev, and a misspelled parameter would be ignored without a word.
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$Apps,
    [switch]$Tools,
    [string]$Dev,
    [string]$GitName,
    [string]$GitEmail,
    [string]$Language,
    [string]$Overlay
)
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

function Step($text) { Write-Host "-> $text" -ForegroundColor Cyan }

# Copies $Path to <Path>.bak, or to <Path>.<yyyyMMdd-HHmmss>.bak when that exists: the undo steps
# restore <Path>.bak as the file from before the kit, so the first one is never replaced.
function Backup-File([string]$Path) {
    $bak = "$Path.bak"
    if (Test-Path -LiteralPath $bak) { $bak = "$Path.$(Get-Date -Format yyyyMMdd-HHmmss).bak" }
    Copy-Item -LiteralPath $Path -Destination $bak -Force
}

# Writes $Text to $Path only when it differs; a different existing file is backed up first.
# Returns whether it wrote.
function Write-IfChanged([string]$Path, [string]$Text) {
    $old = (Test-Path -LiteralPath $Path) ? (Get-Content -LiteralPath $Path -Raw) : $null
    if ($old -ceq $Text) { return $false }
    if ($old) { Backup-File $Path }
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    [IO.File]::WriteAllText($Path, $Text)
    $true
}

# Sets only the attribution key of a Claude Code settings.json; every other key stays as it was,
# and the file before the change is backed up. A file that is not a JSON object is left alone.
function Set-ClaudeAttribution([string]$Path) {
    $exists = Test-Path -LiteralPath $Path
    $text = $exists ? (Get-Content -LiteralPath $Path -Raw) : $null
    $json = [ordered]@{}
    if ("$text".Trim()) {
        # A hashtable also reads keys that differ only in case, and an empty key, which are valid JSON.
        $json = try { $text | ConvertFrom-Json -AsHashtable -NoEnumerate } catch { $null }
    }
    # Claude Code needs an object; an array or a string would be rewritten, and backed up again, on every run.
    if ($json -isnot [Collections.IDictionary]) {
        throw "$Path is not valid JSON or not a JSON object; fix the file or delete it (Claude Code then starts from its defaults)"
    }
    $want = [ordered]@{ commit = ''; pr = ''; sessionUrl = $false }
    if (($json['attribution'] | ConvertTo-Json -Compress) -eq ($want | ConvertTo-Json -Compress)) { return $false }
    $json['attribution'] = $want
    if ($exists) { Backup-File $Path }
    New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null
    $json | ConvertTo-Json -Depth 32 | Set-Content -LiteralPath $Path
    $true
}

# The overlay's config.json, or an empty object without an overlay; a missing key reads as $null.
function Get-OverlayConfig([string]$Dir) {
    $file = $Dir ? (Join-Path $Dir 'config.json') : $null
    ($file -and (Test-Path -LiteralPath $file)) ? (Get-Content -LiteralPath $file -Raw | ConvertFrom-Json) : [pscustomobject]@{}
}

# The global rules: the template with the name and language filled in, then the overlay's
# rules/*.md fragments in name order.
function Get-Rules([string]$Template, [string]$Name, [string]$Language, [string]$OverlayDir) {
    $text = $Template.Replace('<YOUR_NAME>', $Name).Replace('<LANGUAGE>', $Language)
    $rulesDir = $OverlayDir ? (Join-Path $OverlayDir 'rules') : $null
    if ($rulesDir -and (Test-Path -LiteralPath $rulesDir)) {
        foreach ($fragment in Get-ChildItem -LiteralPath $rulesDir -Filter *.md -File | Sort-Object Name) {
            $text = $text.TrimEnd() + "`n`n" + (Get-Content -LiteralPath $fragment.FullName -Raw).Trim() + "`n"
        }
    }
    $text
}

# winget.json with the overlay's extra package ids added once each.
function Get-WingetImport([string]$CoreFile, [string[]]$Extra) {
    $json = Get-Content -LiteralPath $CoreFile -Raw | ConvertFrom-Json
    $packages = [Collections.Generic.List[object]]::new([object[]]$json.Sources[0].Packages)
    foreach ($id in $Extra) {
        if ($id -and $id -notin $packages.PackageIdentifier) { $packages.Add([pscustomobject]@{ PackageIdentifier = $id }) }
    }
    $json.Sources[0].Packages = $packages.ToArray()
    $json | ConvertTo-Json -Depth 8
}

# Runs the overlay's setup.d/*.ps1 in name order, each in its own pwsh; returns one result per hook.
# A failing hook does not stop the next one.
function Invoke-OverlayHooks([string]$OverlayDir) {
    $hookDir = $OverlayDir ? (Join-Path $OverlayDir 'setup.d') : $null
    if (-not ($hookDir -and (Test-Path -LiteralPath $hookDir))) { return }
    foreach ($hook in Get-ChildItem -LiteralPath $hookDir -Filter *.ps1 -File | Sort-Object Name) {
        Write-Host "   $($hook.Name)"
        & pwsh -NoProfile -File $hook.FullName | Out-Host
        [pscustomobject]@{ Name = $hook.Name; Code = $LASTEXITCODE }
    }
}

# The background image path is machine specific, so the repo copy holds a placeholder.
function Expand-TerminalSettings([string]$Text, [string]$RepoDir) {
    $Text.Replace('__STARTER__', ($RepoDir -replace '\\', '\\'))
}

$sandbox = $env:DEVSTARTER_SANDBOX
$userHome, $profilePath = $HOME, $PROFILE
if ($sandbox) {
    $userHome = Join-Path $sandbox 'home'
    $profilePath = Join-Path $userHome 'Documents\PowerShell\Microsoft.PowerShell_profile.ps1'
    $env:LOCALAPPDATA = Join-Path $sandbox 'local'
    $env:GIT_CONFIG_GLOBAL = Join-Path $userHome '.gitconfig'
    # The real user's DEV, AGENT_LANGUAGE and DEVSTARTER_OVERLAY would send writes (and overlay hooks) outside
    # the sandbox; only what an earlier sandboxed run saved counts.
    $saved = Join-Path $sandbox 'user-variables.json'
    $saved = (Test-Path $saved) ? (Get-Content $saved -Raw | ConvertFrom-Json -AsHashtable) : @{}
    foreach ($name in 'DEV', 'AGENT_LANGUAGE', 'DEVSTARTER_OVERLAY') {
        if ($saved[$name]) { Set-Item "env:$name" $saved[$name] } else { Remove-Item "env:$name" -ErrorAction Ignore }
    }
    Write-Host "sandbox: every write goes under $sandbox" -ForegroundColor Yellow
} else {
    # A shell opened before an earlier run saved these lacks them, and a rerun from it would
    # silently drop the overlay and reset DEV and the language; the saved user values win.
    foreach ($name in 'DEV', 'AGENT_LANGUAGE', 'DEVSTARTER_OVERLAY') {
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if ($value) { Set-Item "env:$name" $value }
    }
}

function Set-UserVariable([string]$Name, [string]$Value) {
    if ($sandbox) {
        $file = Join-Path $sandbox 'user-variables.json'
        $vars = (Test-Path $file) ? (Get-Content $file -Raw | ConvertFrom-Json -AsHashtable) : @{}
        if ($vars[$Name] -ne $Value) {
            $vars[$Name] = $Value
            $vars | ConvertTo-Json | Set-Content $file
        }
    } elseif ([Environment]::GetEnvironmentVariable($Name, 'User') -ne $Value) {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
    }
    Set-Item "env:$Name" $Value
}

# winget installs put their folders on the machine and user PATH; this shell started before that.
# Appended, so whatever is already first on PATH stays first.
function Update-SessionPath {
    $known = $env:PATH -split ';'
    $new = foreach ($scope in 'Machine', 'User') {
        [Environment]::GetEnvironmentVariable('PATH', $scope) -split ';' | Where-Object { $_ -and $_ -notin $known }
    }
    if ($new) { $env:PATH = (@($env:PATH) + $new) -join ';' }
}

if ($Overlay) {
    if (-not (Test-Path -LiteralPath $Overlay -PathType Container)) { throw "overlay folder not found: $Overlay" }
    Set-UserVariable DEVSTARTER_OVERLAY (Resolve-Path -LiteralPath $Overlay).Path
}
$overlayDir = $env:DEVSTARTER_OVERLAY
if ($overlayDir -and -not (Test-Path -LiteralPath $overlayDir -PathType Container)) {
    Write-Warning "DEVSTARTER_OVERLAY points at $overlayDir, which does not exist; running without an overlay"
    $overlayDir = $null
}
$config = Get-OverlayConfig $overlayDir
$env:DEVSTARTER_ROOT = $here

# DEV is the root of every repository and where new terminals start.
$Dev = $Dev ? $Dev : ($config.dev ? $config.dev : ($env:DEV ? $env:DEV : (Join-Path $userHome 'dev')))
$Dev = [Environment]::ExpandEnvironmentVariables($Dev)
New-Item -ItemType Directory -Force $Dev | Out-Null
Set-UserVariable DEV (Resolve-Path $Dev).Path

$Language = $Language ? $Language : $config.language
if ($Language) { Set-UserVariable AGENT_LANGUAGE $Language }

# With the Python install manager, the WindowsApps python.exe is its alias rather than the Store
# stub, and uv running it while looking for an interpreter silently installs a runtime. Limiting
# uv to the Pythons it manages also keeps uv the one Python source.
Set-UserVariable UV_PYTHON_PREFERENCE only-managed

# Native commands do not throw on a nonzero exit code, so check it: a failed step is reported
# in the summary and the script exits 1. Every step is safe to repeat, so rerunning retries it.
$failed = [Collections.Generic.List[string]]::new()
$notes = [Collections.Generic.List[string]]::new()
$rerun = 'double-click START.cmd again (or run .\setup.ps1 -Apps in PowerShell 7)'
function Invoke-Native([string]$what, [string]$retry, [scriptblock]$command) {
    $global:LASTEXITCODE = 0
    & $command
    if ($LASTEXITCODE) {
        Write-Host "   failed: $what (exit code $LASTEXITCODE)" -ForegroundColor Red
        $failed.Add("$what did not finish (exit code $LASTEXITCODE). Retry: $retry")
    }
}

if ($Apps) {
    Step 'apps (winget import): this can take several minutes; Windows may ask for permission'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $import = Join-Path ([IO.Path]::GetTempPath()) "dev-starter-winget-$PID.json"
        Get-WingetImport "$here\winget.json" @($config.winget) | Set-Content $import
        try {
            # winget import exits nonzero when any one app failed; the others are still installed.
            # --no-upgrade: an installed app is left alone; it may be the Terminal or pwsh running this.
            Invoke-Native 'Installing apps with winget' $rerun {
                winget import -i $import --accept-package-agreements --accept-source-agreements --ignore-unavailable --no-upgrade
            }
        } finally { Remove-Item $import -ErrorAction SilentlyContinue }
        Update-SessionPath
    } else {
        $failed.Add("winget is not available, so no apps were installed. Install `"App Installer`" from the Microsoft Store, then $rerun")
    }

    # One Python source: uv. Its python.exe goes in ~/.local/bin; no python.org installer, no Store aliases.
    $uv = Get-Command uv -ErrorAction SilentlyContinue
    $uv = $uv ? $uv.Source : "$env:LOCALAPPDATA\Microsoft\WinGet\Links\uv.exe"
    if (Test-Path $uv) {
        Invoke-Native 'Installing Python with uv' $rerun { & $uv python install 3.13 --default }
        # winget's uv does not put ~/.local/bin on PATH, so `python` would still open the Store alias
        if (-not $sandbox) { Invoke-Native 'Adding Python to PATH' $rerun { & $uv python update-shell } }
    }
    else { $failed.Add("uv was not found after installing apps. Close this window, then $rerun") }
}

if ($Tools) {
    Step 'optional CLI tools (tools.ps1)'
    Invoke-Native 'Optional tools' '.\tools.ps1 (or -Only <tool>)' { & pwsh -NoProfile -File "$here\tools.ps1" }
}

Step 'PowerShell profile: profile.ps1 -> $PROFILE'
Write-IfChanged $profilePath (Get-Content "$here\profile.ps1" -Raw) | Out-Null

# Claude Code reads every CLAUDE.md from its working directory up, so one at $DEV covers every repo
# under it; tools that read AGENTS.md only from their working directory find the copy next to it.
Step "agent rules -> $env:DEV"
Write-IfChanged "$env:DEV\AGENTS.md" (Get-Content "$here\AGENTS.md" -Raw) | Out-Null
Write-IfChanged "$env:DEV\CLAUDE.md" "@AGENTS.md`n" | Out-Null

$hasGit = [bool](Get-Command git -ErrorAction SilentlyContinue)
if (-not $hasGit) { $failed.Add("Git is not installed, so git identity and hooks were skipped. Retry: $rerun") }

if ($hasGit) {
    Step 'git: identity'
    $GitName = $GitName ? $GitName : $config.git.name
    $GitEmail = $GitEmail ? $GitEmail : $config.git.email
    $currentName = "$(git config --global user.name)".Trim()
    $currentEmail = "$(git config --global user.email)".Trim()
    # Asked only when nothing is set yet; Enter skips, and the summary says how to set it later.
    if (-not [Console]::IsInputRedirected) {
        if (-not $GitName -and -not $currentName) { $GitName = (Read-Host '   Your name for git commits (Enter = skip)').Trim() }
        if (-not $GitEmail -and -not $currentEmail) { $GitEmail = (Read-Host '   Your email for git commits (Enter = skip)').Trim() }
    }
    foreach ($key in @{ Name = 'user.name'; Value = $GitName; Current = $currentName }, @{ Name = 'user.email'; Value = $GitEmail; Current = $currentEmail }) {
        if ($key.Value -and $key.Value -ne $key.Current) {
            Invoke-Native "Setting git $($key.Name)" ".\setup.ps1 -GitName `"Your Name`" -GitEmail `"your email`"" { git config --global $key.Name $key.Value }
        } elseif (-not $key.Value -and -not $key.Current) {
            $notes.Add("git $($key.Name) is not set yet (needed before your first commit): git config --global $($key.Name) `"...`"")
        }
    }
}

# The same global rules for every agent that reads a user-level instructions file.
Step 'agents: global instructions (Claude, Codex, Gemini, OpenCode)'
$name = $config.name ?? ($hasGit ? "$(git config --global user.name)".Trim() : '')
$rules = Get-Rules (Get-Content "$here\claude-global.md" -Raw) ($name ? $name : $env:USERNAME) ($env:AGENT_LANGUAGE ?? 'English') $overlayDir
foreach ($target in "$userHome\.claude\CLAUDE.md", "$userHome\.codex\AGENTS.md", "$userHome\.gemini\GEMINI.md",
                    "$userHome\.config\opencode\AGENTS.md") {
    Write-IfChanged $target $rules | Out-Null
}

Step 'Claude Code: no co-author, PR or session lines'
try { Set-ClaudeAttribution "$userHome\.claude\settings.json" | Out-Null }
catch {
    $message = $_.Exception.Message.TrimEnd('.')
    Write-Host "   failed: $message" -ForegroundColor Red
    $failed.Add("Claude Code attribution was not set: $message. Retry: .\setup.ps1")
}

# Settings only stop what Claude Code adds itself; this hook also strips AI credit
# lines that any tool writes into a commit message, then runs the repo's own hook.
if ($hasGit) {
    Step 'git: global commit-msg hook'
    $hooks = "$userHome\.config\git\hooks"
    function Write-Hook($source, $name) {
        # sh wants LF; a Windows checkout may have turned the hooks into CRLF.
        Write-IfChanged "$hooks\$name" ((Get-Content -Raw "$here\$source") -replace "`r`n", "`n") | Out-Null
    }
    Write-Hook 'commit-msg' 'commit-msg'
    # The receive hooks keep a push-to-deploy repository on this PC deploying. Left out:
    # reference-transaction and post-index-change, which would start sh on every ref update and
    # index write, and push-to-checkout, whose mere presence makes git skip its own
    # updateInstead checkout, so a forwarder with no repository hook leaves the working tree stale.
    foreach ($name in 'applypatch-msg', 'pre-applypatch', 'post-applypatch', 'pre-commit', 'pre-merge-commit',
                      'prepare-commit-msg', 'post-commit', 'pre-rebase', 'post-checkout', 'post-merge',
                      'post-rewrite', 'pre-auto-gc', 'pre-receive', 'update', 'post-receive', 'post-update',
                      'proc-receive', 'sendemail-validate') {
        Write-Hook 'forward-hook' $name
    }
    # pre-push is the one forwarding hook that also runs the lint CI runs first (it still hands over)
    Write-Hook 'pre-push' 'pre-push'
    $hooksPath = $hooks -replace '\\', '/'
    $currentHooks = "$(git config --global core.hooksPath)".Trim()
    if ($currentHooks -ne $hooksPath) {
        if ($currentHooks) { Write-Warning "core.hooksPath was $currentHooks; it now points at $hooksPath" }
        Invoke-Native 'Setting the git hooks folder' $rerun { git config --global core.hooksPath $hooksPath }
    }
}

Step 'Windows Terminal: settings.json'
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wt) {
    Write-IfChanged "$wt\settings.json" (Expand-TerminalSettings (Get-Content "$here\terminal\settings.json" -Raw) $here) | Out-Null
} else { Write-Host '   Windows Terminal has not been started yet; skipped (open Windows Terminal once, then double-click START.cmd again)' }

if ($overlayDir) {
    Step "overlay hooks: $overlayDir\setup.d"
    foreach ($result in Invoke-OverlayHooks $overlayDir | Where-Object Code) {
        Write-Host "   failed: $($result.Name) (exit code $($result.Code))" -ForegroundColor Red
        $failed.Add("Overlay hook $($result.Name) failed (exit code $($result.Code)). Retry: .\setup.ps1")
    }
}

Write-Host ''
if ($failed.Count) {
    Write-Host "Finished, but $($failed.Count) step(s) did not complete. Everything else is set up." -ForegroundColor Yellow
    Write-Host 'Running the same thing again is safe: finished steps are skipped and only these are retried.' -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
} else {
    Write-Host 'All steps finished.' -ForegroundColor Green
}
$notes | ForEach-Object { Write-Host "  - $_" }
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Close this window and open a new Windows Terminal, so newly installed programs are found.'
Write-Host '  2. Sign in to GitHub (opens your browser):  gh auth login'
Write-Host '  3. Install Claude Code:  irm https://claude.ai/install.ps1 | iex'
Write-Host '     Then run  claude  in your project folder and sign in in the browser it opens.'
Write-Host "  4. Your projects folder is $env:DEV  (open it in VS Code with:  code `$env:DEV)"
Write-Host '  5. What was changed and how to undo it: START-HERE.ko.md'
if ($failed.Count) { exit 1 }
