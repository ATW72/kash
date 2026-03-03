# Kash — Recreation Prompt

> Use this prompt to recreate Kash from scratch with an AI coding assistant.

---

## Prompt

Build a self-hosted, full-stack household and business finance web application called **Kash** using **Python (Flask)** on the backend and **Vanilla JS + Chart.js** on the frontend. Store all data in **SQLite**. Deploy via **systemd on a Debian LXC inside Proxmox**.

---

## Design System

- **Color palette**: Midnight Teal — deep navy header (`#0a2540` → `#0d3d52`) with **electric teal** (`#00d4aa`) as the primary accent
- **Business Mode palette**: Deep purple (`#4c1d95` → `#7c3aed`) activated when Business tab is open
- **Typography**: DM Sans via Google Fonts, system font fallback
- **Dark mode**: Warm navy (`#14233a` background, `#213348` cards), persists across sessions including PWA
- **Glassmorphism** card style on all panels
- **Inline SVG icons** only — no icon CDN dependencies
- Animated stat counters, smooth hover transitions, micro-animations throughout
- Mobile: bottom navigation bar, slide-up modals, swipe-to-close drawers
- PWA-installable on iPhone (Safari → Add to Home Screen) and Android

---

## Personal Finance Features

### Dashboard
- Monthly hero card: income, expenses, net saved, budget %, month-end forecast badge
- Month navigation (◀ ▶ to browse past months)
- Insights card: spending anomaly detection (40%+ above 3-month avg), savings streaks, largest expense, overdue bill alerts
- Bill alerts: unpaid bills due within 7 days with Pay button
- Budget progress bars: color-coded green/yellow/red
- Who Owes What: outstanding split balances
- Spending by person breakdown
- Widget toggle: show/hide cards per user

### Dashboard Charts (Chart.js)
- 12-Month income vs expenses dual area lines
- Income vs Spending full-width area chart
- Spending Breakdown donut chart (clickable to filter expenses)
- Sparklines on every stat card (12 months, spending=red, savings=teal)
- Cumulative savings line chart

### Spending (Expenses)
- Add/edit/delete with category, payment method, notes
- Receipt photo attachment (filename stored in DB)
- Expandable table rows (notes, original currency, receipt link)
- Duplicate detection warning

### Income
- Track by source, filter by date range and person

### Credit Cards
- Multiple cards, auto-balance from linked expenses, utilization bar

### Budgets
- Monthly per-category budgets
- Copy last month button
- Budget rollover (underspend carries forward)
- Month-over-month ▲▼ badges
- Per-category 6-month sparklines

### Bills
- One-time and recurring (weekly, bi-weekly, monthly, yearly)
- Recurring auto-creates the next cycle on payment
- Auto-creates a Spending entry when paid
- 7-day early warning + 3-day reminder via email

### Recurring Transactions
- Automate regular expenses and income

### Savings Goals
- Name, target amount, target date, progress bar

### Reports
- Monthly trend charts, spending by category
- Export to CSV and Excel (openpyxl)

### Currencies
- Home currency + foreign currencies with exchange rates
- Auto-converts all totals

### Bank Statement Import
- Upload CSV or Excel — columns auto-detected
- Rule-based categorization (Walmart→Groceries, Netflix→Entertainment, etc.)
- Debit/credit auto-detection
- Preview table: inspect/change/skip before importing
- Duplicate skipping
- Optional AI categorization via Ollama

### Bill Splitting
- Split evenly, by %, or custom amount
- Who Owes What dashboard card
- One-click settle

### Audit Trail
- Every expense create/edit/delete logged with user + timestamp
- Filterable admin view

---

## Business Mode

A fully isolated dual-mode experience. All business data is stored with `is_business=1` in the database — never mixed with personal data.

### Navigation
- "Business" tab in desktop top navigation
- **"Biz"** purple button in mobile bottom nav bar
- "Business Mode" badge appears in the header
- Switching to Business tab activates the deep purple theme system-wide

### Business Stats (animated counters)
- Revenue, Expenses, Net Profit, Profit Margin %, Estimated Tax Reserve (25% of profit)

### Cash Flow Chart
- Bar chart: Revenue vs Expenses for last 6 months
- **Golden dashed Net Profit trend line** overlaid

### Business Budget Tracking
- Set business-specific category budgets
- Animated progress bars: purple → yellow (>75%) → red (over budget)
- **Alert banner** at top of Business tab when any category hits ≥80%

### Invoice Generator
- Form: Client name, email, issue date, due date, line items (add/remove), tax rate %, notes
- Live totals: subtotal → tax → total update as user types
- Preview: styled purple-gradient modal showing a printable invoice
- Print / Save as PDF via browser print
- Save to database (auto-numbered `INV-YYYYMM-001`)
- Invoice history table with DRAFT / SENT / PAID status badges
- "Mark Paid" button per invoice
- **CSV export**: `/api/business/export/csv` — downloads all business income + expenses

### Business AI Advisor
- Powered by local Ollama
- Analyzes real revenue, expenses, margin from DB
- Generates markdown business health summary + recommendations
- Supports all US states + France for tax context

---

## Email Notifications

Use **Flask-Mail** with Gmail SMTP. Daily scheduler via **APScheduler** runs at 8am.

| Alert | Subject | When |
|---|---|---|
| Bill 7-day warning | 📅 Kash: Bills Due This Week | Daily |
| Bill 3-day final | ⏰ Kash: Final Reminder | Daily |
| Bill overdue | 🚨 Kash: Bills Overdue | Daily |
| Personal budget ≥80% | ⚠️ Kash: Budget Warning | Daily |
| Business budget ≥80% | ⚠️ Kash Business: Budget Warning | Daily (purple HTML email) |
| Invoice overdue | 🔴 Kash Business: X Invoices Overdue | Daily (red HTML email) |
| Monthly summary | 📊 Kash: [Month] Summary | 1st of month |

Per-user preferences: `notify_bills`, `notify_budgets`, `notify_monthly` columns on the `users` table.

---

## User Management & Security

- Admin-created accounts only (no self-registration)
- Invite by email: auto-generate temp password, email it to new user
- Forced password change on first login
- Admin can edit/delete users, reset passwords
- **Two-Factor Authentication**: TOTP via PyOTP + QR code setup flow
- **Google OAuth**: optional Sign-In with Google via Authlib
- Password hashing: `pbkdf2:sha256` via Werkzeug
- Per-user sharing: any record can be opt-in shared with specific users
- "Mine Only" toggle on all list views

---

## Database Schema (SQLite)

Key tables:
- `users` — id, username, password_hash, is_admin, display_name, email, notify_*, two_factor_method, totp_secret, google_id, avatar_url
- `expenses` — id, date, category, description, amount, paid_by, payment_method, credit_card_id, notes, receipt_filename, is_business, owner, currency, original_amount
- `income` — id, date, source, description, amount, received_by, notes, is_business, owner, currency, original_amount
- `budgets` — id, category, amount, month, year, rollover, is_business, owner
- `bills` — id, name, amount, due_date, is_paid, is_recurring, frequency
- `categories` — id, name, type (personal | business)
- `credit_cards` — id, owner, card_name, credit_limit, manual_balance
- `invoices` — id, invoice_number, client_name, client_email, issue_date, due_date, items (JSON), notes, tax_rate, status (draft|sent|paid), owner, created_at
- `savings_goals`, `recurring_transactions`, `currencies`, `audit_logs`, `shared_records`

All `is_business` columns default to 0 and are added via `ALTER TABLE` migrations for existing databases.

---

## API Endpoints (Flask)

### Personal Finance
- `GET/POST /api/expenses` — list/create expenses
- `PUT/DELETE /api/expenses/<id>`
- `GET/POST /api/income`
- `GET/POST /api/budgets` — supports `?is_business=1&month=YYYY-MM`
- `GET/POST /api/bills`
- `GET/POST /api/categories` — supports `?type=business`
- `GET/POST /api/savings-goals`
- `GET/POST /api/credit-cards`
- `GET /api/currencies`

### Business
- `GET /api/business/stats` — revenue, expenses, profit, margin for current month
- `GET /api/business/export/csv` — download all business data as CSV
- `GET /api/business/advisor` — Ollama AI business advice
- `GET/POST /api/invoices`
- `PATCH /api/invoices/<id>` — update status

### Auth
- `POST /login`, `POST /logout`
- `GET/POST /api/users` (admin)
- `POST /api/users/invite`
- `GET /auth/google`, `/auth/google/callback`
- `GET/POST /api/2fa/setup`

### Utility
- `GET /api/dashboard` — aggregate dashboard stats
- `POST /api/import` — bank statement import
- `GET /api/audit`
- `POST /api/backup`, `POST /api/restore`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Python 3 / Flask |
| WSGI | Gunicorn (3 workers) |
| Database | SQLite (via `sqlite3` stdlib) |
| Frontend | Vanilla JS (ES6+ modules), Chart.js (CDN) |
| Email | Flask-Mail (Gmail SMTP / any SMTP) |
| Scheduler | APScheduler (BackgroundScheduler) |
| AI | Ollama REST API (local LLM, optional) |
| 2FA | PyOTP + QRCode |
| OAuth | Authlib (Google) |
| Excel Export | openpyxl |
| Deployment | Systemd service on Debian LXC in Proxmox |
| PWA | Web App Manifest + Service Worker |

---

## File Structure

```
kash/
├── app.py                  # All Flask routes and business logic
├── main.py                 # App entry point (runs Gunicorn or dev server)
├── templates/
│   └── index.html          # Single-page app (all HTML + CSS + JS inline)
├── static/
│   ├── manifest.json       # PWA manifest
│   ├── sw.js               # Service worker
│   └── email_logo.png      # PNG logo for HTML emails
├── utils/
│   ├── auth.py             # Login decorators, session helpers
│   ├── db.py               # get_db_connection(), get_visible_clause()
│   ├── notifications.py    # Email builders + run_daily_notifications()
│   └── helpers.py
├── config/
│   └── settings.py         # Loads .env into app.config
├── data/
│   └── expenses.db         # SQLite database (auto-created)
├── install.sh              # Proxmox LXC installer
├── update.sh               # In-place updater (preserves .env + DB)
├── requirements.txt
└── README.md
```

---

## Deployment (Proxmox LXC)

- Debian LXC, 1 CPU / 2048MB RAM / 16GB disk
- Python virtualenv at `/opt/kash/venv`
- Systemd service: `kash.service` running `gunicorn -w 3 -b 0.0.0.0:5000 app:app`
- `.env` file at `/opt/kash/.env` (never overwritten by updates)
- Database at `/opt/kash/data/expenses.db`
- Receipts stored in `/opt/kash/static/receipts/`
- Updating: pull from `atw-kash` branch on GitHub, copy files, `systemctl restart kash`
