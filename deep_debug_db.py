import sqlite3
import json
import os

db_path = 'data/expenses.db' # Based on my search earlier
if not os.path.exists(db_path):
    # Try the root if it's there
    db_path = 'kash.db'

print(f"Checking database: {db_path}")

conn = sqlite3.connect(db_path)
conn.row_factory = sqlite3.Row
c = conn.cursor()
try:
    c.execute("SELECT * FROM credit_cards")
    rows = [dict(r) for r in c.fetchall()]
    print(f"Found {len(rows)} cards:")
    print(json.dumps(rows, indent=2))
except Exception as e:
    print(f"Error: {e}")
conn.close()
