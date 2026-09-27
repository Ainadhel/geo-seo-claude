#Requires -Version 5.1
<#
.SYNOPSIS
    GEO-SEO Claude bootstrap for Windows / PowerShell (OpenCode port).

.DESCRIPTION
    Prepares this working folder in place. It does NOT install anything into
    $HOME or any other directory outside the repository: the skills already sit
    where OpenCode reads them (.agents\skills\), so there is nothing to copy.

    Creates:
      .\.venv\                          project-local virtual environment
      .\.data\geo-prospects\            prospect / proposal / CRM state
      .\.data\geo-prospects\audits\
      .\.data\geo-prospects\proposals\
      .\.data\geo-prospects\reports\

    The venv interpreter is .\.venv\Scripts\python.exe (NOT bin/python3), and
    that is the exact path the skills and agent files reference.

.EXAMPLE
    .\install-win.ps1
    .\install-win.ps1 -InstallPlaywright
    .\install-win.ps1 -Force          # rebuild the venv from scratch
#>
[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipPlaywright,
    [switch]$InstallPlaywright
)

$ErrorActionPreference = 'Stop'

$RepoRoot  = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir   = Join-Path $RepoRoot '.venv'
$VenvPy    = Join-Path $VenvDir 'Scripts\python.exe'
$DataDir   = Join-Path $RepoRoot '.data\geo-prospects'
$ReqFile   = Join-Path $RepoRoot 'requirements.txt'
$UvExe     = Join-Path $env:LOCALAPPDATA 'hermes\bin\uv.exe'

function Write-Step  { param($m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok    { param($m) Write-Host "  [OK]   $m" -ForegroundColor Green }
function Write-Warn2 { param($m) Write-Host "  [warn] $m" -ForegroundColor Yellow }
function Write-Fail  { param($m) Write-Host "  [FAIL] $m" -ForegroundColor Red }

Write-Host ''
Write-Host '+--------------------------------------------------+' -ForegroundColor Blue
Write-Host '|   GEO-SEO OpenCode bootstrap (Windows)            |' -ForegroundColor Blue
Write-Host '|   Local working folder, nothing global installed  |' -ForegroundColor Blue
Write-Host '+--------------------------------------------------+' -ForegroundColor Blue
Write-Host "  Repository: $RepoRoot"
Write-Host ''

# ---------------------------------------------------------------- Python ----
Write-Step 'Checking prerequisites'

$PythonCmd = $null
foreach ($candidate in @('py', 'python', 'python3')) {
    $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
    if (-not $resolved) { continue }
    try {
        $ver = & $candidate -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
    } catch { continue }
    if ($ver -and [int]($ver.Split('.')[0]) -ge 3 -and [int]($ver.Split('.')[1]) -ge 8) {
        $PythonCmd = $candidate
        $PythonVersion = $ver
        break
    }
}
if (-not $PythonCmd) {
    Write-Fail 'Python 3.8+ is required but was not found on PATH.'
    Write-Host '  Install: https://www.python.org/downloads/ (tick "Add Python to PATH")'
    exit 1
}
Write-Ok "Python $PythonVersion ($PythonCmd)"

$UseUv = $false
if (Test-Path -LiteralPath $UvExe) { $UseUv = $true }
elseif (Get-Command uv -ErrorAction SilentlyContinue) { $UseUv = $true }
if ($UseUv) { Write-Ok 'uv detected, using it for the venv' }
else        { Write-Ok 'uv not found, falling back to stdlib venv' }

# ------------------------------------------------------------------ venv ----
if ($Force -and (Test-Path -LiteralPath $VenvDir)) {
    Write-Step 'Removing the existing virtual environment (-Force)'
    Remove-Item -Recurse -Force -LiteralPath $VenvDir
}

if (-not (Test-Path -LiteralPath $VenvPy)) {
    Write-Step "Creating the virtual environment at $VenvDir"
    if ($UseUv) {
        & uv venv $VenvDir --python $PythonCmd --quiet
    } else {
        & $PythonCmd -m venv $VenvDir
    }
    if ($LASTEXITCODE -ne 0) { Write-Fail 'venv creation failed.'; exit 1 }
    Write-Ok 'Virtual environment created'
} else {
    Write-Ok 'Virtual environment already present (use -Force to rebuild)'
}

# ---------------------------------------------------------- dependencies ----
Write-Step 'Installing Python dependencies into the venv'
if (-not (Test-Path -LiteralPath $ReqFile)) {
    Write-Warn2 'requirements.txt not found, skipping.'
} else {
    if ($UseUv) {
        & uv pip install --python $VenvPy -r $ReqFile --quiet
    } else {
        & $VenvPy -m pip install --upgrade pip --quiet
        & $VenvPy -m pip install -r $ReqFile --quiet
    }
    if ($LASTEXITCODE -ne 0) { Write-Fail 'Dependency install failed.'; exit 1 }
    Write-Ok "Dependencies installed (isolated, nothing on the system Python)"
}

# pytest: the test suite is pytest-style, unittest discover does not collect it.
Write-Step 'Installing pytest into the venv'
if ($UseUv) { & uv pip install --python $VenvPy pytest --quiet }
else        { & $VenvPy -m pip install pytest --quiet }
if ($LASTEXITCODE -ne 0) { Write-Fail 'pytest install failed.'; exit 1 }
Write-Ok 'pytest installed'

# ------------------------------------------------------------- data dir ----
Write-Step 'Creating the local prospect data directory'
foreach ($sub in @($DataDir, (Join-Path $DataDir 'audits'), (Join-Path $DataDir 'proposals'), (Join-Path $DataDir 'reports'))) {
    New-Item -ItemType Directory -Force -Path $sub | Out-Null
}
Write-Ok "$DataDir (git-ignored, holds client data, never auto-deleted)"

# ------------------------------------------------------------ playwright ----
if ($InstallPlaywright -and -not $SkipPlaywright) {
    Write-Step 'Installing Playwright Chromium into the venv'
    & $VenvPy -m playwright install chromium
    if ($LASTEXITCODE -ne 0) {
        Write-Warn2 "Playwright install failed, screenshots will be unavailable. Retry: $VenvPy -m playwright install chromium"
    } else { Write-Ok 'Playwright Chromium installed' }
} else {
    Write-Host "  [skip] Playwright. Install later with: $VenvPy -m playwright install chromium"
}

# ------------------------------------------------------------- verify ------
Write-Host ''
Write-Step 'Verifying'

$Checks = @(
    @{ Label = 'Venv interpreter';        Path = $VenvPy },
    @{ Label = 'Orchestrator skill';      Path = (Join-Path $RepoRoot '.agents\skills\geo\SKILL.md') },
    @{ Label = 'Sub-skills directory';    Path = (Join-Path $RepoRoot '.agents\skills\geo-audit') },
    @{ Label = 'Agents directory';        Path = (Join-Path $RepoRoot 'agents') },
    @{ Label = 'Utility scripts';         Path = (Join-Path $RepoRoot 'scripts') },
    @{ Label = 'Schema templates';        Path = (Join-Path $RepoRoot 'schema') },
    @{ Label = 'Report templates';        Path = (Join-Path $RepoRoot 'templates\geo-report-template.html') },
    @{ Label = 'Prospect data directory'; Path = $DataDir }
)

$AllOk = $true
foreach ($c in $Checks) {
    if (Test-Path -LiteralPath $c.Path) { Write-Ok $c.Label }
    else { Write-Fail "$($c.Label) missing: $($c.Path)"; $AllOk = $false }
}

$SkillCount = @(Get-ChildItem -Path (Join-Path $RepoRoot '.agents\skills') -Directory -Filter 'geo-*').Count
$AgentCount = @(Get-ChildItem -Path (Join-Path $RepoRoot 'agents') -Filter 'geo-*.md' -File).Count
Write-Ok "Sub-skills: $SkillCount, agents: $AgentCount"

# ---------------------------------------------------------------- done -----
Write-Host ''
if (-not $AllOk) { Write-Warn2 'Some checks failed, see above.' }
Write-Host '+--------------------------------------------------+' -ForegroundColor Green
Write-Host '|   Bootstrap complete                             |' -ForegroundColor Green
Write-Host '+--------------------------------------------------+' -ForegroundColor Green
Write-Host ''
Write-Host "  Venv interpreter : $VenvPy"
Write-Host "  Prospect data    : $DataDir"
Write-Host ''
Write-Host '  Run the test suite:'
Write-Host "    $VenvPy -m pytest tests\ -q"
Write-Host ''
Write-Host '  Run a script against a real URL:'
Write-Host "    $VenvPy scripts\fetch_page.py https://example.com"
Write-Host ''
Write-Host '  Then, in OpenCode: /geo quick https://example.com'
Write-Host ''
exit 0
