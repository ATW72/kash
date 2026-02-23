# 💸 Kash v4.0 — Personal Finance Tracker

A full-featured, self-hosted household finance tracker built for Proxmox LXC.
Track spending, income, bills, budgets, and savings goals — with email notifications,
multi-currency support, receipt photos, and a mobile-friendly PWA experience.

---

## ✨ Features

### 📊 Dashboard
- **Monthly hero card** — income, spending, net saved, budget %, and month-end forecast badge
- **Month navigation** — browse any past month with ◀ ▶ arrows
- **Insights card** — smart alerts for spending anomalies, streaks, largest expense, and overdue bills
- **Bill alerts** — unpaid bills due within 7 days shown with a Pay button
- **Budget status** — live progress bars for every category, color-coded green/yellow/red
- **Who Owes What** — outstanding split balances across the household at a glance
- **Spending by person** — household member breakdown for the current month
- **Cumulative savings chart** — track whether savings are trending up or down
- **Widget toggle** — show or hide any dashboard card, saved per user

### 💸 Spending
- Add, edit, and delete expenses with category, payment method, and notes
- **Receipt photo attachment** — photograph or upload receipts tied to any expense
- **Expandable rows** — click any row to see full notes, original currency, and receipt link
- **Duplicate detection** — warns before saving if a similar expense already exists
- **Quick-add floating button** — add an expense from any tab in seconds

### 💵 Income
- Track income by source (salary, bonus, investment, etc.)
- Filter by date range and per-person tracking

### 💳 Credit Cards
- Track balances across multiple cards
- Auto-calculates balance from linked expenses
- Utilization bar per card

### 🎯 Budgets
- Set monthly budgets per category
- **Copy last month** — duplicate all budgets in one click
- **Budget rollover** — underspend carries forward to the next month automatically
- **Month-over-month indicators** — ▲▼ badges show spending trends vs last month
- **Category sparklines** — inline 6-month mini chart on every budget row, green if trending down, red if up

### 💰 Savings Goals
- Set a goal name, target amount, and target date
- Progress bar with % achieved and monthly savings needed to hit the goal

### 📅 Bills
- Track one-time and **recurring bills** (weekly, bi-weekly, monthly, yearly)
- Recurring bills auto-create the next cycle when paid
- Auto-creates a Spending entry when paid — zero double-entry
- 7-day early warning + 3-day final reminder via email

### 🔄 Recurring Transactions
- Automate regular expenses and income entries

### 📈 Reports
- Monthly trend charts and spending by category
- Click any chart segment to filter expenses by that category
- Export to CSV or Excel

### 💱 Currencies
- Set your home currency and add foreign currencies with exchange rates
- Expenses in foreign currencies auto-convert to home currency for all totals

### 🔔 Email Notifications (per user)
- Bill due in 7 days — early warning
- Bill due in 3 days — final reminder
- Budget at 80% or exceeded
- Monthly summary on the 1st of each month
- Each user configures their own email and alert preferences

### 📋 Audit Trail
- Every expense create, edit, and delete is logged with who, what, and when
- Filterable audit log visible to admins

### 🗄️ Backup & Restore
- One-click JSON backup of all data
- Full restore from backup after a reinstall

### 🔎 Global Search
- Real-time search across expenses, income, and bills from the header bar
- Results grouped by type, click any result to jump directly to that record

### 🔒 Privacy & Sharing
- **Private by default** — every record is only visible to the user who created it
- **Opt-in sharing** — share any expense, income entry, credit card, bill, budget, or savings goal with specific users
- Shared users get **view and edit** access
- **Mine Only toggle** on every list — filter to just your own records at any time
- Shared items show a 🔗 badge with the owner's name so you always know the source
- Only the owner can share or unshare a record
- Admin has the same access as any regular user — no special data privileges

### 👥 Multi-User
- Unlimited users with display names, individual logins, and per-user notifications
- Admin and standard user roles — admin manages users and app settings only

### 💡 Spending Insights & Forecast
- **Month-end forecast** — projects your total spending based on your current daily pace, shown on the dashboard hero card and trend chart
- **Anomaly detection** — alerts when a category is 40%+ above your 3-month average
- **Savings streaks** — tracks and celebrates consecutive months where you saved money
- **Largest expense** highlight each month
- **Overdue bill alerts** surfaced directly on the dashboard

### 🔍 Advanced Search
- Filter expenses by keyword, person, payment method, amount range, and date simultaneously
- Results show count and total amount matching your filters
- Lives inside the Spending tab — no separate page needed

### 🤝 Bill Splitting
- Split any expense evenly, by percentage, or by custom amount
- Tracks who owes what across all unsettled splits
- **Who Owes What** dashboard card shows outstanding balances at a glance
- One-click settle for any person

### 📊 Category Sparklines
- Every budget row shows a tiny 6-month trend chart inline
- Green = spending trending down, red = trending up
- Instant visual of which categories are getting better or worse

### ⚙️ Dashboard Widget Toggle
- Show or hide any dashboard card to personalise your view
- Preferences saved per user — each household member can have their own layout

### 🚀 Onboarding Wizard
- First-time users are guided through 6 steps: set currency, first budget, first bill, notifications
- Each step can be skipped individually or all at once
- Never shown again after completion

### 📱 Mobile / PWA
- Bottom navigation bar on mobile
- Install as a home screen app — works like a native app
- Dark mode persists across sessions including PWA mode

---

## 🚀 Proxmox LXC Installation

### Fresh Install

Run this single command on your **Proxmox host** shell:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/install.sh)"
```

The installer will prompt you for:
- **Container ID** — e.g. `121`
- **Storage pool** — e.g. `local-lvm`
- **Hostname** — defaults to `kash`
- **Admin username & password** — your Kash login
- **Gmail address & app password** — optional, for email notifications

It then automatically:
1. Creates a Debian LXC with recommended resources
2. Installs Python, dependencies, and sets up a virtualenv
3. Writes the `.env` config file
4. Creates and enables the `kash` systemd service
5. Starts the app and confirms it's healthy

Once complete, Kash is available at `http://<container-ip>:5000`

### 📦 Recommended Container Resources

| Resource | Minimum | Recommended | Notes |
|---|---|---|---|
| CPU Cores | 1 | 1 | Flask is single-threaded, 1 core is sufficient |
| RAM | 512MB | **2048MB** | Needed for Gunicorn workers, APScheduler, Flask-Mail, and multi-user load |
| Disk | 4GB | **16GB** | Receipt photos add up fast — future-proofed for years of use |

The install script defaults to **1 core / 2048MB RAM / 16GB disk**.

### Updating an Existing Container

If you installed with the old defaults (512MB / 4GB), run these on your Proxmox host to resize without rebuilding:

```bash
pct set 121 --memory 2048
pct resize 121 rootfs 16G
pct reboot 121
```

Replace `121` with your container ID. No data is touched.

---

## 🔄 Updating

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ATW72/kash/main/update.sh)"
```

Or manually (replace 121 with your CTID):

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

Your database is never touched during an update.

---

## 📧 Email Notifications Setup

1. Google Account → Security → 2-Step Verification → App Passwords → generate one for Kash
2. Add to `/opt/kash/.env` on the LXC:

```env
MAIL_USERNAME=yourgmail@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_FROM_NAME=Kash
```

3. `systemctl restart kash`
4. Each user adds their email in the Account tab and picks which alerts they want

---

## 📱 Install as Mobile App (PWA)

**iPhone:** Safari → Share → Add to Home Screen

**Android:** Chrome → Menu → Install App

---

## ⚙️ Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_PORT` | `5000` | Port the app runs on |
| `APP_LOGIN_USERNAME` | `admin` | Admin username |
| `APP_LOGIN_PASSWORD` | `admin123` | Admin password — change this! |
| `FLASK_SECRET_KEY` | auto | Session secret key |
| `APP_DATABASE_PATH` | `/opt/kash/data/expenses.db` | Database path |
| `MAIL_SERVER` | `smtp.gmail.com` | SMTP server |
| `MAIL_PORT` | `587` | SMTP port |
| `MAIL_USERNAME` | *(empty)* | Gmail address |
| `MAIL_PASSWORD` | *(empty)* | Gmail app password |
| `MAIL_FROM_NAME` | `Kash` | Sender name |

---

## 🛠️ Local Development

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

## 📦 Tech Stack

- **Backend:** Python / Flask
- **Database:** SQLite
- **Frontend:** Vanilla JS, Chart.js
- **Email:** Flask-Mail (Gmail SMTP)
- **Scheduler:** APScheduler
- **Deployment:** Systemd on Debian LXC (Proxmox)
- **PWA:** Web App Manifest + Service Worker for home screen install and asset caching

---

## 📄 License

MIT — free to use, modify, and self-host.
