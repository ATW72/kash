import logging
from datetime import datetime, date
from flask_mail import Mail, Message
from utils.db import get_db_connection

mail = Mail()
logger = logging.getLogger(__name__)


def init_mail(app):
    """Initialize Flask-Mail with the app."""
    app.config['MAIL_SERVER']   = app.config.get('MAIL_SERVER', 'smtp.gmail.com')
    app.config['MAIL_PORT']     = app.config.get('MAIL_PORT', 587)
    app.config['MAIL_USE_TLS']  = app.config.get('MAIL_USE_TLS', True)
    app.config['MAIL_USERNAME'] = app.config.get('MAIL_USERNAME', '')
    app.config['MAIL_PASSWORD'] = app.config.get('MAIL_PASSWORD', '')
    app.config['MAIL_DEFAULT_SENDER'] = (
        app.config.get('MAIL_FROM_NAME', 'Kash'),
        app.config.get('MAIL_USERNAME', '')
    )
    mail.init_app(app)


def send_email(to, subject, html_body):
    """Send a single email. Returns True on success."""
    try:
        msg = Message(subject=subject, recipients=[to], html=html_body)
        mail.send(msg)
        return True
    except Exception as e:
        logger.error(f"Email send failed to {to}: {e}")
        return False



def build_welcome_email(username, display_name, temp_password, app_url=''):
    """Build HTML welcome email for new users with their temp password."""
    name = display_name or username
    return f"""
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;max-width:560px;margin:0 auto;background:#f9fafb;padding:2rem;">
      <div style="background:linear-gradient(135deg,#0a2540,#0d3d52);border-radius:16px;padding:2rem;text-align:center;margin-bottom:1.5rem;">
        <h1 style="margin:0;"><img src="https://raw.githubusercontent.com/ATW72/kash/52a2ed786417678f4be500380b41453cab4aaa27/static/email_logo.png" alt="Kash" height="28" style="vertical-align:middle;border:none;outline:none;"></h1>
        <p style="color:rgba(255,255,255,0.85);margin:0.5rem 0 0;">Private. Simple. Yours.</p>
      </div>
      <div style="background:white;border-radius:16px;padding:2rem;margin-bottom:1rem;">
        <h2 style="margin:0 0 0.5rem;color:#1f2937;">Welcome, {name}! 👋</h2>
        <p style="color:#6b7280;margin:0 0 1.5rem;">Your Kash account has been created. Use the credentials below to log in — you'll be asked to set your own password right away.</p>
        <div style="background:#f3f4f6;border-radius:10px;padding:1.25rem;margin-bottom:1.5rem;">
          <div style="margin-bottom:0.75rem;">
            <span style="font-size:0.8rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;">Username</span>
            <div style="font-size:1.1rem;font-weight:700;color:#1f2937;margin-top:0.2rem;">{username}</div>
          </div>
          <div>
            <span style="font-size:0.8rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;">Temporary Password</span>
            <div style="font-size:1.1rem;font-weight:700;color:#667eea;margin-top:0.2rem;font-family:monospace;letter-spacing:0.1em;">{temp_password}</div>
          </div>
        </div>
        {f'<a href="{app_url}" style="display:block;background:linear-gradient(135deg,#00d4aa,#00bfa5);color:white;text-align:center;padding:0.875rem;border-radius:10px;text-decoration:none;font-weight:600;margin-bottom:1rem;">Open Kash →</a>' if app_url else ''}
        {f'<div style="background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;padding:1rem;margin-bottom:1rem;"><span style="font-size:0.8rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;">Login URL</span><div style="margin-top:0.3rem;"><a href="{app_url}" style="color:#667eea;font-weight:600;word-break:break-all;">{app_url}</a></div></div>' if app_url else ''}
        <p style="color:#9ca3af;font-size:0.82rem;margin:0;">This is a temporary password. You will be required to set a new password on your first login. Keep this email safe until then.</p>
      </div>
      <p style="text-align:center;color:#9ca3af;font-size:0.78rem;margin:0;">Sent by Kash • Private. Simple. Yours.</p>
    </div>"""

def build_bill_alert_email(username, display_name, bills):
    """Build HTML email for upcoming/overdue bills."""
    name = display_name or username
    rows = ''
    for b in bills:
        d = b['days_until']
        if d < 0:
            status = f'<span style="color:#ef4444;font-weight:700;">{abs(d)} days overdue</span>'
        elif d == 0:
            status = '<span style="color:#ef4444;font-weight:700;">Due today!</span>'
        else:
            status = f'<span style="color:#f59e0b;font-weight:600;">Due in {d} days</span>'
        rows += f'''
        <tr>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{b["name"]}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{b["due_date"]}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;font-weight:700;color:#ef4444;">${b["amount"]:.2f}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{status}</td>
        </tr>'''

    return f'''
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;max-width:600px;margin:0 auto;">
      <div style="background:linear-gradient(135deg,#0a2540,#0d3d52);padding:24px 32px;border-radius:16px 16px 0 0;">
        <h1 style="margin:0;"><img src="https://raw.githubusercontent.com/ATW72/kash/52a2ed786417678f4be500380b41453cab4aaa27/static/email_logo.png" alt="Kash" height="24" style="vertical-align:middle;border:none;outline:none;"></h1>
        <p style="color:rgba(255,255,255,0.85);margin:4px 0 0;font-size:0.9rem;">Bill Alert</p>
      </div>
      <div style="background:#ffffff;padding:28px 32px;border:1px solid #e5e7eb;border-top:none;">
        <p style="font-size:1rem;color:#1f2937;">Hi <strong>{name}</strong>,</p>
        <p style="color:#6b7280;">You have bills coming up that need attention:</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:0.9rem;">
          <thead>
            <tr style="background:#f9fafb;">
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Bill</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Due Date</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Amount</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Status</th>
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
        <p style="color:#6b7280;font-size:0.85rem;margin-top:24px;">Log in to Kash to pay your bills and keep your finances on track.</p>
      </div>
      <div style="background:#f9fafb;padding:16px 32px;border-radius:0 0 16px 16px;border:1px solid #e5e7eb;border-top:none;">
        <p style="color:#9ca3af;font-size:0.8rem;margin:0;">You're receiving this because you enabled bill alerts in Kash.</p>
      </div>
    </div>'''


def build_budget_alert_email(username, display_name, budgets):
    """Build HTML email for budget alerts."""
    name = display_name or username
    rows = ''
    for b in budgets:
        pct = b['percentage']
        if pct > 100:
            status = f'<span style="color:#ef4444;font-weight:700;">Over budget! ({pct}%)</span>'
            color = '#ef4444'
        else:
            status = f'<span style="color:#f59e0b;font-weight:600;">{pct}% used</span>'
            color = '#f59e0b'
        months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        rows += f'''
        <tr>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{b["category"]}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{months[b["month"]]} {b["year"]}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;color:{color};font-weight:700;">${b["spent"]:.2f} / ${b["effective_amount"]:.2f}</td>
          <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;">{status}</td>
        </tr>'''

    return f'''
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;max-width:600px;margin:0 auto;">
      <div style="background:linear-gradient(135deg,#0a2540,#0d3d52);padding:24px 32px;border-radius:16px 16px 0 0;">
        <h1 style="margin:0;"><img src="https://raw.githubusercontent.com/ATW72/kash/52a2ed786417678f4be500380b41453cab4aaa27/static/email_logo.png" alt="Kash" height="24" style="vertical-align:middle;border:none;outline:none;"></h1>
        <p style="color:rgba(255,255,255,0.85);margin:4px 0 0;font-size:0.9rem;">Budget Alert</p>
      </div>
      <div style="background:#ffffff;padding:28px 32px;border:1px solid #e5e7eb;border-top:none;">
        <p style="font-size:1rem;color:#1f2937;">Hi <strong>{name}</strong>,</p>
        <p style="color:#6b7280;">Some of your budgets need attention this month:</p>
        <table style="width:100%;border-collapse:collapse;margin:16px 0;font-size:0.9rem;">
          <thead>
            <tr style="background:#f9fafb;">
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Category</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Period</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Spent / Budget</th>
              <th style="padding:10px 12px;text-align:left;color:#6b7280;font-size:0.8rem;text-transform:uppercase;">Status</th>
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>
      </div>
      <div style="background:#f9fafb;padding:16px 32px;border-radius:0 0 16px 16px;border:1px solid #e5e7eb;border-top:none;">
        <p style="color:#9ca3af;font-size:0.8rem;margin:0;">You're receiving this because you enabled budget alerts in Kash.</p>
      </div>
    </div>'''


def build_monthly_summary_email(username, display_name, stats):
    """Build HTML monthly summary email."""
    name = display_name or username
    now = datetime.now()
    prev_month = now.month - 1 if now.month > 1 else 12
    prev_year = now.year if now.month > 1 else now.year - 1
    months = ['','January','February','March','April','May','June',
              'July','August','September','October','November','December']
    net = stats['income'] - stats['expenses']
    net_color = '#10b981' if net >= 0 else '#ef4444'

    return f'''
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;max-width:600px;margin:0 auto;">
      <div style="background:linear-gradient(135deg,#667eea,#764ba2);padding:24px 32px;border-radius:16px 16px 0 0;">
        <h1 style="color:white;margin:0;font-size:1.4rem;">💸 Kash</h1>
        <p style="color:rgba(255,255,255,0.85);margin:4px 0 0;font-size:0.9rem;">{months[prev_month]} {prev_year} Monthly Summary</p>
      </div>
      <div style="background:#ffffff;padding:28px 32px;border:1px solid #e5e7eb;border-top:none;">
        <p style="font-size:1rem;color:#1f2937;">Hi <strong>{name}</strong>, here's your summary for {months[prev_month]}:</p>
        <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px;margin:20px 0;">
          <div style="background:#f9fafb;border-radius:12px;padding:16px;text-align:center;">
            <div style="font-size:0.75rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;">Income</div>
            <div style="font-size:1.4rem;font-weight:800;color:#10b981;">${stats["income"]:,.2f}</div>
          </div>
          <div style="background:#f9fafb;border-radius:12px;padding:16px;text-align:center;">
            <div style="font-size:0.75rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;">Expenses</div>
            <div style="font-size:1.4rem;font-weight:800;color:#ef4444;">${stats["expenses"]:,.2f}</div>
          </div>
          <div style="background:#f9fafb;border-radius:12px;padding:16px;text-align:center;">
            <div style="font-size:0.75rem;color:#6b7280;text-transform:uppercase;letter-spacing:0.05em;margin-bottom:6px;">Net Saved</div>
            <div style="font-size:1.4rem;font-weight:800;color:{net_color};">${net:,.2f}</div>
          </div>
        </div>
        {'<p style="color:#10b981;font-weight:600;">🎉 Great job! You saved money last month.</p>' if net >= 0 else '<p style="color:#ef4444;font-weight:600;">⚠️ You spent more than you earned last month.</p>'}
        <p style="color:#6b7280;font-size:0.85rem;margin-top:16px;">Log in to Kash to review your full breakdown and set budgets for this month.</p>
      </div>
      <div style="background:#f9fafb;padding:16px 32px;border-radius:0 0 16px 16px;border:1px solid #e5e7eb;border-top:none;">
        <p style="color:#9ca3af;font-size:0.8rem;margin:0;">You're receiving this because you enabled monthly summaries in Kash.</p>
      </div>
    </div>'''


def run_daily_notifications(app):
    """Run all daily notification checks. Called by scheduler at 8am."""
    with app.app_context():
        if not app.config.get('MAIL_USERNAME'):
            return  # Mail not configured

        conn = get_db_connection()
        today = date.today()
        now = datetime.now()

        # Get all users with email and at least one notification enabled
        users = conn.execute("""
            SELECT id, username, display_name, email,
                   notify_bills, notify_budgets, notify_monthly
            FROM users
            WHERE email IS NOT NULL AND email != ''
            AND (notify_bills=1 OR notify_budgets=1 OR notify_monthly=1)
        """).fetchall()

        for user in users:
            uid = user['id']
            email = user['email']

            # ── Bill alerts ──────────────────────────────────────────────────
            if user['notify_bills']:
                all_bills = conn.execute("""
                    SELECT name, amount, due_date,
                           CAST(julianday(due_date) - julianday('now') AS INTEGER) as days_until
                    FROM bills
                    WHERE is_paid = 0
                    AND CAST(julianday(due_date) - julianday('now') AS INTEGER) <= 7
                    ORDER BY due_date ASC
                """).fetchall()
                all_bills = [dict(b) for b in all_bills]

                # 3-day final reminder (overdue, today, 1-3 days)
                urgent = [b for b in all_bills if b['days_until'] <= 3]
                if urgent:
                    html = build_bill_alert_email(user['username'], user['display_name'], urgent)
                    overdue = any(b['days_until'] < 0 for b in urgent)
                    subject = '🚨 Kash: Bills Overdue' if overdue else '⏰ Kash: Final Reminder — Bills Due in 3 Days'
                    send_email(email, subject, html)

                # 7-day early warning (4-7 days out, only if no urgent bills already sent)
                elif all_bills:
                    week_out = [b for b in all_bills if 4 <= b['days_until'] <= 7]
                    if week_out:
                        html = build_bill_alert_email(user['username'], user['display_name'], week_out)
                        subject = '📅 Kash: Bills Due This Week'
                        send_email(email, subject, html)

            # ── Budget alerts ────────────────────────────────────────────────
            if user['notify_budgets']:
                budgets_raw = conn.execute("""
                    SELECT b.id, b.category, b.amount, b.month, b.year,
                           COALESCE(b.rollover, 0) as rollover,
                           COALESCE(SUM(e.amount), 0) as spent
                    FROM budgets b
                    LEFT JOIN expenses e ON e.category = b.category
                        AND strftime('%Y', e.date) = CAST(b.year AS TEXT)
                        AND strftime('%m', e.date) = printf('%02d', b.month)
                    WHERE b.month = ? AND b.year = ?
                    GROUP BY b.id
                    HAVING (spent / (b.amount + COALESCE(b.rollover,0))) >= 0.8
                """, (now.month, now.year)).fetchall()

                if budgets_raw:
                    budgets = []
                    for b in budgets_raw:
                        d = dict(b)
                        effective = d['amount'] + d['rollover']
                        d['effective_amount'] = round(effective, 2)
                        d['percentage'] = round(d['spent'] / effective * 100, 1) if effective > 0 else 0
                        budgets.append(d)
                    html = build_budget_alert_email(user['username'], user['display_name'], budgets)
                    over = any(b['percentage'] > 100 for b in budgets)
                    subject = '🚨 Kash: Budget Exceeded' if over else '⚠️ Kash: Budget Warning'
                    send_email(email, subject, html)

            # ── Monthly summary (send on 1st of month) ───────────────────────
            if user['notify_monthly'] and today.day == 1:
                prev_month = now.month - 1 if now.month > 1 else 12
                prev_year = now.year if now.month > 1 else now.year - 1
                income = conn.execute(
                    "SELECT COALESCE(SUM(amount),0) FROM income WHERE strftime('%Y',date)=? AND strftime('%m',date)=?",
                    (str(prev_year), f"{prev_month:02d}")).fetchone()[0]
                expenses = conn.execute(
                    "SELECT COALESCE(SUM(amount),0) FROM expenses WHERE strftime('%Y',date)=? AND strftime('%m',date)=?",
                    (str(prev_year), f"{prev_month:02d}")).fetchone()[0]
                stats = {'income': float(income), 'expenses': float(expenses)}
                html = build_monthly_summary_email(user['username'], user['display_name'], stats)
                months = ['','January','February','March','April','May','June',
                          'July','August','September','October','November','December']
                subject = f'📊 Kash: {months[prev_month]} Summary'
                send_email(email, subject, html)

        conn.close()
