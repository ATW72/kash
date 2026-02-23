from datetime import datetime


def validate_expense(data, get_db_connection):
    """Validate expense data. Returns (is_valid, error_message)."""
    required_fields = ['date', 'category', 'description', 'amount', 'paid_by']
    for field in required_fields:
        if field not in data or data[field] is None or str(data[field]).strip() == '':
            return False, f"Missing required field: {field}"

    try:
        amount = float(data['amount'])
        if amount <= 0:
            return False, "Amount must be greater than zero"
        if round(amount, 2) != round(amount, 10):
            pass  # minor float precision tolerance
    except (ValueError, TypeError):
        return False, "Invalid amount value"

    try:
        datetime.strptime(data['date'], '%Y-%m-%d')
    except ValueError:
        return False, "Invalid date format. Use YYYY-MM-DD"

    if not str(data['paid_by']).strip():
        return False, "paid_by is required"

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM categories WHERE name = ?", (data['category'],))
    count = cursor.fetchone()[0]
    conn.close()
    if count == 0:
        return False, "Invalid category"

    return True, None


def validate_income(data):
    """Validate income data. Returns (is_valid, error_message)."""
    required_fields = ['date', 'source', 'description', 'amount', 'received_by']
    for field in required_fields:
        if field not in data or data[field] is None or str(data[field]).strip() == '':
            return False, f"Missing required field: {field}"

    try:
        amount = float(data['amount'])
        if amount <= 0:
            return False, "Amount must be greater than zero"
    except (ValueError, TypeError):
        return False, "Invalid amount value"

    try:
        datetime.strptime(data['date'], '%Y-%m-%d')
    except ValueError:
        return False, "Invalid date format. Use YYYY-MM-DD"

    if not str(data['received_by']).strip():
        return False, "received_by is required"

    return True, None


def validate_password(password):
    """Validate password. Returns (is_valid, error_message)."""
    if not password:
        return False, "Password is required"
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"
    return True, None


def format_currency(val):
    """Format a number as currency string."""
    try:
        num = float(val) or 0
        return f"${num:,.2f}"
    except (ValueError, TypeError):
        return "$0.00"


def get_credit_card_balance(card_id, get_db_connection_fn):
    """Calculate credit card balance (manual override or sum of expenses)."""
    conn = get_db_connection_fn()
    cursor = conn.cursor()

    cursor.execute("SELECT manual_balance FROM credit_cards WHERE id = ?", (card_id,))
    row = cursor.fetchone()

    if row and row[0] is not None:
        conn.close()
        return float(row[0])

    cursor.execute("""
        SELECT COALESCE(SUM(amount), 0.0)
        FROM expenses
        WHERE credit_card_id = ?
    """, (card_id,))
    balance = float(cursor.fetchone()[0])
    conn.close()
    return balance
