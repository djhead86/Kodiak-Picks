# ============================================================
#  Kodiak Picks — Installer for Windows (PowerShell)
#  https://github.com/beerforblood/kodiak-picks
#
#  Run this script in PowerShell:
#    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#    .\install.ps1
# ============================================================

$RepoUrl    = "https://github.com/beerforblood/kodiak-picks"
$InstallDir = "kodiak-picks"
$MinNode    = 20

# ── Colors / helpers ─────────────────────────────────────────
function Write-Ok   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  --> $msg" -ForegroundColor Cyan }
function Write-Warn { param($msg) Write-Host "  [!] $msg"  -ForegroundColor Yellow }
function Write-Hr   { Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray }
function Write-Die  {
  param($msg)
  Write-Host "`n  [ERROR] $msg`n" -ForegroundColor Red
  Read-Host "  Press Enter to exit"
  exit 1
}

# ── Banner ───────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "  ██╗  ██╗ ██████╗ ██████╗ ██╗ █████╗ ██╗  ██╗" -ForegroundColor Cyan
Write-Host "  ██║ ██╔╝██╔═══██╗██╔══██╗██║██╔══██╗██║ ██╔╝" -ForegroundColor Cyan
Write-Host "  █████╔╝ ██║   ██║██║  ██║██║███████║█████╔╝ " -ForegroundColor Cyan
Write-Host "  ██╔═██╗ ██║   ██║██║  ██║██║██╔══██║██╔═██╗ " -ForegroundColor Cyan
Write-Host "  ██║  ██╗╚██████╔╝██████╔╝██║██║  ██║██║  ██╗" -ForegroundColor Cyan
Write-Host "  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PICKS  —  Sports Betting Tracker" -ForegroundColor White
Write-Host "  Tracks bets, CLV, ROI, and AI-powered picks" -ForegroundColor DarkGray
Write-Host ""
Write-Hr
Write-Host ""

# ── Step 1: Prerequisites ────────────────────────────────────
Write-Host "  [1/5] Checking prerequisites" -ForegroundColor White
Write-Host ""

# git
try {
  $gitVer = (git --version 2>&1)
  Write-Ok $gitVer
} catch {
  Write-Host ""
  Write-Warn "git not found."
  Write-Host ""
  Write-Host "  Install git for Windows from:" -ForegroundColor Cyan
  Write-Host "  https://git-scm.com/download/win" -ForegroundColor Cyan
  Write-Host ""
  Write-Host "  Or via winget:" -ForegroundColor DarkGray
  Write-Host "  winget install --id Git.Git -e --source winget" -ForegroundColor DarkGray
  Write-Host ""
  Write-Die "Please install git and re-run this script."
}

# Node.js
try {
  $nodeVerFull = (node --version 2>&1)
  $nodeVerNum  = [int]($nodeVerFull -replace 'v(\d+)\..*', '$1')

  if ($nodeVerNum -lt $MinNode) {
    Write-Host ""
    Write-Warn "Node.js $MinNode+ required. You have $nodeVerFull."
    Write-Host ""
    Write-Host "  Download the latest LTS from https://nodejs.org" -ForegroundColor Cyan
    Write-Host "  Or via winget:" -ForegroundColor DarkGray
    Write-Host "  winget install OpenJS.NodeJS.LTS" -ForegroundColor DarkGray
    Write-Host ""
    Write-Die "Please upgrade Node.js and re-run this script."
  }

  Write-Ok "Node.js $nodeVerFull"
  Write-Ok "npm $(npm --version)"
} catch {
  Write-Host ""
  Write-Warn "Node.js not found."
  Write-Host ""
  Write-Host "  Download from https://nodejs.org (LTS version recommended)" -ForegroundColor Cyan
  Write-Host "  Or via winget:" -ForegroundColor DarkGray
  Write-Host "  winget install OpenJS.NodeJS.LTS" -ForegroundColor DarkGray
  Write-Host ""
  Write-Die "Please install Node.js $MinNode+ and re-run this script."
}

Write-Host ""

# ── Step 2: Clone or locate repo ────────────────────────────
Write-Host "  [2/5] Setting up project files" -ForegroundColor White
Write-Host ""

# Detect if we're already inside the project folder
$AlreadyInside = (Test-Path "package.json") -and ((Get-Content "package.json" -Raw) -match '"name": "kodiak-picks"')

if ($AlreadyInside) {
  Write-Ok "Already inside the Kodiak Picks directory"
  $ProjectDir = (Get-Location).Path
} elseif (Test-Path $InstallDir) {
  Write-Info "Found existing '$InstallDir' folder — pulling latest updates..."
  Set-Location $InstallDir
  git pull --quiet
  Write-Ok "Updated to latest version"
  $ProjectDir = (Get-Location).Path
} else {
  Write-Info "Cloning Kodiak Picks..."
  git clone --quiet $RepoUrl $InstallDir
  if ($LASTEXITCODE -ne 0) { Write-Die "Could not clone repo. Check your internet connection." }
  Set-Location $InstallDir
  Write-Ok "Cloned successfully"
  $ProjectDir = (Get-Location).Path
}

Write-Host ""

# ── Step 3: API Keys ─────────────────────────────────────────
Write-Host "  [3/5] API Key Setup" -ForegroundColor White
Write-Host ""
Write-Host "  Kodiak Picks connects to a couple of free/cheap APIs." -ForegroundColor Gray
Write-Host "  Your keys are stored LOCALLY ONLY -- never sent anywhere else." -ForegroundColor Gray
Write-Host ""
Write-Hr

$SkipKeys = $false

if (Test-Path ".env.local") {
  Write-Host ""
  Write-Warn ".env.local already exists."
  $overwrite = Read-Host "  Overwrite with new keys? [y/N]"
  if ($overwrite -notmatch '^[Yy]$') {
    Write-Info "Keeping existing .env.local -- skipping key setup."
    $SkipKeys = $true
  }
}

if (-not $SkipKeys) {

  # The Odds API
  Write-Host ""
  Write-Host "  1. The Odds API  (required)" -ForegroundColor Cyan
  Write-Host "  Free tier -- up to 500 requests/month. Sign up at:" -ForegroundColor DarkGray
  Write-Host "  https://the-odds-api.com" -ForegroundColor DarkGray
  $OddsApiKey = ""
  while ([string]::IsNullOrWhiteSpace($OddsApiKey)) {
    $OddsApiKey = Read-Host "  Paste your key"
    if ([string]::IsNullOrWhiteSpace($OddsApiKey)) {
      Write-Warn "This key is required for live odds data."
    }
  }

  # Anthropic
  Write-Host ""
  Write-Host "  2. Anthropic API Key  (optional -- for AI bet suggestions)" -ForegroundColor Cyan
  Write-Host "  Get one at https://console.anthropic.com -- pay-per-use, very cheap." -ForegroundColor DarkGray
  Write-Host "  Leave blank to disable AI features." -ForegroundColor DarkGray
  $AnthropicKey = Read-Host "  Paste your key (or Enter to skip)"

  # Stock features
  Write-Host ""
  Write-Hr
  Write-Host ""
  Write-Host "  Stock Portfolio Features  (all optional -- press Enter to skip)" -ForegroundColor White
  Write-Host ""
  Write-Host "  Polygon.io API key (live stock prices): https://polygon.io" -ForegroundColor DarkGray
  $PolygonKey = Read-Host "  Key"

  Write-Host ""
  Write-Host "  Financial Modeling Prep (stock fundamentals): https://financialmodelingprep.com" -ForegroundColor DarkGray
  $FmpKey = Read-Host "  Key"

  # Write .env.local
  Write-Host ""
  Write-Info "Writing .env.local..."

  $envContent = @"
# ── Kodiak Picks — Environment Configuration ─────────────────
# Generated by install.ps1 on $(Get-Date)
# Do NOT share this file -- it contains your private API keys.

# Required: Live odds data
ODDS_API_KEY=$OddsApiKey

# Optional: AI-powered bet suggestions (Claude)
ANTHROPIC_API_KEY=$AnthropicKey

# Optional: Stock portfolio features
POLYGON_API_KEY=$PolygonKey
FMP_API_KEY=$FmpKey

# Database path (default: local file)
DB_PATH=./kodiak.db

# LLM analysis feature toggle
ENABLE_LLM_ANALYSIS=true
"@

  Set-Content -Path ".env.local" -Value $envContent -Encoding UTF8
  Write-Ok ".env.local written"
}

Write-Host ""

# ── Step 4: Install & Build ──────────────────────────────────
Write-Host "  [4/5] Installing dependencies & building" -ForegroundColor White
Write-Host ""
Write-Info "Running npm install..."
npm install --silent
if ($LASTEXITCODE -ne 0) { Write-Die "npm install failed. Check the errors above." }
Write-Ok "Dependencies installed"

Write-Host ""
Write-Info "Building production app (this takes ~30 seconds)..."
npm run build
if ($LASTEXITCODE -ne 0) { Write-Die "Build failed. Check the errors above." }
Write-Ok "Build complete"

Write-Host ""

# ── Step 5: Create startup shortcut ─────────────────────────
Write-Host "  [5/5] Creating startup shortcut" -ForegroundColor White
Write-Host ""

$StartScript = Join-Path $ProjectDir "Start Kodiak Picks.bat"

@"
@echo off
title Kodiak Picks
echo.
echo  Starting Kodiak Picks...
echo  Open http://localhost:3000 in your browser.
echo.
cd /d "%~dp0"
start "" "http://localhost:3000"
npm start
pause
"@ | Set-Content -Path $StartScript -Encoding ASCII

Write-Ok "Created 'Start Kodiak Picks.bat' -- double-click it anytime to launch"

# ── Done ─────────────────────────────────────────────────────
Write-Host ""
Write-Hr
Write-Host ""
Write-Host "  All done! Kodiak Picks is ready." -ForegroundColor Green
Write-Host ""
Write-Host "  To start the app:" -ForegroundColor White
Write-Host "  * Double-click 'Start Kodiak Picks.bat' in File Explorer" -ForegroundColor Cyan
Write-Host "  * Or run: npm start  in this folder" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Then open http://localhost:3000 in your browser." -ForegroundColor White
Write-Host ""
Write-Host "  To update later, run this installer again -- it will pull the latest version." -ForegroundColor DarkGray
Write-Host ""
Write-Hr
Write-Host ""
Read-Host "  Press Enter to exit"
