#!/usr/bin/env bash
# ============================================================
#  Kodiak Picks — Installer for macOS & Linux
#  https://github.com/beerforblood/kodiak-picks
# ============================================================

set -e

REPO_URL="https://github.com/beerforblood/kodiak-picks"
INSTALL_DIR="kodiak-picks"
MIN_NODE=20

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Helpers ──────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✔${NC}  $1"; }
info() { echo -e "  ${CYAN}→${NC}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
die()  { echo -e "\n  ${RED}✖  ERROR:${NC} $1\n"; exit 1; }

hr() { echo -e "${DIM}────────────────────────────────────────────────────${NC}"; }

prompt_key() {
  local label="$1"
  local hint="$2"
  local var_name="$3"
  local optional="$4"

  echo ""
  echo -e "  ${BOLD}${label}${NC}"
  if [[ -n "$hint" ]]; then
    echo -e "  ${DIM}${hint}${NC}"
  fi
  if [[ "$optional" == "true" ]]; then
    echo -e "  ${DIM}(optional — press Enter to skip)${NC}"
  fi
  echo -n "  > "
  read -r value
  printf -v "$var_name" '%s' "$value"
}

# ── Banner ───────────────────────────────────────────────────
clear
echo ""
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
  ██╗  ██╗ ██████╗ ██████╗ ██╗ █████╗ ██╗  ██╗
  ██║ ██╔╝██╔═══██╗██╔══██╗██║██╔══██╗██║ ██╔╝
  █████╔╝ ██║   ██║██║  ██║██║███████║█████╔╝
  ██╔═██╗ ██║   ██║██║  ██║██║██╔══██║██╔═██╗
  ██║  ██╗╚██████╔╝██████╔╝██║██║  ██║██║  ██╗
  ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

  ██████╗ ██╗ ██████╗██╗  ██╗███████╗
  ██╔══██╗██║██╔════╝██║ ██╔╝██╔════╝
  ██████╔╝██║██║     █████╔╝ ███████╗
  ██╔═══╝ ██║██║     ██╔═██╗ ╚════██║
  ██║     ██║╚██████╗██║  ██╗███████║
  ╚═╝     ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝
BANNER
echo -e "${NC}"
echo -e "  ${BOLD}Sports Betting Tracker — Installer${NC}"
echo -e "  ${DIM}Tracks bets, CLV, ROI, and AI-powered picks${NC}"
echo ""
hr
echo ""

# ── Step 1: Check git ────────────────────────────────────────
echo -e "${BOLD}  [1/5] Checking prerequisites${NC}"
echo ""

if ! command -v git &> /dev/null; then
  die "git is not installed.\n\n  macOS:  brew install git  (or install Xcode Command Line Tools)\n  Linux:  sudo apt install git  /  sudo dnf install git"
fi
ok "git $(git --version | awk '{print $3}')"

# ── Step 2: Check Node.js ────────────────────────────────────
if ! command -v node &> /dev/null; then
  echo ""
  warn "Node.js not found. Please install Node.js ${MIN_NODE}+ and re-run this script."
  echo ""
  echo -e "  ${CYAN}Install options:${NC}"
  echo -e "  • macOS (Homebrew):   ${BOLD}brew install node${NC}"
  echo -e "  • Linux (NVM):        ${BOLD}curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash${NC}"
  echo -e "                        ${BOLD}nvm install ${MIN_NODE}${NC}"
  echo -e "  • Official installer: ${BOLD}https://nodejs.org${NC}"
  echo ""
  exit 1
fi

NODE_VER=$(node -e "console.log(process.versions.node.split('.')[0])")
if [[ "$NODE_VER" -lt "$MIN_NODE" ]]; then
  die "Node.js ${MIN_NODE}+ required. You have v$(node --version).\n  Get the latest at https://nodejs.org"
fi
ok "Node.js $(node --version)"
ok "npm $(npm --version)"
echo ""

# ── Step 3: Clone or locate the repo ────────────────────────
echo -e "${BOLD}  [2/5] Setting up project files${NC}"
echo ""

# Check if we're already inside the repo (script run from within the project)
if [[ -f "package.json" ]] && grep -q '"name": "kodiak-picks"' package.json 2>/dev/null; then
  ok "Already inside the Kodiak Picks directory"
  PROJECT_DIR="$(pwd)"
else
  if [[ -d "$INSTALL_DIR" ]]; then
    info "Found existing '$INSTALL_DIR' folder — pulling latest updates..."
    cd "$INSTALL_DIR"
    git pull --quiet
    ok "Updated to latest version"
  else
    info "Cloning Kodiak Picks..."
    git clone --quiet "$REPO_URL" "$INSTALL_DIR" || die "Could not clone repo. Check your internet connection."
    cd "$INSTALL_DIR"
    ok "Cloned successfully"
  fi
  PROJECT_DIR="$(pwd)"
fi

echo ""

# ── Step 4: API Keys ─────────────────────────────────────────
echo -e "${BOLD}  [3/5] API Key Setup${NC}"
echo ""
echo -e "  Kodiak Picks connects to a couple of free/cheap APIs."
echo -e "  Your keys are stored ${BOLD}locally only${NC} — never sent anywhere else."
echo ""
hr

# Check for existing .env.local
if [[ -f ".env.local" ]]; then
  echo ""
  warn ".env.local already exists."
  echo -n "  Overwrite with new keys? [y/N] "
  read -r overwrite
  if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
    info "Keeping existing .env.local — skipping key setup."
    SKIP_KEYS=true
  fi
fi

if [[ "$SKIP_KEYS" != "true" ]]; then

  # The Odds API
  echo ""
  echo -e "  ${BOLD}${CYAN}1. The Odds API${NC}  ${DIM}(required)${NC}"
  echo -e "  ${DIM}Free tier — up to 500 requests/month. Sign up at:${NC}"
  echo -e "  ${DIM}https://the-odds-api.com${NC}"
  echo -n "  Paste your key > "
  read -r ODDS_API_KEY
  while [[ -z "$ODDS_API_KEY" ]]; do
    warn "This key is required for live odds data."
    echo -n "  Paste your key > "
    read -r ODDS_API_KEY
  done

  # Anthropic (Claude)
  echo ""
  echo -e "  ${BOLD}${CYAN}2. Anthropic API Key${NC}  ${DIM}(for AI bet suggestions — optional)${NC}"
  echo -e "  ${DIM}Get one at https://console.anthropic.com — pay-per-use, very cheap.${NC}"
  echo -e "  ${DIM}Leave blank to disable AI features.${NC}"
  echo -n "  Paste your key > "
  read -r ANTHROPIC_API_KEY

  # Optional: stock features
  echo ""
  hr
  echo ""
  echo -e "  ${BOLD}Stock Portfolio Features${NC}  ${DIM}(all optional — press Enter to skip each)${NC}"

  echo ""
  echo -e "  ${DIM}Polygon.io API key (live stock prices): https://polygon.io${NC}"
  echo -n "  > "
  read -r POLYGON_API_KEY

  echo ""
  echo -e "  ${DIM}Financial Modeling Prep key (stock fundamentals): https://financialmodelingprep.com${NC}"
  echo -n "  > "
  read -r FMP_API_KEY

  # Write .env.local
  echo ""
  info "Writing .env.local..."

  cat > .env.local << EOF
# ── Kodiak Picks — Environment Configuration ─────────────────
# Generated by install.sh on $(date)
# Do NOT share this file — it contains your private API keys.

# Required: Live odds data
ODDS_API_KEY=${ODDS_API_KEY}

# Optional: AI-powered bet suggestions (Claude)
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

# Optional: Stock portfolio features
POLYGON_API_KEY=${POLYGON_API_KEY}
FMP_API_KEY=${FMP_API_KEY}

# Database path (default: local file, change to /data/kodiak.db for Railway)
DB_PATH=./kodiak.db

# LLM analysis feature toggle
ENABLE_LLM_ANALYSIS=true
EOF

  ok ".env.local written"
fi

echo ""

# ── Step 5: Install & Build ──────────────────────────────────
echo -e "${BOLD}  [4/5] Installing dependencies & building${NC}"
echo ""
info "Running npm install..."
npm install --silent || die "npm install failed"
ok "Dependencies installed"

echo ""
info "Building production app..."
npm run build || die "Build failed — check the errors above"
ok "Build complete"

echo ""

# ── Step 6: Create start script ──────────────────────────────
echo -e "${BOLD}  [5/5] Creating startup shortcut${NC}"
echo ""

# macOS: create an app-launcher .command file (double-clickable)
# Linux: create a shell script
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  LAUNCHER="$PROJECT_DIR/Start Kodiak Picks.command"
  cat > "$LAUNCHER" << LAUNCH
#!/usr/bin/env bash
cd "$(cd "$(dirname "$0")" && pwd)"
echo "Starting Kodiak Picks..."
npm start &
sleep 3
open http://localhost:3000
wait
LAUNCH
  chmod +x "$LAUNCHER"
  ok "Created 'Start Kodiak Picks.command' — double-click it anytime to launch"
else
  LAUNCHER="$PROJECT_DIR/start-kodiak.sh"
  cat > "$LAUNCHER" << LAUNCH
#!/usr/bin/env bash
cd "$(cd "$(dirname "$0")" && pwd)"
echo "Starting Kodiak Picks at http://localhost:3000 ..."
npm start
LAUNCH
  chmod +x "$LAUNCHER"
  ok "Created 'start-kodiak.sh'"
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
hr
echo ""
echo -e "  ${GREEN}${BOLD}All done! Kodiak Picks is ready.${NC}"
echo ""
echo -e "  ${BOLD}To start the app:${NC}"
if [[ "$OS" == "Darwin" ]]; then
  echo -e "  • Double-click ${CYAN}\"Start Kodiak Picks.command\"${NC} in Finder"
  echo -e "  • Or run: ${CYAN}npm start${NC} in this folder"
else
  echo -e "  • Run: ${CYAN}./start-kodiak.sh${NC}"
  echo -e "  • Or run: ${CYAN}npm start${NC} in this folder"
fi
echo ""
echo -e "  Then open ${CYAN}http://localhost:3000${NC} in your browser."
echo ""
echo -e "  ${DIM}To update later, run this installer again — it will pull the latest version.${NC}"
echo ""
hr
echo ""
