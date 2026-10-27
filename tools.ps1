# Install or update the optional command-line tools that winget does not carry: the small, stable core
# list in tools.json (codigest, deai) plus any an overlay adds. Off by default: setup.ps1 runs this
# only with -Tools. Safe to run again:
# an installed tool is left alone unless -Update is given, and -Update only touches a copy this
# script would have installed (a cargo or hand-made install is reported, not replaced).
#   .\tools.ps1                     install the missing tools, then print a status table
#   .\tools.ps1 -Update             also update the installed ones
#   .\tools.ps1 -Only codigest,deai just these
#   .\tools.ps1 -DryRun             print what would run, change nothing
param(
    [string[]]$Only,
    [switch]$Update,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'

# The catalogue is tools.json plus the "tools" list of the overlay's config.json (DEVSTARTER_OVERLAY);
# an overlay entry with the name of a catalogue entry replaces it. Each entry is the tool's own
# documented install path:
#   Kind uv      Package (PyPI name or git URL), Command, Names (tool names an existing uv install may use)
#   Kind gh      Repo (owner/name of a gh extension), Extension
#   Kind script  Url (an install.ps1), Command, Dir (where it installs), UninstallArgs (when the script can uninstall)
# uv and gh check what they download; release installers are expected to verify what they download.
$tools = [ordered]@{}
$sources = @(Join-Path $PSScriptRoot 'tools.json')
if ($env:DEVSTARTER_OVERLAY) { $sources += Join-Path $env:DEVSTARTER_OVERLAY 'config.json' }
foreach ($source in $sources | Where-Object { Test-Path -LiteralPath $_ }) {
    $data = Get-Content -LiteralPath $source -Raw | ConvertFrom-Json
    foreach ($tool in ($source -like '*config.json' ? $data.tools : $data) | Where-Object { $_ }) {
        if ($tool.Dir) { $tool.Dir = [Environment]::ExpandEnvironmentVariables($tool.Dir) }
        $tools[$tool.Name] = $tool
    }
}
$tools = @($tools.Values)

function Get-UvToolDir { $env:UV_TOOL_DIR ? $env:UV_TOOL_DIR : (Join-Path $env:APPDATA 'uv\tools') }

function Get-UvToolName($tool) {
    @($tool.Names ?? $tool.Package) | Where-Object { Test-Path (Join-Path (Get-UvToolDir) $_) } | Select-Object -First 1
}

# What is installed: Version, Where, and whether this script manages that copy.
function Get-State($tool) {
    if ($tool.Kind -eq 'gh') {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { return $null }
        $line = gh extension list 2>$null | Where-Object { $_ -match [regex]::Escape($tool.Repo) } | Select-Object -First 1
        if (-not $line) { return $null }
        $version = ($line -split '\s+' | Where-Object { $_ -match '^v?\d' } | Select-Object -Last 1) ?? '?'
        return [pscustomobject]@{ Version = $version; Where = "gh extension $($tool.Repo)"; Managed = $true }
    }
    $cmd = Get-Command $tool.Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd -and $tool.Kind -eq 'script') {
        # a fresh install is on the user PATH only for new terminals
        $cmd = Get-Command (Join-Path $tool.Dir "$($tool.Command).exe") -CommandType Application -ErrorAction SilentlyContinue
    }
    if (-not $cmd) { return $null }
    $version = "$(& $cmd.Source --version 2>$null)".Trim()
    if ($LASTEXITCODE -ne 0 -or -not $version) { $version = '?' }
    $managed = switch ($tool.Kind) {
        'uv' { [bool](Get-UvToolName $tool) }
        'script' { (Split-Path $cmd.Source) -ieq $tool.Dir }
    }
    [pscustomobject]@{ Version = $version; Where = $cmd.Source; Managed = $managed }
}

# Runs a tool's installer script in its own process, so its exit code is seen and it cannot
# change this session's variables.
function Invoke-Installer([string]$url) {
    $script = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('n') + '.ps1')
    try {
        Invoke-WebRequest -UseBasicParsing $url -OutFile $script
        pwsh -NoProfile -ExecutionPolicy Bypass -File $script
    } finally { Remove-Item -Force $script -ErrorAction SilentlyContinue }
}

function Get-Plan($tool, [string]$action) {
    switch ($tool.Kind) {
        'uv' { if ($action -eq 'install') { "uv tool install $($tool.Package)" } else { "uv tool upgrade $(Get-UvToolName $tool)" } }
        'gh' { if ($action -eq 'install') { "gh extension install $($tool.Repo)" } else { "gh extension upgrade $($tool.Extension)" } }
        'script' { "Invoke-Installer $($tool.Url)" }
    }
}

function Get-Uninstall($tool) {
    switch ($tool.Kind) {
        'uv' { "uv tool uninstall $((Get-UvToolName $tool) ?? $tool.Package)" }
        'gh' { "gh extension remove $($tool.Extension)" }
        'script' {
            if ($tool.UninstallArgs) { "& ([scriptblock]::Create((irm $($tool.Url)))) $($tool.UninstallArgs)" }
            else { "Remove-Item -Recurse '$($tool.Dir)', then drop it from the user PATH" }
        }
    }
}

$prereq = @{ uv = 'uv'; gh = 'gh'; script = 'pwsh' }

$Only = $Only -split ','   # pwsh -File passes 'a,b' as one string
$selected = if ($Only) {
    $unknown = @($Only | Where-Object { $_ -notin $tools.Name })
    if ($unknown) { throw "unknown tool(s): $($unknown -join ', '); known: $($tools.Name -join ', ')" }
    $tools | Where-Object Name -in $Only
} else { $tools }

$results = foreach ($tool in $selected) {
    $before = Get-State $tool
    $action = if (-not $before) { 'install' } elseif (-not $Update) { 'keep' } elseif ($before.Managed) { 'update' } else { 'keep' }
    $status = 'ok'
    $detail = ($before -and $Update -and -not $before.Managed) ? 'not installed by this script; left as is' : ''
    if ($action -ne 'keep') {
        $plan = Get-Plan $tool $action
        if (-not (Get-Command $prereq[$tool.Kind] -ErrorAction SilentlyContinue)) {
            $status = 'failed'; $detail = "$($prereq[$tool.Kind]) is not installed (run .\setup.ps1 -Apps first)"
        } elseif ($DryRun) {
            $status = 'dry run'; $detail = "would run: $plan"
        } else {
            Write-Host "-> $action $($tool.Name): $plan" -ForegroundColor Cyan
            try {
                $global:LASTEXITCODE = 0
                Invoke-Expression $plan
                if ($LASTEXITCODE) { throw "exit code $LASTEXITCODE" }
            } catch {
                $status = 'failed'; $detail = "$_"
                # Windows cannot replace a program that is running (os error 32)
                $busy = @(Get-Process -Name $tool.Command, $tool.Name -ErrorAction SilentlyContinue)
                if ($busy) { $detail += " ($($tool.Command) is running as pid $($busy.Id -join ', '); close what uses it and retry)" }
            }
        }
    }
    $after = $DryRun ? $before : (Get-State $tool)
    [pscustomobject]@{
        Tool = $tool.Name; Action = $action; Status = $status
        Version = $after.Version; Where = $after.Where; Detail = $detail; Uninstall = Get-Uninstall $tool
    }
}

$results | Format-Table Tool, Action, Status, Version, Where -AutoSize | Out-Host
foreach ($r in $results | Where-Object Detail) {
    $color = $r.Status -eq 'failed' ? 'Red' : 'Gray'
    $retry = $r.Status -eq 'failed' ? " Retry: .\tools.ps1 -Only $($r.Tool)" : ''
    Write-Host "$($r.Tool): $($r.Detail).$retry" -ForegroundColor $color
}

# Two copies of one command (say a uv and a cargo codigest): the first on PATH wins silently, so name them.
foreach ($tool in $selected | Where-Object Command) {
    $copies = @(Get-Command $tool.Command -All -CommandType Application -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -Unique)
    if ($copies.Count -gt 1) {
        Write-Warning "more than one $($tool.Command) on PATH: $($copies -join ', '); the first one runs. Keep one (uninstall: $(Get-Uninstall $tool))"
    }
}
if (@($results | Where-Object Status -eq 'failed').Count) { exit 1 }
