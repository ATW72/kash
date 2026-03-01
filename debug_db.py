import sqlite3
import json

conn = sqlite3.connect('/home/anwillia/Documents/git/kash/data/expenses.db')
conn.row_factory = sqlite3.Row
c = conn.cursor()
try:
    c.execute("SELECT * FROM credit_cards")
    rows = [dict(r) for r in c.fetchall()]
    print(json.dumps(rows, indent=2))
except Exception as e:
    print(f"Error: {e}")
conn.close()
