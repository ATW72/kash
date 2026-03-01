import sqlite3
import os

dbs = ['./data/expenses.db', './kash.db']
potential_names = ['MilStar', 'American Express', 'Apple Card', 'Care Credit', 'Dillards', 'Kohl', 'PayPal', 'Sam', 'TJ Maxx']

for db in dbs:
    if os.path.exists(db):
        print(f"Checking {db}...")
        conn = sqlite3.connect(db)
        c = conn.cursor()
        try:
            c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='credit_cards'")
            if c.fetchone():
                c.execute("SELECT id, owner, card_name FROM credit_cards")
                rows = c.fetchall()
                if rows:
                    for r in rows:
                        print(f"  Found Card: ID={r[0]}, Owner='{r[1]}', Name='{r[2]}'")
                else:
                    print("  No cards in credit_cards table.")
            else:
                print("  No credit_cards table.")
        except Exception as e:
            print(f"  Error: {e}")
        conn.close()
    else:
        print(f"{db} not found.")
