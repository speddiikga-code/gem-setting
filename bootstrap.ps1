# Started by START.cmd under the stock Windows PowerShell 5.1, so this file keeps to 5.1 syntax and ASCII.
# Removes the download mark from the kit's files, installs PowerShell 7 with winget when it is missing,
# then runs setup.ps1 -Apps under PowerShell 7. Extra arguments are passed on to setup.ps1.
$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot

Write-Host 'dev-starter: setting up this PC' -ForegroundColor Cyan

# Files extracted from a downloaded zip carry the internet mark, which blocks the scripts setup.ps1 starts itself.
Get-ChildItem -LiteralPath $here -Recurse -File | Unblock-File

# Installers put their folders on the machine and user PATH after this shell started; appended, so what
# is already first on PATH stays first.
function Update-SessionPath {
    $known = $env:PATH -split ';'
    $new = foreach ($scope in 'Machine', 'User') {
        [Environment]::GetEnvironmentVariable('PATH', $scope) -split ';' | Where-Object { $_ -and $_ -notin $known }
    }
    if ($new) { $env:PATH = (@($env:PATH) + $new) -join ';' }
}

function Find-Pwsh {
    $cmd = Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { return $cmd.Source }
    # Windows resets ProgramFiles for every process, so a test sandbox (DEVSTARTER_SANDBOX) cannot hide this one
    if ($env:DEVSTARTER_SANDBOX) { return }
    $default = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
    if (Test-Path $default) { return $default }
}

$pwsh = Find-Pwsh
if (-not $pwsh) {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        # On a new PC winget is often installed but not registered for this user until the Store updates it.
        try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe } catch { }
        Update-SessionPath
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'winget is not available on this PC.' -ForegroundColor Red
        Write-Host 'Open the Microsoft Store, search for "App Installer", install or update it, then double-click START.cmd again.'
        exit 1
    }
    Write-Host '-> installing PowerShell 7 (Windows may ask for permission)' -ForegroundColor Cyan
    winget install --id Microsoft.PowerShell -e --source winget --accept-package-agreements --accept-source-agreements
    Update-SessionPath
    $pwsh = Find-Pwsh
    if (-not $pwsh) {
        Write-Host 'PowerShell 7 could not be installed.' -ForegroundColor Red
        Write-Host 'Double-click START.cmd again. If it fails again, run this in a terminal and read its message:'
        Write-Host '   winget install --id Microsoft.PowerShell -e --source winget'
        exit 1
    }
}

# Replies from coding agents in Korean unless the caller chose a language.
$setupArgs = @('-Apps') + $args
if (-not ($args -contains '-Language')) { $setupArgs += @('-Language', 'Korean') }
& $pwsh -NoProfile -ExecutionPolicy Bypass -File (Join-Path $here 'setup.ps1') @setupArgs
exit $LASTEXITCODE
