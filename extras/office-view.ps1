# Keep the file a build writes apart from the file a person has open in Office.
#   .\office-view.ps1 publish <work.pptx> <view.pptx>   copy the work file to the view file
#   .\office-view.ps1 render  <deck.pptx> <outdir> [-Slides 1,3] [-Width 1600]
#   .\office-view.ps1 pdf     <deck.pptx> <out.pdf>
# publish: Office locks an open file, so a busy view file is never overwritten or skipped; the new
# version goes to the first free <view>_view2, _view3, ... instead, and the path is printed. Once the
# view file is free again, publish writes there and removes the extra copies that are not open.
# render: exports slides from a temporary copy, so the render never locks the work or view file.
# pdf: prints a temporary copy through PowerPoint's own print path to "Microsoft Print to PDF", so the
# PDF is what PowerPoint draws, then office-view-crop.py trims the paper's blank bands (CropBox only).
# A PDF that is open is not overwritten; the next free <out>_view2.pdf, ... is written instead.
# PowerPoint COM attaches to the running PowerPoint, so it is quit only if this script started it.
param(
    [Parameter(Mandatory, Position = 0)][ValidateSet('publish', 'render', 'pdf')][string]$Action,
    [Parameter(Mandatory, Position = 1)][string]$Source,
    [Parameter(Mandatory, Position = 2)][string]$Target,
    [int[]]$Slides,
    [int]$Width = 1600
)
$ErrorActionPreference = 'Stop'
$Source = (Resolve-Path $Source).Path

function Test-Locked([string]$Path) {
    if (-not (Test-Path $Path)) { return $false }
    try { [IO.File]::Open($Path, 'Open', 'ReadWrite', 'None').Dispose(); $false } catch [IO.IOException] { $true }
}

function Copy-Atomic([string]$From, [string]$To) {
    $tmp = "$To.tmp$PID"
    Copy-Item -LiteralPath $From -Destination $tmp -Force
    Move-Item -LiteralPath $tmp -Destination $To -Force
}

# Writes $From to $To, or to the first free <To>_viewN when $To is open; removes free extras.
function Publish-View([string]$From, [string]$To) {
    $To = [IO.Path]::GetFullPath($To)
    $dir, $stem, $ext = [IO.Path]::GetDirectoryName($To), [IO.Path]::GetFileNameWithoutExtension($To), [IO.Path]::GetExtension($To)
    $extras = @(Get-ChildItem -LiteralPath $dir -Filter "${stem}_view*$ext" | Where-Object Name -Match "^$([regex]::Escape($stem))_view\d+$([regex]::Escape($ext))$")
    if (-not (Test-Locked $To)) {
        Copy-Atomic $From $To
        $extras | Where-Object { -not (Test-Locked $_.FullName) } | Remove-Item -Force
        "published: $To"
        return
    }
    foreach ($n in 2..99) {
        $spare = Join-Path $dir "${stem}_view$n$ext"
        if (Test-Locked $spare) { continue }
        Copy-Atomic $From $spare
        "published: $spare  ($([IO.Path]::GetFileName($To)) is open; close it and publish again to go back to that name)"
        return
    }
    throw "no free view name next to $To"
}

if ($Action -eq 'publish') {
    Publish-View $Source $Target
    return
}

if ($Action -eq 'render') { New-Item -ItemType Directory -Force $Target | Out-Null }
$copy = Join-Path ([IO.Path]::GetTempPath()) "office-view-$PID$([IO.Path]::GetExtension($Source))"
Copy-Item -LiteralPath $Source -Destination $copy -Force
$wasRunning = [bool](Get-Process POWERPNT -ErrorAction SilentlyContinue)
# A PowerPoint that is still starting answers CO_E_SERVER_EXEC_FAILURE; it succeeds a few seconds later.
foreach ($try in 1..3) {
    try { $app = New-Object -ComObject PowerPoint.Application; break } catch {
        if ($try -lt 3) { Start-Sleep -Seconds 3; continue }
        Remove-Item $copy -Force
        throw "PowerPoint COM is not available ($($_.Exception.Message))."
    }
}
$printed = Join-Path ([IO.Path]::GetTempPath()) "office-view-$PID-printed.pdf"
try {
    $pres = $app.Presentations.Open($copy, $true, $false, $false)
    $slideW, $slideH = $pres.PageSetup.SlideWidth, $pres.PageSetup.SlideHeight
    if ($Action -eq 'render') {
        $height = [int]($Width * $slideH / $slideW)
        foreach ($n in ($Slides ?? 1..$pres.Slides.Count)) {
            $png = Join-Path (Resolve-Path $Target) ('s{0:d2}.png' -f $n)
            $pres.Slides($n).Export($png, 'PNG', $Width, $height)
            $png
        }
    } else {
        $print = $pres.PrintOptions
        $print.ActivePrinter = 'Microsoft Print to PDF'
        $print.PrintInBackground = $false
        $print.OutputType = 1   # ppPrintOutputSlides
        $print.FitToPage = $true
        $print.PrintHiddenSlides = $false
        $pres.PrintOut(1, $pres.Slides.Count, $printed)
    }
    $pres.Close()
} finally {
    if (-not $wasRunning) { $app.Quit() }
    [void][Runtime.InteropServices.Marshal]::ReleaseComObject($app)
    Remove-Item $copy -Force -ErrorAction SilentlyContinue
}
if ($Action -eq 'pdf') {
    # the spooler finishes the file after PrintOut returns
    $deadline = (Get-Date).AddSeconds(60)
    while (-not ((Test-Path $printed) -and -not (Test-Locked $printed) -and (Get-Item $printed).Length -gt 0)) {
        if ((Get-Date) -gt $deadline) { throw "Microsoft Print to PDF wrote nothing to $printed" }
        Start-Sleep -Milliseconds 300
    }
    $trimmed = "$printed.trim.pdf"
    try {
        # 3.13 is the setup.ps1 Python; pymupdf ships no free-threaded (3.14t) wheel
        uv run --quiet --python 3.13 --script (Join-Path $PSScriptRoot 'office-view-crop.py') $printed $trimmed $slideW $slideH
        if ($LASTEXITCODE) { throw "office-view-crop.py failed ($LASTEXITCODE)" }
        Publish-View $trimmed $Target
    } finally {
        Remove-Item $printed, $trimmed -Force -ErrorAction SilentlyContinue
    }
}
