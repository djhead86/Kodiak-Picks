# Kodiak Picks

**A personal sports betting + stock portfolio tracker with AI-powered analysis, ELO power ratings, and bear-themed aesthetics.**

Track every bet, measure your closing line value (CLV), see your real ROI, get AI-powered pick suggestions, monitor stock positions, and watch your ELO model learn from every game — all running locally on your machine. No subscription, no cloud, no one watching your data.

---

## What it does

- **Live odds** across NFL, NBA, MLB, NHL, NCAAF, NCAAB — pulled automatically every hour via The Odds API
- **ELO power ratings** — team strength model updated from real ESPN game results every 30 minutes, used to compute edge vs. market odds
- **Power Rankings** — sport-tabbed leaderboard showing your model's current team ratings with tier badges
- **AI bet suggestions** — Claude analyzes matchups using ELO edge, line movement, news context, and CLV signals
- **CLV tracking** — did you beat the closing line? Automatically captured within 60 min of game time
- **Dashboard** with win record, net units, ROI, and a running P/L chart
- **Wisdom queue** — AI analysis review before placing bets
- **Parlay support** — multi-leg wagers with auto odds calculation and Kelly sizing
- **Stock portfolio tracker** — AI-screened stock picks with position management
- **Bear-forged design** — custom SVG bear mascot, gold particle atmosphere, page transitions, and animated UI throughout

Everything lives in a local SQLite database on your computer. Your picks, your data.

---

## Install

### macOS / Linux

One command:

```bash
curl -fsSL https://raw.githubusercontent.com/beerforblood/kodiak-picks/main/install.sh | bash
```

Or download `install.sh`, make it executable, and run it:

```bash
chmod +x install.sh
./install.sh
```

### Windows

Open **PowerShell as Administrator** and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\install.ps1
```

Or right-click `install.ps1` and select **Run with PowerShell**.

---

The installer will:

1. Check that Node.js 20+ and git are installed (with instructions if not)
2. Clone this repo to your machine
3. Walk you through entering your API keys (stored locally in `.env.local`, never shared)
4. Install dependencies and build the production app
5. Create a one-click startup shortcut

It takes about 2 minutes.

---

## API keys you'll need

| Key | Required? | Cost | Where to get it |
|-----|-----------|------|-----------------|
| The Odds API | **Yes** | Free tier (500 req/mo) | [the-odds-api.com](https://the-odds-api.com) |
| Anthropic (Claude) | Optional | Pay-per-use, pennies | [console.anthropic.com](https://console.anthropic.com) |
| Polygon.io | Optional | Free tier | [polygon.io](https://polygon.io) |
| Financial Modeling Prep | Optional | Free tier | [financialmodelingprep.com](https://site.financialmodelingprep.com) |

The Odds API free tier gives you 500 requests/month — more than enough for tracking picks across all sports. AI features require the Anthropic key but are entirely optional. Stock features require Polygon and/or FMP keys.

---

## Pages

| Page | Route | What it does |
|------|-------|-------------|
| Command Center | `/` | Live matchups with score ticker — click any odds to stage a bet |
| Matchups | `/matchups` | All upcoming games with odds and ELO edge indicators |
| Wisdom | `/wisdom` | AI analysis queue — review Claude's take before placing |
| Ledger | `/ledger` | All bets — mark won/lost/push, enter closing lines |
| Analytics | `/dashboard` | Win record, net units, ROI, CLV, P/L chart, best/worst bets |
| Power Rankings | `/power-rankings` | ELO leaderboard per sport with tier badges and sync stats |
| Stocks | `/stocks` | AI-screened stock picks and analysis |
| Portfolio | `/portfolio` | Stock position tracker with P/L |

---

## The ELO Model

Kodiak runs a standard ELO rating system per team per sport. Ratings start at 1500 and update after every completed game.

**How it works:**
- ESPN scoreboard API is polled every 30 minutes for completed games
- Each game result adjusts both teams' ratings using sport-specific K-factors
- Home advantage is factored into expected score calculation, then stripped before storing
- Edge signals compare your model's fair probability against no-vig market odds

**Sport configuration:**

| Sport | K-Factor | Home Advantage | Notes |
|-------|----------|----------------|-------|
| NBA | 20 | 100 | Moderate learning rate |
| NFL | 24 | 55 | Higher K for 17-game season |
| MLB | 10 | 15 | Low K for 162-game season |
| NHL | 16 | 55 | Moderate across the board |
| NCAAF | 28 | 80 | High K + strong home field |
| NCAAB | 24 | 80 | High K + strong home court |

---

## Background Jobs (Cron)

These run automatically when the app is running:

| Job | Frequency | What it does |
|-----|-----------|-------------|
| Odds refresh | Every hour | Pulls latest odds from The Odds API |
| Closing line capture | Every 15 min | Captures odds close to game time for CLV |
| ELO sync | Every 30 min | Fetches completed game scores from ESPN, updates ratings |
| Bet suggestions | Every 2 hours | Claude screens matchups for value (if Anthropic key set) |
| Stock screener | 9 AM + 4 PM weekdays | Claude screens for stock picks (if Anthropic key set) |

---

## Tech stack

- **Next.js 14** (App Router) — frontend + API routes
- **React 18** — UI with custom SVG components and CSS animations
- **SQLite** (better-sqlite3) — all data stored locally in `kodiak.db`
- **node-cron** — background job scheduling
- **Recharts** — charts and data visualization
- **The Odds API** — live sports odds
- **ESPN Scoreboard API** — completed game scores for ELO
- **Anthropic Claude** (Sonnet + Haiku) — AI bet analysis, suggestions, stock screening, news gathering

---

## What is CLV?

Closing Line Value measures whether you're finding real edges or just getting lucky.

```
You bet Team A at -150.
Game closes at -180.

Implied probability at your pick:   60.0%
Implied probability at close:       64.3%
CLV = +4.3%  ← you got the better number
```

Bettors who consistently beat the closing line are profitable long-term — regardless of short-term record. Kodiak tracks this automatically.

---

## After installing

Your database lives at `kodiak.db` in the project folder. **Back this up** if you care about your history — it's a single file, easy to copy anywhere.

To update to the latest version, just run the installer again. It detects an existing installation and pulls the latest code.

---

## Security notes

- All API keys are stored in `.env.local` which is gitignored — they never leave your machine
- The `.env.example` file shows what keys are needed with placeholder values
- Never commit `.env`, `.env.local`, `*.key`, `*.pem`, or `*.db` files
- If you fork this repo, double-check that your `.gitignore` is intact before pushing

---

## Running on a server (optional)

If you want it accessible from other devices or running 24/7, deploy to [Railway](https://railway.app):

```bash
npm run build
npm start
```

Set these environment variables in Railway:
- `ODDS_API_KEY`
- `ANTHROPIC_API_KEY` (optional)
- `DB_PATH=/data/kodiak.db` (Railway persistent volume)

---

*Built for personal use. No warranty. Bet responsibly.*
