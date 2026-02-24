# Kash — Private Household Finance Tracker

> *Private. Simple. Yours.*

A full-featured, self-hosted household finance tracker built for Proxmox LXC.
Track spending, income, bills, budgets, and savings goals — with email notifications,
multi-user support, bank statement import, AI categorization, and a native-quality mobile experience.

---

## ✨ Features

### Dashboard
- **Monthly hero card** — income, spending, net saved, budget %, and month-end forecast badge
- **Month navigation** — browse any past month with ◀ ▶ arrows
- **Insights card** — smart alerts for spending anomalies, streaks, largest expense, and overdue bills
- **Bill alerts** — unpaid bills due within 7 days shown with a Pay button
- **Budget status** — live progress bars for every category, color-coded green/yellow/red
- **Who Owes What** — outstanding split balances across the household at a glance
- **Spending by person** — household member breakdown for the current month
- **Cumulative savings chart** — track whether savings are trending up or down
- **Widget toggle** — show or hide any dashboard card, saved per user — accessible from the header on desktop or the More drawer on mobile

### Dashboard Charts
- **12-Month Trend** — income vs expenses as dual area lines over the last year
- **Income vs Spending** — full-width area chart showing the gap between what you earn and spend each month — the gap is your savings margin, visualised
- **Spending Breakdown** — donut chart of spending by category this month; click any segment to filter expenses by that category
- **Sparklines** — tiny inline trend lines on every stat card showing the last 12 months at a glance; spending trends red, savings trend teal
- **Cumulative Savings** — running total of net savings over time

### Spending
- Add, edit, and delete expenses with category, payment method, and notes
- **Receipt photo attachment** — photograph or upload receipts tied to any expense
- **Expandable rows** — click any row to see full notes, original currency, and receipt link
- **Duplicate detection** — warns before saving if a similar expense already exists

### Income
- Track income by source (salary, bonus, investment, etc.)
- Filter by date range and per-person tracking

### Credit Cards
- Track balances across multiple cards
- Auto-calculates balance from linked expenses
- Utilization bar per card

### Budgets
- Set monthly budgets per category
- **Copy last month** — duplicate all budgets in one click
- **Budget rollover** — underspend carries forward to the next month automatically
- **Month-over-month indicators** — ▲▼ badges show spending trends vs last month
- **Category sparklines** — inline 6-month mini chart on every budget row

### Savings Goals
- Set a goal name, target amount, and target date
- Progress bar with % achieved and monthly savings needed to hit the goal

### Bills
- Track one-time and **recurring bills** (weekly, bi-weekly, monthly, yearly)
- Recurring bills auto-create the next cycle when paid
- Auto-creates a Spending entry when paid — zero double-entry
- 7-day early warning + 3-day final reminder via email

### Recurring Transactions
- Automate regular expenses and income entries

### Reports
- Monthly trend charts and spending by category
- Click any chart segment to filter expenses by that category
- Export to CSV or Excel

### Currencies
- Set your home currency and add foreign currencies with exchange rates
- Expenses in foreign currencies auto-convert to home currency for all totals

### Bank Statement Import
- Upload a CSV or Excel export from **any bank** — columns auto-detected
- **Smart rule-based categorization** — Walmart → Groceries, Netflix → Entertainment, etc.
- **Debit/credit auto-detection** — negative = expense, positive = income, or separate columns handled
- **Review table** — inspect every transaction before importing, change any category or type, uncheck rows to skip
- **Duplicate skipping** — same date + description + amount is silently skipped
- **AI categorization** — connect a local Ollama instance for smarter categorization

### AI Categorization (Ollama)
- Connect to a local Ollama instance running on your network
- Transaction descriptions categorized by a local LLM — **data never leaves your network**
- Recommended model: `llama3.1:8b` (runs well on CPU-only hardware)
- Configure in the Import tab or set `OLLAMA_URL` in `.env`

### Email Notifications (per user)
- Bill due in 7 days — early warning
- Bill due in 3 days — final reminder
- Budget at 80% or exceeded
- Monthly summary on the 1st of each month
- Each user configures their own email and alert preferences

### Privacy & Sharing
- **Private by default** — every record is only visible to the user who created it
- **Opt-in sharing** — share any expense, income, credit card, bill, budget, or savings goal with specific users
- Shared users get view and edit access
- **Mine Only toggle** on every list — filter to just your own records at any time
- Shared items show a badge with the owner's name
- Only the owner can share or unshare a record

### Multi-User & User Management
- Admin creates accounts — users never self-register (keeps your app private)
- **Invite by email** — admin enters username, display name, and email; Kash auto-generates a secure temporary password and emails it to the user
- **Forced password change** — new users must set their own password on first login
- Admin can edit any user: username, display name, email, admin role, or reset password
- Users with a temp password show a Temp badge in the users list
- Unlimited users with individual logins and per-user notification settings

### Spending Insights & Forecast
- **Month-end forecast** — projects total spending based on current daily pace
- **Anomaly detection** — alerts when a category is 40%+ above your 3-month average
- **Savings streaks** — tracks consecutive months where you saved money
- **Largest expense** highlight each month

### Advanced Search & Filter
- **Desktop** — real-time search bar in the header across expenses, income, and bills
- **Mobile** — tap the search icon for a full-screen search overlay
- Filter expenses by keyword, person, payment method, amount range, and date simultaneously

### Bill Splitting
- Split any expense evenly, by percentage, or by custom amount
- **Who Owes What** dashboard card shows outstanding balances at a glance
- One-click settle for any person

### Audit Trail
- Every expense create, edit, and delete is logged with who, what, and when
- Filterable audit log visible to admins

### Backup & Restore
- One-click JSON backup of all data
- Full restore from backup after a reinstall

### Onboarding Wizard
- First-time users are guided through setup: currency, first budget, first bill, notifications
- Each step can be skipped individually

### Mobile / PWA — Native Quality
- **Priority bottom navigation** — Dashboard, Spending, Bills, Income, + More (ordered by daily use)
- **More drawer** — Budgets, Cards, Reports, Currencies, Import, Widgets, Account — slides up from the bottom
- **Full-screen search overlay** — tap the search icon in the header for full-width search
- **iPhone safe area support** — proper padding for notch and home indicator
- **Swipeable tables** — horizontal scroll on all data tables
- **Slide-up modals** — modals animate from the bottom on mobile
- Install as a home screen app on iPhone and Android

### Design
- **Midnight Teal palette** — deep navy (#0a2540 → #0d3d52) with electric teal (#00d4aa) accents
- **Outlined K wordmark** — custom SVG logo where the K is a teal outline, unique to Kash
- **Inline SVG icons** — all icons are self-contained inline SVGs, zero CDN dependency, fully offline-capable
- **DM Sans font** — loaded via Google Fonts CDN (`fonts.googleapis.com`), with a system font fallback (SF Pro, Segoe UI, Roboto) if the CDN is unavailable
- **Dark mode** — warm deep navy palette (`#14233a` background, `#213348` cards) rather than pitch-black, preserving the teal accent depth
- Dark mode persists across sessions including PWA mode

---

## Proxmox LXC Installation

### Fresh Install

Run this single command on your **Proxmox host** shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/install.sh)"
```

The installer will prompt you for:
- **Container ID** — e.g. `121`
- **Hostname** — defaults to `kash`
- **Storage pool** — e.g. `local-lvm`
- **Bridge** — defaults to `vmbr0`
- **Static IP** — optional; enter in CIDR format e.g. `192.168.1.50/24`, or press Enter for DHCP
- **CPU, RAM, disk** — defaults to 1 core / 2048MB / 16GB
- **Admin username & password** — your Kash login
- **Gmail address & app password** — optional, for email notifications
- **Ollama URL** — optional, for AI transaction categorization

It then automatically:
1. Creates a Debian LXC with recommended resources
2. Installs Python, Gunicorn, and all dependencies in a virtualenv
3. Downloads the latest release from GitHub
4. Writes the `.env` config file
5. Creates and enables the `kash` systemd service
6. Starts the app and confirms it's healthy

Once complete, Kash is available at `http://<container-ip>:5000`

### Network & CDN Notes

Kash loads Chart.js from `cdn.jsdelivr.net` for dashboard charts. If your network runs **Pi-hole or a strict firewall**, this domain may be blocked, causing charts to fail silently.

**Quick fix — whitelist these domains in Pi-hole:**
```bash
pihole --white-list cdn.jsdelivr.net
pihole --white-list fonts.googleapis.com
pihole --white-list fonts.gstatic.com
pihole restartdns
```

All icons are inline SVGs and require no network access. The app font falls back gracefully to your system font if Google Fonts is unavailable.

---

### Recommended Container Resources

| Resource | Minimum | Recommended | Notes |
|---|---|---|---|
| CPU Cores | 1 | 1 | Sufficient for household use with Gunicorn |
| RAM | 1024MB | **2048MB** | Headroom for Gunicorn workers, APScheduler, Flask-Mail |
| Disk | 4GB | **16GB** | Receipt photos add up — future-proofed for years of use |

The install script defaults to **1 core / 2048MB RAM / 16GB disk**.

### Resizing an Existing Container

```bash
pct set 121 --memory 2048
pct resize 121 rootfs 16G
pct reboot 121
```

Replace `121` with your container ID. No data is touched.

---

## Updating

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/update.sh)"
```

Or manually:

```bash
pct exec 121 -- bash -c "
  cd /tmp &&
  wget -q https://github.com/ATW72/kash/releases/latest/download/kash.zip &&
  unzip -o kash.zip &&
  cp -r kash/* /opt/kash/ &&
  chown -R appuser:appuser /opt/kash &&
  systemctl restart kash &&
  rm -rf /tmp/kash /tmp/kash.zip &&
  echo Done
"
```

Your database and `.env` are never touched during an update.

---

## Email Notifications Setup

1. Google Account → Security → 2-Step Verification → App Passwords → generate one for Kash
2. Add to `/opt/kash/.env`:

```env
MAIL_USERNAME=yourgmail@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM_NAME=Kash
```

3. `pct exec 121 -- systemctl restart kash`
4. Each user adds their email in Account → Notification Settings

---

## Ollama AI Setup

1. Install Ollama on a machine on your network (see [ollama.com](https://ollama.com))
2. Pull a model: `ollama pull llama3.1:8b`
3. Add to `/opt/kash/.env`:

```env
OLLAMA_URL=http://192.168.1.100:11434
OLLAMA_MODEL=llama3.1:8b
```

4. `pct exec 121 -- systemctl restart kash`
5. The Import tab will show a green Ollama connected status

**Recommended hardware for Ollama:**
- CPU-only: 16GB+ RAM, 4+ cores (llama3.1:8b uses ~5GB RAM)
- With GPU: Any NVIDIA GPU with 4GB+ VRAM for near-instant responses

---

## Install as Mobile App (PWA)

**iPhone:** Safari → Share → Add to Home Screen

**Android:** Chrome → Menu → Install App

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_PORT` | `5000` | Port the app runs on |
| `APP_LOGIN_USERNAME` | `admin` | Initial admin username |
| `APP_LOGIN_PASSWORD` | `admin123` | Initial admin password — change after install |
| `FLASK_SECRET_KEY` | auto-generated | Session secret key |
| `APP_DATABASE_PATH` | `/opt/kash/data/expenses.db` | SQLite database path |
| `MAIL_SERVER` | `smtp.gmail.com` | SMTP server |
| `MAIL_PORT` | `587` | SMTP port |
| `MAIL_USERNAME` | *(empty)* | Gmail address |
| `MAIL_PASSWORD` | *(empty)* | Gmail app password |
| `MAIL_FROM_NAME` | `Kash` | Sender display name |
| `OLLAMA_URL` | *(empty)* | Ollama instance URL for AI categorization |
| `OLLAMA_MODEL` | `llama3.1:8b` | Ollama model to use |

---

## Local Development

```bash
git clone https://github.com/ATW72/kash.git
cd kash
pip install -r requirements.txt
export APP_DATABASE_PATH=./data/expenses.db
export APP_LOGIN_USERNAME=admin
export APP_LOGIN_PASSWORD=admin123
export FLASK_SECRET_KEY=dev-secret
python main.py
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Python / Flask |
| WSGI Server | Gunicorn (3 workers) |
| Database | SQLite |
| Frontend | Vanilla JS, Chart.js, Inline SVG icons |
| Email | Flask-Mail (Gmail SMTP) |
| Scheduler | APScheduler |
| AI | Ollama (local LLM, optional) |
| Deployment | Systemd on Debian LXC (Proxmox) |
| PWA | Web App Manifest + Service Worker |

---

## License

MIT — free to use, modify, and self-host.
